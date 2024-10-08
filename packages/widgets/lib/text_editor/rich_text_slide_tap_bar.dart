import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:widgets/button/slide_tap.dart';
import 'package:widgets/text_editor/rich_text_editor_controller.dart';

class RichTextSlideTapBar extends StatelessWidget {
  const RichTextSlideTapBar({
    super.key,
    required this.controller,
  });

  final RichTextEditorController controller;

  @override
  Widget build(BuildContext context) {
    return SlidingTapGroup(
      child: Column(
        children: [
          SlidingTapItem(
            onEnter: () {
              controller.toggleCheckList();
            },
            onLeave: () {
              controller.toggleCheckList();
            },
            onConfirm: () {},
            child: const Icon(Icons.check_box),
          ),
          SlidingTapItem(
            onEnter: () {
              controller.toggleList(Attribute.ol);
            },
            onLeave: () {
              controller.toggleList(Attribute.ol);
            },
            onConfirm: () {},
            child: const Icon(Icons.format_list_numbered),
          ),
          SlidingTapItem(
            onEnter: () {
              controller.toggleList(Attribute.ul);
            },
            onLeave: () {
              controller.toggleList(Attribute.ul);
            },
            onConfirm: () {},
            child: const Icon(Icons.format_list_bulleted),
          ),
        ],
      ),
    );
  }
}
