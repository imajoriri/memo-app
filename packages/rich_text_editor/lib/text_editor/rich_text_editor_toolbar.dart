import 'package:flutter/material.dart';
import 'package:rich_text_editor/text_editor/rich_text_editor_controller.dart';

class RichTextEditorToolbar extends StatelessWidget {
  const RichTextEditorToolbar({
    super.key,
    required this.controller,
    this.padding = EdgeInsets.zero,
  });

  final RichTextEditorController controller;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutExpo,
      color: Colors.grey[200],
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 現在の行をチェックボックスにする
                  IconButton(
                    onPressed: () {
                      controller.toggleCheckbox();
                    },
                    icon: const Icon(Icons.check_box),
                  ),

                  // 現在の行をbulletにする
                  IconButton(
                    onPressed: () {
                      controller.toggleBullet();
                    },
                    icon: const Icon(Icons.format_list_bulleted),
                  ),

                  // インデントをプラスする
                  IconButton(
                    onPressed: () {
                      controller.increaseIndent();
                    },
                    icon: const Icon(Icons.format_indent_increase),
                  ),

                  // インデントをマイナスする
                  IconButton(
                    onPressed: () {
                      controller.decreaseIndent();
                    },
                    icon: const Icon(Icons.format_indent_decrease),
                  ),

                  // 現在の行をHeaderにする
                  IconButton(
                    onPressed: () {
                      controller.toggleHeader(1);
                    },
                    icon: const Icon(Icons.format_bold),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.toggleHeader(2);
                    },
                    icon: const Icon(Icons.format_bold),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.toggleHeader(3);
                    },
                    icon: const Icon(Icons.format_bold),
                  ),

                  // 現在の行を削除するボタン
                  IconButton(
                    onPressed: () {
                      controller.deleteCurrentLine();
                    },
                    icon: const Icon(Icons.delete),
                  ),

                  // 現在の行の下に新しい行を追加するボタン
                  IconButton(
                    onPressed: () {
                      controller.addNewLineToCurrentLine();
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),

          // キーボード閉じるボタン
          IconButton(
            onPressed: () {
              // キーボードを閉じる
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(Icons.keyboard_hide),
          ),
        ],
      ),
    );
  }
}
