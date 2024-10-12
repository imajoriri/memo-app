import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:widgets/text_editor/rich_text_editor_controller.dart';

class RichTextEditorToolbar extends StatelessWidget {
  const RichTextEditorToolbar({
    super.key,
    required this.controller,
  });

  final RichTextEditorController controller;

  @override
  Widget build(BuildContext context) {
    const toolbarConfigurations = QuillToolbarConfigurations();
    // return QuillSimpleToolbar(
    //   configurations: QuillSimpleToolbarConfigurations(),
    //   controller: controller,
    // );
    return Container(
      color: Colors.grey[200],
      child: QuillToolbar(
        configurations: toolbarConfigurations,
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // QuillSimpleToolbar参照
                    QuillToolbarToggleCheckListButton(
                      options:
                          toolbarConfigurations.buttonOptions.toggleCheckList,
                      controller: controller,
                    ),
                    QuillToolbarToggleStyleButton(
                      attribute: Attribute.ol,
                      options: toolbarConfigurations.buttonOptions.listNumbers,
                      controller: controller,
                    ),
                    QuillToolbarToggleStyleButton(
                      attribute: Attribute.ul,
                      options: toolbarConfigurations.buttonOptions.listBullets,
                      controller: controller,
                    ),
                    QuillToolbarToggleStyleButton(
                      attribute: Attribute.bold,
                      options: toolbarConfigurations.buttonOptions.bold,
                      controller: controller,
                    ),
                    QuillToolbarIndentButton(
                      controller: controller,
                      isIncrease: true,
                      options:
                          toolbarConfigurations.buttonOptions.indentIncrease,
                    ),
                    QuillToolbarIndentButton(
                      controller: controller,
                      isIncrease: false,
                      options:
                          toolbarConfigurations.buttonOptions.indentDecrease,
                    ),
                    QuillToolbarSelectHeaderStyleButtons(
                      controller: controller,
                      options: toolbarConfigurations
                          .buttonOptions.selectHeaderStyleButtons,
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
      ),
    );
  }
}
