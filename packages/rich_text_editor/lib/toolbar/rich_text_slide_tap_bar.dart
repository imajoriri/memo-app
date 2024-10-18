import 'package:flutter/material.dart';
import 'package:rich_text_editor/controller/rich_text_editor_controller.dart';
import 'package:widgets/button/slide_tap.dart';

class RichTextSlideTapBar extends StatelessWidget {
  const RichTextSlideTapBar({
    super.key,
    required this.controller,
  });

  final RichTextEditorController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
    // return SlidingTapGroup(
    //   child: Column(
    //     children: [
    //       _Button(
    //         onToggle: () {
    //           controller.toggleCheckList();
    //         },
    //         icon: const Icon(Icons.check_box),
    //       ),
    //       _Button(
    //         onToggle: () {
    //           controller.toggleList(Attribute.ol);
    //         },
    //         icon: const Icon(Icons.format_list_numbered),
    //       ),
    //       _Button(
    //         onToggle: () {
    //           controller.toggleList(Attribute.ul);
    //         },
    //         icon: const Icon(Icons.format_list_bulleted),
    //       ),
    //     ],
    //   ),
    // );
  }
}

class _Button extends StatelessWidget {
  const _Button({
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
