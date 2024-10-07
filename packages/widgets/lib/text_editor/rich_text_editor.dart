// ignore_for_file: unnecessary_overrides

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:widgets/async/url_future_builder.dart';
import 'package:widgets/text_editor/rich_text_editor_controller.dart';

void _updateSelectionForKeyPhrase(
    String phrase, Attribute attribute, QuillController controller) {
  controller.replaceText(controller.selection.baseOffset - phrase.length,
      phrase.length, '\n', null);
  _moveCursor(-phrase.length, controller);
  controller
    ..formatSelection(attribute)
    // Remove the added newline.
    ..replaceText(controller.selection.baseOffset + 1, 1, '', null);
}

void _moveCursor(int chars, QuillController controller) {
  final selection = controller.selection;
  controller.updateSelection(
      controller.selection.copyWith(
          baseOffset: selection.baseOffset + chars,
          extentOffset: selection.baseOffset + chars),
      ChangeSource.local);
}

/// `[]`を入力したときに、チェックリストにするショートカット。
// `handleFormatBlockStyleBySpaceEvent`(private method)を参考にしている。
final SpaceShortcutEvent _formatCheckList = SpaceShortcutEvent(
  character: "[]",
  handler: (node, controller) {
    _updateSelectionForKeyPhrase("[]", Attribute.unchecked, controller);
    return true;
  },
);

class RichTextEditor extends HookWidget {
  const RichTextEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.scrollController,
    this.expands = true,
    this.scrollPhysics,
  });

  final RichTextEditorController controller;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final bool expands;
  final ScrollPhysics? scrollPhysics;

  @override
  Widget build(BuildContext context) {
    final effectiveFocusNode = focusNode ?? useFocusNode();
    return QuillEditor.basic(
      focusNode: effectiveFocusNode,
      controller: controller,
      scrollController: scrollController,
      configurations: QuillEditorConfigurations(
        expands: expands,
        scrollPhysics: scrollPhysics,
        padding: const EdgeInsets.all(16),
        spaceShortcutEvents: [
          ...standardSpaceShorcutEvents,
          _formatCheckList,
        ],
        characterShortcutEvents: standardCharactersShortcutEvents,
        embedBuilders: [
          _UrlPreviewEmbedBuilder(),
        ],
      ),
    );
  }
}

class _UrlPreviewEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'url_preview';

  @override
  String toPlainText(Embed node) => node.value.data;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final url = node.value.data;
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse(url));
      },
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          alignment: Alignment.centerLeft,
          // TODO: 横幅目一杯に広がってしまうのを防ぐ。
          child: UrlFutureBuilder(
            key: ValueKey(url),
            url: Uri.parse(url),
            data: (ogp) => Row(
              children: [
                if (ogp.iconUrl != null)
                  Image.network(
                    ogp.iconUrl!,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ogp.title ?? '',
                    style: textStyle,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text(url),
          ),
        ),
      ),
    );
  }
}
