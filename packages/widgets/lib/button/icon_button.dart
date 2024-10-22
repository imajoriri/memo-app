import 'package:flutter/material.dart';
import 'package:widgets/button/app_button.dart';
import 'package:widgets/theme/theme.dart';

/// 小さめのアイコンボタン。
class TokeruIconButton extends StatefulWidget {
  /// アイコンのWidget。
  final Widget icon;

  /// クリック時の処理。
  final void Function()? onPressed;

  /// ツールチップ。
  final String? tooltip;

  /// アイコンのサイズ。
  final double iconSize;

  /// パディング。
  final EdgeInsets padding;

  /// ボタンの角の丸み。
  final double radius;

  /// Borderを表示するかどうか。
  final bool showBorder;

  const TokeruIconButton.medium({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.showBorder = false,
  })  : iconSize = 20,
        padding = const EdgeInsets.all(8),
        radius = 8;

  const TokeruIconButton.small({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.showBorder = false,
  })  : iconSize = 16,
        padding = const EdgeInsets.all(4),
        radius = 8;

  @override
  State<TokeruIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<TokeruIconButton> {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: AppButton(
        style: AppButtonStyle(
          contentColor: context.tokeruColors.onSurface,
          backgroundColor: context.tokeruColors.surface.withOpacity(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
          ),
        ),
        onPressed: widget.onPressed,
        child: Container(
          padding: widget.padding,
          decoration: widget.showBorder
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(
                    color: context.tokeruColors.outline,
                  ),
                )
              : null,
          child: IconTheme.merge(
            child: widget.icon,
            data: IconThemeData(
              size: widget.iconSize,
              color: context.tokeruColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
