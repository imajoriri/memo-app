import 'package:flutter/material.dart';

extension _ButtonStatusColor on Color {
  /// ホバー時のカラーを返すメソッド。
  Color get hovered => withOpacity(0.08);

  /// フォーカス時のカラーを返すメソッド。
  Color get focused => withOpacity(0.10);

  /// プレス時のカラーを返すメソッド。
  Color get pressed => withOpacity(0.10);

  /// Disabledのカラーを返すメソッド。
  Color get disabled => withOpacity(0.38);
}

class AppButtonStyle {
  /// ボタンのコンテンツ(中身)のカラー。
  ///
  /// [IconTheme]、[DefaultTextStyle]を使用してコンテンツのカラーとして使用される。
  /// ホバーやフォーカス時のカラーは、このカラーを元に計算される。
  final Color contentColor;

  /// ボタンの背景色。
  final Color backgroundColor;

  /// ホバー時のカラー。
  ///
  /// nullの場合、[_ButtonStatusColor.hovered]が使用される。
  final Color? hoveredColor;

  /// フォーカス時のカラー。
  ///
  /// nullの場合、[_ButtonStatusColor.focused]が使用される。
  final Color? focusedColor;

  /// プレス時のカラー。
  ///
  /// nullの場合、[_ButtonStatusColor.pressed]が使用される。
  final Color? pressedColor;

  /// Disabled時のカラー。
  ///
  /// nullの場合、[_ButtonStatusColor.disabled]が使用される。
  final Color? disabledColor;

  /// ボタンのカラーが変更時にアニメーションするかどうか。
  final bool stateColorAnimated;

  /// ボタンの背景色のカラーが変更時にアニメーションするかどうか。
  final bool backgroundColorAnimated;

  /// ボタンの形状。
  final ShapeBorder shape;

  const AppButtonStyle({
    required this.contentColor,
    required this.backgroundColor,
    this.hoveredColor,
    this.focusedColor,
    this.pressedColor,
    this.disabledColor,
    this.stateColorAnimated = true,
    this.backgroundColorAnimated = true,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  });
}

/// ボタンとしての基本的な機能を持つWidget
///
/// - Hovered, Focused, Pressedの状態に応じて、カラーを変更する。
/// - Pressed状態の時にbounceする。([bounce]がtrueの時)
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.style,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.skipTraversal = false,
  }) : bounce = onLongPress != null;

  final AppButtonStyle style;

  final Widget child;

  /// ボタンが押された時のコールバック。
  final void Function()? onPressed;

  final void Function()? onLongPress;

  /// Pressed状態の時にbounceするかどうか。
  ///
  /// バウンスすることで長押し可能であることを示唆したいため、[onLongPress]がnullの場合はbounceしない。
  final bool bounce;

  final bool skipTraversal;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool get enabled => widget.onPressed != null;

  bool hover = false;
  bool focus = false;
  bool pressed = false;

  void onInvoke() {
    if (widget.onPressed == null) {
      return;
    }
    if (!pressed) {
      setState(() {
        pressed = true;
      });
    }
    widget.onPressed?.call();
    if (context.mounted) {
      setState(() {
        pressed = false;
      });
    }
    return;
  }

  Color get overlayColor {
    late final Color overlayColor;
    if (!enabled) {
      overlayColor =
          widget.style.disabledColor ?? widget.style.contentColor.disabled;
    } else if (pressed) {
      overlayColor =
          widget.style.pressedColor ?? widget.style.contentColor.pressed;
    } else if (hover) {
      overlayColor =
          widget.style.hoveredColor ?? widget.style.contentColor.hovered;
    } else if (focus) {
      overlayColor =
          widget.style.focusedColor ?? widget.style.contentColor.focused;
    } else {
      overlayColor = widget.style.backgroundColor.withOpacity(0);
    }
    return overlayColor;
  }

  @override
  Widget build(BuildContext context) {
    // ボタンの背景色のアニメーション時間。
    final backgroundColorDuration =
        Duration(milliseconds: widget.style.backgroundColorAnimated ? 150 : 0);

    // ボタンのステートによるカラー変更のアニメーション時間。
    final stateColorduration =
        Duration(milliseconds: widget.style.stateColorAnimated ? 150 : 0);

    // ボタンのbounceアニメーション時間。
    const bounceDuration = Duration(milliseconds: 200);

    return Semantics(
      container: true,
      child: FocusableActionDetector(
        focusNode: FocusNode(skipTraversal: widget.skipTraversal || !enabled),
        onShowHoverHighlight: (value) => setState(() {
          hover = value;
        }),
        onShowFocusHighlight: (value) => setState(() {
          focus = value;
        }),
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        actions: <Type, Action<Intent>>{
          ActivateIntent:
              CallbackAction<ActivateIntent>(onInvoke: (_) => onInvoke()),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => onInvoke(),
          ),
        },
        child: GestureDetector(
          onTap: onInvoke,
          onTapDown: (detail) => setState(() {
            pressed = true;
          }),
          onTapCancel: () => setState(() {
            pressed = false;
          }),
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            duration: bounceDuration,
            curve: Curves.easeOutExpo,
            scale: pressed && enabled && widget.bounce ? 0.95 : 1.0,
            child: Stack(
              children: [
                // Container layer
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: backgroundColorDuration,
                    decoration: ShapeDecoration(
                      color: widget.style.backgroundColor,
                      shape: widget.style.shape,
                    ),
                  ),
                ),

                // State layer
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: stateColorduration,
                    decoration: ShapeDecoration(
                      color: overlayColor,
                      shape: widget.style.shape,
                    ),
                  ),
                ),

                // Content layer
                IconTheme.merge(
                  data: IconThemeData(
                    color: widget.style.contentColor,
                  ),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: widget.style.contentColor,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
