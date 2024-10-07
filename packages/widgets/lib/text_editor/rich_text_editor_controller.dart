import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

const useRichTextEditorController = _RichTextEditorControllerHookCreator();

class _RichTextEditorControllerHookCreator {
  const _RichTextEditorControllerHookCreator();

  RichTextEditorController call({
    Document? document,
    ReplaceTextCallback? onReplaceText,
  }) {
    return use(_RichTextEditorControllerHook(
      initialDocument: document,
      onReplaceText: onReplaceText,
    ));
  }
}

class _RichTextEditorControllerHook extends Hook<RichTextEditorController> {
  const _RichTextEditorControllerHook({
    this.initialDocument,
    this.onReplaceText,
  });

  final Document? initialDocument;
  final ReplaceTextCallback? onReplaceText;

  @override
  _RichTextEditorControllerHookState createState() =>
      _RichTextEditorControllerHookState();
}

class _RichTextEditorControllerHookState
    extends HookState<RichTextEditorController, _RichTextEditorControllerHook> {
  late final _controller = RichTextEditorController(
    document: hook.initialDocument ?? Document(),
    selection: const TextSelection.collapsed(offset: 0),
    onReplaceText: hook.onReplaceText,
  );

  @override
  void initHook() {
    super.initHook();
  }

  @override
  RichTextEditorController build(BuildContext context) {
    return _controller;
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
    super.onReplaceText,
  });

  String get content => jsonEncode(document.toDelta().toJson());

  set content(String content) {
    if (content.isEmpty) {
      clear();
      return;
    }
    final delta = Delta.fromJson(jsonDecode(content));
    document = Document.fromDelta(delta);
  }

  /// 先頭に改行を入れ、フォーカスする。
  void addNewLineAndMoveCursorToStart() {
    replaceText(
      0,
      0,
      '\n',
      null,
    );
    moveCursorToStart();
  }

  /// サブクラスのclipboardPasteをオーバーライドして、URLがクリップボードにある場合は、URLプレビューを作成する。
  @override
  Future<bool> clipboardPaste({void Function()? updateEditor}) async {
    final text = await Clipboard.getData(Clipboard.kTextPlain);
    // textがurlかどうか。
    final url = Uri.tryParse(text?.text ?? '');
    if (url != null && url.hasAbsolutePath) {
      _createUrlPreview(
        url: url.toString(),
      );
      return true;
    }
    return super.clipboardPaste(updateEditor: updateEditor);
  }

  Future<void> _createUrlPreview({
    required String url,
  }) async {
    final block = BlockEmbed.custom(
      _UrlPreviewBlockEmbed.fromUrl(url),
    );
    final index = selection.baseOffset;
    final length = selection.extentOffset - index;

    replaceText(index, length, block, null);
  }
}

class _UrlPreviewBlockEmbed extends CustomBlockEmbed {
  final String url;

  _UrlPreviewBlockEmbed.fromUrl(this.url) : super('url_preview', url);

  Document get document => Document.fromJson(jsonDecode(data));
}
