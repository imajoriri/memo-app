import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rich_text_editor/controller/rich_text_editor_controller.dart';
import 'package:widgets/widget.dart';

class RichTextEditorToolbar extends StatelessWidget {
  const RichTextEditorToolbar({
    super.key,
    required this.controller,
    this.leftAddPadding = 0,
    this.rightAddPadding = 0,
  });

  final RichTextEditorController controller;
  final double leftAddPadding;
  final double rightAddPadding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutExpo,
      color: Colors.grey[200],
      padding: EdgeInsets.only(
        left: context.tokeruSpacing.smallX + leftAddPadding,
        right: context.tokeruSpacing.smallX + rightAddPadding,
        bottom: context.tokeruSpacing.smallX,
        top: context.tokeruSpacing.smallX,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Buttons(controller: controller),
          ),

          // キーボード閉じるボタン
          TokeruIconButton.medium(
            onPressed: () {
              // キーボードを閉じる
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(CupertinoIcons.keyboard_chevron_compact_down),
          ),
        ],
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({
    required this.controller,
  });

  final RichTextEditorController controller;

  @override
  Widget build(BuildContext context) {
    const space = 8.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 現在の行をチェックボックスにする
          TokeruIconButton.medium(
            icon: const Icon(CupertinoIcons.text_badge_checkmark),
            onPressed: () {
              controller.toggleCheckbox();
            },
          ),
          const SizedBox(width: space),

          // 現在の行をbulletにする
          TokeruIconButton.medium(
            onPressed: () {
              controller.toggleBullet();
            },
            icon: const Icon(CupertinoIcons.list_bullet),
          ),
          const SizedBox(width: space),

          // 現在の行をnumber listにする
          TokeruIconButton.medium(
            onPressed: () {
              controller.toggleNumberList();
            },
            icon: const Icon(CupertinoIcons.list_number),
          ),
          const SizedBox(width: space),

          // インデントをプラスする
          TokeruIconButton.medium(
            onPressed: () {
              controller.increaseIndent();
            },
            icon: const Icon(Icons.format_indent_increase),
          ),
          const SizedBox(width: space),

          // インデントをマイナスする
          TokeruIconButton.medium(
            onPressed: () {
              controller.decreaseIndent();
            },
            icon: const Icon(Icons.format_indent_decrease),
          ),
          const SizedBox(width: space),

          // 現在の行をHeaderにする
          TokeruIconButton.medium(
            onPressed: () {
              controller.toggleHeader(1);
            },
            icon: const AFMobileIcon(
              afMobileIcons: AFMobileIcons.h1,
              size: 20,
            ),
          ),
          const SizedBox(width: space),

          TokeruIconButton.medium(
            onPressed: () {
              controller.toggleHeader(2);
            },
            icon: const AFMobileIcon(
              afMobileIcons: AFMobileIcons.h2,
              size: 20,
            ),
          ),
          const SizedBox(width: space),

          TokeruIconButton.medium(
            onPressed: () {
              controller.toggleHeader(3);
            },
            icon: const AFMobileIcon(
              afMobileIcons: AFMobileIcons.h3,
              size: 20,
            ),
          ),
          const SizedBox(width: space),

          // 現在の行を削除するボタン
          TokeruIconButton.medium(
            onPressed: () {
              controller.deleteCurrentLine();
            },
            icon: const Icon(Icons.delete),
          ),
          const SizedBox(width: space),

          // 現在の行の下に新しい行を追加するボタン
          TokeruIconButton.medium(
            onPressed: () {
              controller.addNewLineToCurrentLine();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
