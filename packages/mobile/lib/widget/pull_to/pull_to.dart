import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mobile/widget/pull_to/pull_to_builder.dart';
import 'package:mobile/widget/pull_to/pull_to_mode.dart';

const double _kActivityIndicatorRadius = 14.0;

class PullToControl extends StatefulWidget {
  const PullToControl({
    super.key,
    required this.child,
    required this.onPull,
    this.refreshTriggerPullDistance = 80,
    this.refreshIndicatorExtent = 20.0,
    this.builder = buildRefreshIndicator,
  })  : assert(refreshTriggerPullDistance > 0.0),
        assert(refreshIndicatorExtent >= 0.0),
        assert(
          refreshTriggerPullDistance >= refreshIndicatorExtent,
          'The refresh indicator cannot take more space in its final state '
          'than the amount initially created by overscrolling.',
        );

  final Widget child;

  final double refreshTriggerPullDistance;

  /// [onPull]が実行中に占領されるスペースの量。
  final double refreshIndicatorExtent;

  final PullToIndicatorBuilder builder;

  final Future<void> Function(int count) onPull;

  static Widget buildRefreshIndicator({
    required BuildContext context,
    required PullToMode mode,
    required double pulledExtent,
    required double refreshTriggerPullDistance,
    required double refreshIndicatorExtent,
  }) {
    final double percentageComplete =
        clampDouble(pulledExtent / refreshTriggerPullDistance, 0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 0.0,
          right: 0.0,
          child: _buildIndicatorForRefreshState(
            context,
            mode,
            _kActivityIndicatorRadius,
            percentageComplete,
          ),
        ),
      ],
    );
  }

  static Widget _buildIndicatorForRefreshState(
    BuildContext context,
    PullToMode refreshState,
    double radius,
    double percentageComplete,
  ) {
    return switch (refreshState) {
      PullToMode.inactive => const SizedBox.shrink(),
      PullToMode.drag => Opacity(
          opacity: percentageComplete,
          child: const Icon(Icons.arrow_downward),
        ),
      PullToMode.overFirstThreshold => const BounceText(
          key: ValueKey('pull_to_1'),
          child: Text('Write something here', textAlign: TextAlign.center),
        ),
      PullToMode.overSecondThreshold => const BounceText(
          key: ValueKey('pull_to_2'),
          child: Text('Add two new lines', textAlign: TextAlign.center),
        ),
      PullToMode.doing => const SizedBox.shrink(),
      PullToMode.done => const SizedBox.shrink(),
    };
  }

  @override
  State<PullToControl> createState() => _PullToAddControlState();
}

class _PullToAddControlState extends State<PullToControl> {
  PullToMode mode = PullToMode.inactive;
  void setMode(PullToMode newMode) {
    setState(() {
      mode = newMode;
    });
  }

  double pulledExtent = 0.0;

  // Pull To Addの状態を計算して返す。
  void transitionNextState({
    required ScrollNotification notification,
  }) async {
    if (notification is! ScrollUpdateNotification) {
      return;
    }

    if (notification.metrics.axisDirection == AxisDirection.down) {
      setState(() {
        pulledExtent = pulledExtent - notification.scrollDelta!;
      });
    } else if (notification.metrics.axisDirection == AxisDirection.up) {
      setState(() {
        pulledExtent = pulledExtent + notification.scrollDelta!;
      });
    }

    if (pulledExtent < 0) {
      return;
    }

    // 1つ目の閾値
    final firstThreshold = widget.refreshTriggerPullDistance;
    // 2つ目の閾値
    final secondThreshold = widget.refreshTriggerPullDistance + 30;

    switch (mode) {
      case PullToMode.inactive:
        if (pulledExtent <= 0) {
          return;
        }
        setMode(PullToMode.drag);
      case PullToMode.drag:
        if (pulledExtent == 0) {
          setMode(PullToMode.inactive);
          return;
        }
        if (pulledExtent >= firstThreshold) {
          HapticFeedback.lightImpact();
          setMode(PullToMode.overFirstThreshold);
        }
      case PullToMode.overFirstThreshold:
        if (pulledExtent < firstThreshold) {
          setMode(PullToMode.drag);
          return;
        }
        if (pulledExtent >= secondThreshold) {
          HapticFeedback.mediumImpact();
          setMode(PullToMode.overSecondThreshold);
          return;
        }
      case PullToMode.overSecondThreshold:
        if (pulledExtent < secondThreshold) {
          setMode(PullToMode.overFirstThreshold);
          return;
        }

        setMode(PullToMode.overSecondThreshold);
      case PullToMode.doing:
        // doingからdoneへの変化はonPointerUpで行うのでここでは何もしない。
        return;
      case PullToMode.done:
        // 完了後のアニメーションの最後の部分は時間がかかることがあり、
        // 0.0になるまで待っていたら次のユーザーのアクションが開始されてしまうとstatusがバグってしまうため、
        // 非アクティブに戻る遷移を厳密に0.0にする前にトリガーさせます。
        if (pulledExtent > widget.refreshTriggerPullDistance * 0.1) {
          return;
        }
        setMode(PullToMode.inactive);
        return;
    }
  }

  // ユーザーが指を離した瞬間に呼ばれる。
  Future<void> onPointerUp() async {
    switch (mode) {
      case PullToMode.inactive:
        setMode(PullToMode.inactive);
      case PullToMode.drag:
        await widget.onPull(0);
        setMode(PullToMode.inactive);
        return;
      case PullToMode.overFirstThreshold:
        widget.onPull(1).whenComplete(() {
          setMode(PullToMode.done);
          setMode(PullToMode.inactive);
        });
        setMode(PullToMode.doing);
      case PullToMode.overSecondThreshold:
        widget.onPull(2).whenComplete(() {
          setMode(PullToMode.done);
          setMode(PullToMode.inactive);
        });
        setMode(PullToMode.doing);
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (event) => onPointerUp(),
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              SchedulerBinding.instance
                  .addPostFrameCallback((Duration timestamp) {
                transitionNextState(
                  notification: notification,
                );
              });
              return false;
            },
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification) {
                // TODO: ClampingScrollPhysicsでしか反応しないが実装必要あるか?
                // https://github.com/flutter/flutter/issues/17649#issuecomment-466771061
                if (notification.depth != 0 || !notification.leading) {
                  return false;
                }
                if (mode == PullToMode.drag) {
                  notification.disallowIndicator();
                  return true;
                }
                return false;
              },
              child: widget.child,
            ),
          ),
          Positioned(
            top: 30,
            left: 30,
            child: Text('$pulledExtent'),
          ),
          widget.builder(
            context: context,
            mode: mode,
            pulledExtent: pulledExtent,
            refreshTriggerPullDistance: widget.refreshTriggerPullDistance,
            refreshIndicatorExtent: widget.refreshIndicatorExtent,
          ),
        ],
      ),
    );
  }
}

class BounceText extends StatefulWidget {
  const BounceText({
    super.key,
    required this.child,
  });

  final Widget child;
  @override
  State<BounceText> createState() => _BounceTextState();
}

class _BounceTextState extends State<BounceText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // AnimationControllerを初期化
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200), // アニメーションの長さを設定
      vsync: this,
    );

    // バウンスエフェクトを追加するためのCurvedAnimation
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceOut, // bounceOutでバウンドアニメーションを設定
      ),
    );

    // アニメーションを開始
    _controller.forward();
  }

  @override
  void dispose() {
    // リソースを解放
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value, // テキストのスケールをアニメーションに基づいて変更
          child: widget.child,
        );
      },
    );
  }
}
