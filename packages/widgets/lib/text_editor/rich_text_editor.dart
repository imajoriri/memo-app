// ignore_for_file: unnecessary_overrides

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:widgets/async/url_future_builder.dart';

RichTextEditorController useRichTextEditorController() {
  return use(const _RichTextEditorControllerHook());
}

class _RichTextEditorControllerHook extends Hook<RichTextEditorController> {
  const _RichTextEditorControllerHook();

  @override
  _RichTextEditorControllerHookState createState() =>
      _RichTextEditorControllerHookState();
}

class _RichTextEditorControllerHookState
    extends HookState<RichTextEditorController, _RichTextEditorControllerHook> {
  @override
  void initHook() {
    super.initHook();
  }

  @override
  RichTextEditorController build(BuildContext context) {
    return RichTextEditorController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class RichTextEditorController extends QuillController {
  RichTextEditorController({
    required super.document,
    required super.selection,
  });

  String get content => jsonEncode(document.toDelta().toJson());

  bool isSame(String content) => this.content == content;

  set content(String content) {
    document = Document.fromDelta(Delta.fromJson(jsonDecode(content)));
  }
}

class RichTextEditor extends StatelessWidget {
  const RichTextEditor({
    super.key,
    required this.controller,
  });

  final RichTextEditorController controller;

  Future<void> _createUrlPreview({
    required String url,
    required QuillController controller,
  }) async {
    final block = BlockEmbed.custom(
      _UrlPreviewBlockEmbed.fromUrl(url),
    );
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    controller.replaceText(index, length, block, null);
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      controller: controller,
      configurations: QuillEditorConfigurations(
        expands: true,
        customActions: {
          PasteTextIntent: CallbackAction(onInvoke: (intent) async {
            final text = await Clipboard.getData(Clipboard.kTextPlain);
            // textがurlかどうか。
            final url = Uri.tryParse(text?.text ?? '');
            if (url != null && url.hasAbsolutePath) {
              _createUrlPreview(
                url: url.toString(),
                controller: controller,
              );
              return true;
            }
            controller.clipboardPaste();
            return null;
          }),
        },
        padding: const EdgeInsets.all(16),
        spaceShortcutEvents: standardSpaceShorcutEvents,
        characterShortcutEvents: standardCharactersShortcutEvents,
        embedBuilders: [
          _UrlPreviewEmbedBuilder(),
        ],
      ),
    );
  }
}

class _UrlPreviewBlockEmbed extends CustomBlockEmbed {
  final String url;

  _UrlPreviewBlockEmbed.fromUrl(this.url) : super('url_preview', url);

  Document get document => Document.fromJson(jsonDecode(data));
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
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse(node.value.data));
      },
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          alignment: Alignment.centerLeft,
          // TODO: 横幅目一杯に広がってしまうのを防ぐ。
          child: UrlFutureBuilder(
            url: Uri.parse(node.value.data),
            data: (ogp) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ogp.iconUrl != null)
                  Image.network(
                    ogp.iconUrl!,
                    width: 16,
                    height: 16,
                  ),
                const SizedBox(width: 8),
                Text(
                  ogp.title ?? '',
                  style: textStyle,
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text(e.toString()),
          ),
        ),
      ),
    );
  }
}
