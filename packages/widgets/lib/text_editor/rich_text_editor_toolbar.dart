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
    return Container(
      color: Colors.grey[200],
      child: QuillToolbar(
        configurations: toolbarConfigurations,
        child: Row(
          children: [
            QuillToolbarToggleCheckListButton(
              options: toolbarConfigurations.buttonOptions.toggleCheckList,
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
          ],
        ),
      ),
    );
  }
}
