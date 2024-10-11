import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const double _kActivityIndicatorRadius = 14.0;

class _SliverPullToAdd extends SingleChildRenderObjectWidget {
  const _SliverPullToAdd({
    this.refreshIndicatorExtent = 0.0,
    this.hasLayoutExtent = false,
    super.child,
  }) : assert(refreshIndicatorExtent >= 0.0);

  /// [hasLayoutExtent]がtrueの時に、Sliver内で占領する高さ。
  final double refreshIndicatorExtent;

  /// hasLayoutExtentがtrueの場合、リフレッシュインジケーターはlayoutExtentに従ってスペースを確保します。
  /// falseの場合は、見た目にはインジケーターが描画されていても、レイアウト上のスペースを占有しない、つまり他のUI要素に影響を与えずに表示される形になります。
  final bool hasLayoutExtent;

  @override
  _RenderSliverPullToAdd createRenderObject(BuildContext context) {
    return _RenderSliverPullToAdd(
      refreshIndicatorExtent: refreshIndicatorExtent,
      hasLayoutExtent: hasLayoutExtent,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderSliverPullToAdd renderObject) {
    renderObject
      ..refreshIndicatorLayoutExtent = refreshIndicatorExtent
      ..hasLayoutExtent = hasLayoutExtent;
  }
}

// RenderSliverオブジェクトは、子のRenderBoxオブジェクトにオーバースクロールされたギャップ内で描画するためのスペースを与えます。
// そして、[layoutExtent]が設定されているかどうかに応じて、そのオーバースクロールされたギャップを保持するかどうかを決定します。
//
// [layoutExtentOffsetCompensation]フィールドは、[layoutExtent]が設定および解除される際にスクロール位置のジャンプを防ぐために
// 内部会計を行います。
class _RenderSliverPullToAdd extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderSliverPullToAdd({
    required double refreshIndicatorExtent,
    required bool hasLayoutExtent,
    RenderBox? child,
  })  : assert(refreshIndicatorExtent >= 0.0),
        _refreshIndicatorExtent = refreshIndicatorExtent,
        _hasLayoutExtent = hasLayoutExtent {
    this.child = child;
  }

  // リフレッシュモード時にスリバー内でインジケーターが占めるべきレイアウトスペースの量。
  double get refreshIndicatorLayoutExtent => _refreshIndicatorExtent;
  double _refreshIndicatorExtent;
  set refreshIndicatorLayoutExtent(double value) {
    assert(value >= 0.0);
    if (value == _refreshIndicatorExtent) {
      return;
    }
    _refreshIndicatorExtent = value;
    markNeedsLayout();
  }

  // 子ボックスはどちらにしても利用可能なスペースにレイアウトされ、描画されますが、
  // これにより[SliverGeometry.layoutExtent]スペースを占有するかどうかが決まります。
  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;
  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent) {
      return;
    }
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  // これは、以前に適用されたスクロールオフセットをスクロール可能なものに追跡し、
  // [refreshIndicatorLayoutExtent]または[hasLayoutExtent]が変更されたときに、
  // 視覚的にすべてを同じ場所に保つために適切なデルタを適用できるようにします。
  double layoutExtentOffsetCompensation = 0.0;

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    // Only pulling to refresh from the top is currently supported.
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);

    // このスリバーが現在持つべき新しいレイアウト範囲の量。
    // - _hasLayoutExtentがfalseの場合は0になる。
    // - _hasLayoutExtentがtrueの場合は、[refreshIndicatorLayoutExtent]の値になる。
    final double layoutExtent =
        (_hasLayoutExtent ? 1.0 : 0.0) * _refreshIndicatorExtent;

    // 新しいlayoutExtentが変更された場合、SliverGeometryのlayoutExtentはその値を取ります（次のperformLayout実行時に）。
    // スクロール位置が突然ジャンプしないように、最初にスクロールオフセットをシフトします。
    if (layoutExtent != layoutExtentOffsetCompensation) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
      );
      layoutExtentOffsetCompensation = layoutExtent;
      // 一時的なフレームのために既存のレイアウト範囲、新しいレイアウト範囲の変更、およびオーバーラップを組み合わせて
      // 子の制約を一時的に調整する必要がないようにするためにリターンします。
      return;
    }

    // オーバースクロール(引っ張っている)されているかどうか
    final bool active = constraints.overlap < 0.0 || layoutExtent > 0.0;
    // オーバースクロールしている部分の長さ
    final double overscrolledExtent =
        constraints.overlap < 0.0 ? constraints.overlap.abs() : 0.0;

    // 子をレイアウトし、現在ドラッグされているオーバースクロールのスペースを与えます。
    // これには、ユーザーがリフレッシュプロセス中に手を離した後も保持するスライバーのレイアウト範囲スペースが含まれる場合と含まれない場合があります。
    child!.layout(
      constraints.asBoxConstraints(
        maxExtent: layoutExtent
            // Plus only the overscrolled portion immediately preceding this
            // sliver.
            +
            overscrolledExtent,
      ),
      parentUsesSize: true,
    );
    if (active) {
      geometry = SliverGeometry(
        scrollExtent: layoutExtent,
        paintOrigin: -overscrolledExtent - constraints.scrollOffset,
        paintExtent: max(
          // Check child size (which can come from overscroll) because
          // layoutExtent may be zero. Check layoutExtent also since even
          // with a layoutExtent, the indicator builder may decide to not
          // build anything.
          max(child!.size.height, layoutExtent) - constraints.scrollOffset,
          0.0,
        ),
        maxPaintExtent: max(
          max(child!.size.height, layoutExtent) - constraints.scrollOffset,
          0.0,
        ),
        layoutExtent: max(layoutExtent - constraints.scrollOffset, 0.0),
      );
    } else {
      // If we never started overscrolling, return no geometry.
      geometry = SliverGeometry.zero;
    }
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (constraints.overlap < 0.0 ||
        constraints.scrollOffset + child!.size.height > 0) {
      paintContext.paintChild(child!, offset);
    }
  }

  // Nothing special done here because this sliver always paints its child
  // exactly between paintOrigin and paintExtent.
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}

enum RefreshIndicatorMode {
  /// 初期状態
  inactive,

  /// 初期状態から最初の閾値までの間
  drag,

  /// 閾値を超えた
  overFirstThreshold,

  /// 閾値を超えた
  overSecondThreshold,

  animating,
  done,
}

/// リフレッシュコントロールの現在の状態と利用可能なスペースに応じて、リフレッシュインジケーターのスペースに表示する異なるウィジェットを作成できるビルダーのシグネチャ。
///
/// `refreshTriggerPullDistance`と`refreshIndicatorExtent`のパラメータは、[CupertinoSliverRefreshControl]に渡されるのと同じ値です。
///
/// `pulledExtent`パラメータは、オーバースクロールから得られるか、リフレッシュ中にスライバーによって保持される現在の利用可能なスペースです。
typedef RefreshControlIndicatorBuilder = Widget Function(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
  double refreshIndicatorExtent,
);

class PullToAddControl extends HookWidget {
  const PullToAddControl({
    super.key,
    required this.slivers,
    required this.onPull,
    this.refreshTriggerPullDistance = 60,
    this.refreshIndicatorExtent = 20.0,
    this.builder = buildRefreshIndicator,
  })  : assert(refreshTriggerPullDistance > 0.0),
        assert(refreshIndicatorExtent >= 0.0),
        assert(
          refreshTriggerPullDistance >= refreshIndicatorExtent,
          'The refresh indicator cannot take more space in its final state '
          'than the amount initially created by overscrolling.',
        );

  final List<Widget> slivers;

  final double refreshTriggerPullDistance;

  /// [onPull]が実行中に占領されるスペースの量。
  final double refreshIndicatorExtent;

  final RefreshControlIndicatorBuilder builder;

  final Future<void> Function(int count) onPull;

  static Widget buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final double percentageComplete =
        clampDouble(pulledExtent / refreshTriggerPullDistance, 0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 100,
          left: 0.0,
          right: 0.0,
          child: _buildIndicatorForRefreshState(
            refreshState,
            _kActivityIndicatorRadius,
            percentageComplete,
          ),
        ),
      ],
    );
  }

  static Widget _buildIndicatorForRefreshState(
    RefreshIndicatorMode refreshState,
    double radius,
    double percentageComplete,
  ) {
    return switch (refreshState) {
      RefreshIndicatorMode.inactive => const SizedBox.shrink(),
      RefreshIndicatorMode.drag => const Icon(Icons.arrow_downward),
      RefreshIndicatorMode.overFirstThreshold =>
        const Text('add line', textAlign: TextAlign.center),
      RefreshIndicatorMode.overSecondThreshold =>
        const Text('add two lines', textAlign: TextAlign.center),
      RefreshIndicatorMode.animating =>
        const Text('animating', textAlign: TextAlign.center),
      RefreshIndicatorMode.done =>
        const Text('done', textAlign: TextAlign.center),
    };
  }

  // Pull To Addの状態を計算して返す。
  void transitionNextState({
    required double pulledExtent,
    required ValueNotifier<RefreshIndicatorMode> refreshState,
    required ValueNotifier<Future<void>?> refreshTask,
  }) {
    // 1つ目の閾値
    final firstThreshold = refreshTriggerPullDistance;
    // 2つ目の閾値
    final secondThreshold = refreshTriggerPullDistance * 2;

    switch (refreshState.value) {
      case RefreshIndicatorMode.inactive:
        if (pulledExtent <= 0) {
          return;
        }
        refreshState.value = RefreshIndicatorMode.drag;
      case RefreshIndicatorMode.drag:
        if (pulledExtent == 0) {
          refreshState.value = RefreshIndicatorMode.inactive;
          return;
        }
        if (pulledExtent >= firstThreshold) {
          HapticFeedback.mediumImpact();
          refreshState.value = RefreshIndicatorMode.overFirstThreshold;
        }
      case RefreshIndicatorMode.overFirstThreshold:
        if (pulledExtent < firstThreshold) {
          refreshState.value = RefreshIndicatorMode.drag;
          return;
        }
        if (pulledExtent >= secondThreshold) {
          HapticFeedback.mediumImpact();
          refreshState.value = RefreshIndicatorMode.overSecondThreshold;
          return;
        }
      case RefreshIndicatorMode.overSecondThreshold:
        if (pulledExtent < secondThreshold) {
          refreshState.value = RefreshIndicatorMode.overFirstThreshold;
          return;
        }

        refreshState.value = RefreshIndicatorMode.overSecondThreshold;
      case RefreshIndicatorMode.animating:
        if (refreshTask.value != null) {
          // リフレッシュ中はリフレッシュを継続。
          return;
        }
        refreshState.value = RefreshIndicatorMode.done;
        continue done;
      done:
      case RefreshIndicatorMode.done:
        // 完了後のアニメーションの最後の部分は時間がかかることがあり、
        // 0.0になるまで待っていたら次のユーザーのアクションが開始されてしまうとstatusがバグってしまうため、
        // 非アクティブに戻る遷移を厳密に0.0にする前にトリガーさせます。
        if (pulledExtent > refreshTriggerPullDistance * 0.1) {
          return;
        }
        refreshState.value = RefreshIndicatorMode.inactive;
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshState = useState(RefreshIndicatorMode.inactive);
    final refreshTask = useState<Future<void>?>(null);

    return Listener(
      // 指を離した時
      onPointerUp: (event) async {
        switch (refreshState.value) {
          case RefreshIndicatorMode.inactive:
            refreshState.value = RefreshIndicatorMode.inactive;
          case RefreshIndicatorMode.drag:
            await onPull(0);
            refreshState.value = RefreshIndicatorMode.inactive;
            return;
          case RefreshIndicatorMode.overFirstThreshold:
            refreshTask.value = onPull(1)
              ..whenComplete(() {
                refreshTask.value = null;
                // この時点でBoxConstraintのmaxHeightが0になっている可能性があるため、
                // もう一度遷移をトリガーします。そうしないと、transitionNextStateの呼び出しが
                // 行われず、状態が非アクティブでないままになる可能性があります。
                // transitionNextState();
              });
            refreshState.value = RefreshIndicatorMode.animating;
          case RefreshIndicatorMode.overSecondThreshold:
            refreshTask.value = onPull(2)
              ..whenComplete(() {
                refreshTask.value = null;
                // transitionNextState();
              });
            refreshState.value = RefreshIndicatorMode.animating;
          default:
            assert(false);
        }
      },
      child: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          _SliverPullToAdd(
            refreshIndicatorExtent: refreshIndicatorExtent,
            // TODO: trueにしてしまうと、最小スペースがrefreshIndicatorExtentになってしまうため、inactiveにならない。
            // refreshState.value != RefreshIndicatorMode.inactive,
            hasLayoutExtent: false,
            child: LayoutBuilder(builder: (context, constraints) {
              final pulledExtent = constraints.maxHeight;
              SchedulerBinding.instance
                  .addPostFrameCallback((Duration timestamp) {
                transitionNextState(
                  pulledExtent: pulledExtent,
                  refreshState: refreshState,
                  refreshTask: refreshTask,
                );
              });

              return builder(
                context,
                refreshState.value,
                pulledExtent,
                refreshTriggerPullDistance,
                refreshIndicatorExtent,
              );
            }),
          ),
          ...slivers,
        ],
      ),
    );
  }
}
