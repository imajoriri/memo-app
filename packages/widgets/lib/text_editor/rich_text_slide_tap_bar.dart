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
          _Button(
            onToggle: () {
              controller.toggleCheckList();
            },
            icon: const Icon(Icons.check_box),
          ),
          _Button(
            onToggle: () {
              controller.toggleList(Attribute.ol);
            },
            icon: const Icon(Icons.format_list_numbered),
          ),
          _Button(
            onToggle: () {
              controller.toggleList(Attribute.ul);
            },
            icon: const Icon(Icons.format_list_bulleted),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.onToggle,
    required this.icon,
  });

  final void Function() onToggle;

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SlidingTapItem(
      onEnter: () {
        onToggle();
      },
      onLeave: () {
        onToggle();
      },
      onConfirm: () {},
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: icon,
      ),
    );
  }
}
