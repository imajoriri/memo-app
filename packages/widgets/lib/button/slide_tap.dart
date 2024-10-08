import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// slideしながらタップできるWidget。[SlidingTapGroup]の中に配置する。
///
/// ```dart
/// SlidingTapGroup(
///   child: SlidingTapItem(
///     onEnter: () {},
///     onLeave: () {},
///     onConfirm: () {},
///     child: Container(),
///   ),
/// );
/// ```
class SlidingTapItem extends StatefulWidget {
  const SlidingTapItem({
    super.key,
    required this.onEnter,
    required this.onLeave,
    required this.onConfirm,
    required this.child,
    this.hapticsFeedback = true,
  });

  /// [child]にポインタが入ったときに呼ばれる。
  final void Function() onEnter;

  /// [child]にポインタが出たときに呼ばれる。
  final void Function() onLeave;

  /// [child]にポインタが離れたときに呼ばれる。
  final void Function() onConfirm;

  /// 表示するWidget。
  final Widget child;

  /// ポインタが入った時にHaptics feedbackをするかどうか。
  final bool hapticsFeedback;

  @override
  State<SlidingTapItem> createState() => _SlidingTapItemState();
}

class _SlidingTapItemState extends State<SlidingTapItem>
    implements _ActionSheetSlideTarget {
  @override
  void didEnter() {
    widget.onEnter();
    if (widget.hapticsFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void didLeave() {
    widget.onLeave();
  }

  @override
  void didConfirm() {
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

class SlidingTapGroup extends StatelessWidget {
  const SlidingTapGroup({
    super.key,
    required this.child,
  });

  final Widget child;

  HitTestResult _hitTest(BuildContext context, Offset globalPosition) {
    final int viewId = View.of(context).viewId;
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, globalPosition, viewId);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};
    gestures[_TargetSelectionGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_TargetSelectionGestureRecognizer>(
      () => _TargetSelectionGestureRecognizer(
        debugOwner: this,
        hitTest: (Offset globalPosition) => _hitTest(
          context,
          globalPosition,
        ),
      ),
      (_TargetSelectionGestureRecognizer instance) {},
    );
    return RawGestureDetector(
      gestures: gestures,
      child: child,
    );
  }
}

class _SlidingTapGestureRecognizer extends VerticalDragGestureRecognizer {
  _SlidingTapGestureRecognizer({
    super.debugOwner,
  }) {
    dragStartBehavior = DragStartBehavior.down;
  }

  /// Called whenever the primary pointer moves regardless of whether drag has
  /// started.
  ///
  /// The parameter is the global position of the primary pointer.
  ///
  /// This is similar to `onUpdate`, but allows the caller to track the primary
  /// pointer's location before the drag starts, which is useful to enhance
  /// responsiveness.
  ValueSetter<Offset>? onResponsiveUpdate;

  /// Called whenever the primary pointer is lifted regardless of whether drag
  /// has started.
  ///
  /// The parameter is the global position of the primary pointer.
  ///
  /// This is similar to `onEnd`, but allows know the primary pointer's final
  /// location even if the drag never started, which is useful to enhance
  /// responsiveness.
  ValueSetter<Offset>? onResponsiveEnd;

  int? _primaryPointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _primaryPointer ??= event.pointer;
    super.addAllowedPointer(event);
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _primaryPointer) {
      _primaryPointer = null;
    }
    super.rejectGesture(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer == _primaryPointer) {
      if (event is PointerMoveEvent) {
        onResponsiveUpdate?.call(event.position);
      }
      // If this gesture has a competing gesture (such as scrolling), and the
      // pointer has not moved far enough to get this panning accepted, a
      // pointer up event should still be considered as an accepted tap up.
      // Manually accept this gesture here, which triggers onDragEnd.
      if (event is PointerUpEvent) {
        resolve(GestureDisposition.accepted);
        stopTrackingPointer(_primaryPointer!);
        onResponsiveEnd?.call(event.position);
      } else {
        super.handleEvent(event);
      }
      if (event is PointerUpEvent || event is PointerCancelEvent) {
        _primaryPointer = null;
      }
    }
  }

  @override
  String get debugDescription => 'tap slide';
}

// A region (typically a button) that can receive entering, exiting, and
// updating events of a "sliding tap" gesture.
//
// Some Cupertino widgets, such as action sheets or dialogs, allow the user to
// select buttons using "sliding taps", where the user can drag around after
// pressing on the screen, and whichever button the drag ends in is selected.
//
// This class is used to define the regions that sliding taps recognize. This
// class must be provided to a `MetaData` widget as `data`, and is typically
// implemented by a widget state class. When an eligible dragging gesture
// enters, leaves, or ends this `MetaData` widget, corresponding methods of this
// class will be called.
//
// Multiple `_ActionSheetSlideTarget`s might be nested.
// `_TargetSelectionGestureRecognizer` uses a simple algorithm that only
// compares if the inner-most slide target has changed (which suffices our use
// case).  Semantically, this means that all outer targets will be treated as
// identical to the inner-most one, i.e. when the pointer enters or leaves a
// slide target, the corresponding method will be called on all targets that
// nest it.
abstract class _ActionSheetSlideTarget {
  // A pointer has entered this region.
  //
  // This includes:
  //
  //  * The pointer has moved into this region from outside.
  //  * The point has contacted the screen in this region. In this case, this
  //    method is called as soon as the pointer down event occurs regardless of
  //    whether the gesture wins the arena immediately.
  void didEnter();

  // A pointer has exited this region.
  //
  // This includes:
  //  * The pointer has moved out of this region.
  //  * The pointer is no longer in contact with the screen.
  //  * The pointer is canceled.
  //  * The gesture loses the arena.
  //  * The gesture ends. In this case, this method is called immediately
  //    before [didConfirm].
  void didLeave();

  // The drag gesture is completed in this region.
  //
  // This method is called immediately after a [didLeave].
  void didConfirm();
}

typedef _HitTester = HitTestResult Function(Offset location);

// Recognizes sliding taps and thereupon interacts with
// `_ActionSheetSlideTarget`s.
class _TargetSelectionGestureRecognizer extends GestureRecognizer {
  _TargetSelectionGestureRecognizer({super.debugOwner, required this.hitTest})
      : _slidingTap = _SlidingTapGestureRecognizer(debugOwner: debugOwner) {
    _slidingTap
      ..onDown = _onDown
      ..onResponsiveUpdate = _onUpdate
      ..onResponsiveEnd = _onEnd
      ..onCancel = _onCancel;
  }

  final _HitTester hitTest;

  final List<_ActionSheetSlideTarget> _currentTargets =
      <_ActionSheetSlideTarget>[];
  final _SlidingTapGestureRecognizer _slidingTap;

  @override
  void acceptGesture(int pointer) {
    _slidingTap.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _slidingTap.rejectGesture(pointer);
  }

  @override
  void addPointer(PointerDownEvent event) {
    _slidingTap.addPointer(event);
  }

  @override
  void addPointerPanZoom(PointerPanZoomStartEvent event) {
    _slidingTap.addPointerPanZoom(event);
  }

  @override
  void dispose() {
    _slidingTap.dispose();
    super.dispose();
  }

  // Collect the `_ActionSheetSlideTarget`s that are currently hit by the
  // pointer, check whether the current target have changed, and invoke their
  // methods if necessary.
  void _updateDrag(Offset pointerPosition) {
    final HitTestResult result = hitTest(pointerPosition);

    // A slide target might nest other targets, therefore multiple targets might
    // be found.
    final List<_ActionSheetSlideTarget> foundTargets =
        <_ActionSheetSlideTarget>[];
    for (final HitTestEntry entry in result.path) {
      if (entry.target case final RenderMetaData target) {
        if (target.metaData is _ActionSheetSlideTarget) {
          foundTargets.add(target.metaData as _ActionSheetSlideTarget);
        }
      }
    }

    // Compare whether the active target has changed by simply comparing the
    // first (inner-most) avatar of the nest, ignoring the cases where
    // _currentTargets intersect with foundTargets (see _ActionSheetSlideTarget's
    // document for more explanation).
    if (_currentTargets.firstOrNull != foundTargets.firstOrNull) {
      for (final _ActionSheetSlideTarget target in _currentTargets) {
        target.didLeave();
      }
      _currentTargets
        ..clear()
        ..addAll(foundTargets);
      for (final _ActionSheetSlideTarget target in _currentTargets) {
        target.didEnter();
      }
    }
  }

  void _onDown(DragDownDetails details) {
    _updateDrag(details.globalPosition);
  }

  void _onUpdate(Offset globalPosition) {
    _updateDrag(globalPosition);
  }

  void _onEnd(Offset globalPosition) {
    _updateDrag(globalPosition);
    for (final _ActionSheetSlideTarget target in _currentTargets) {
      target.didConfirm();
    }
    _currentTargets.clear();
  }

  void _onCancel() {
    for (final _ActionSheetSlideTarget target in _currentTargets) {
      target.didLeave();
    }
    _currentTargets.clear();
  }

  @override
  String get debugDescription => 'target selection';
}
