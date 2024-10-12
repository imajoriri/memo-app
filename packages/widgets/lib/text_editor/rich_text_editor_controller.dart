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

  bool _getIsCheckedList() {
    var attribute = toolbarButtonToggler[Attribute.list.key];

    if (attribute == null) {
      attribute = getSelectionStyle().attributes[Attribute.list.key];
    } else {
      // checkbox tapping causes controller.selection to go to offset 0
      toolbarButtonToggler.remove(Attribute.list.key);
    }

    if (attribute == null) {
      return false;
    }
    return attribute.value == Attribute.unchecked.value ||
        attribute.value == Attribute.checked.value;
  }

  /// 現在のフォーカスしているリストをチェックリストに変換する。
  void toggleCheckList() {
    formatSelection(
      _getIsCheckedList()
          ? Attribute.clone(Attribute.unchecked, null)
          : Attribute.unchecked,
    );
  }

  bool getIsList({
    required Attribute attribute,
  }) {
    if (attribute.key == Attribute.list.key ||
        attribute.key == Attribute.header.key ||
        attribute.key == Attribute.script.key ||
        attribute.key == Attribute.align.key) {
      final attr = getSelectionStyle().attributes[attribute.key];
      if (attr == null) {
        return false;
      }
      return attr.value == attribute.value;
    }
    return getSelectionStyle().attributes.containsKey(attribute.key);
  }

  // 参考: [QuillToolbarToggleStyleButtonState]
  void toggleList(Attribute attribute) {
    formatSelection(
      getIsList(attribute: attribute)
          ? Attribute.clone(attribute, null)
          : attribute,
    );
  }

  /// 現在の行を削除する。
  void deleteCurrentLine() {
    final currentDelta = document.toDelta();
    // 現在のoffsetを取得
    final offset = selection.baseOffset;

    // offsetの行の先頭のoffsetを取得
    final text = document.toPlainText();
    // 改行のoffset一覧
    final lineBreaks = [];
    var tmp = 0;
    text.split('\n').forEach((e) {
      lineBreaks.add(tmp);
      tmp += e.length + 1;
    });
    final startOffset = lineBreaks.lastWhere((e) => e <= offset);
    final endOffset = lineBreaks.firstWhere((e) => e > offset);
    try {
      replaceText(
        startOffset,
        endOffset - startOffset,
        '',
        TextSelection.collapsed(offset: startOffset),
      );
    } catch (e) {
      // 元のdeltaに戻す
      document = Document.fromDelta(currentDelta);
    }
  }

  /// 現在の行の下に新しい行を追加する。
  void addNewLineToCurrentLine() {
    final currentDelta = document.toDelta();
    // 現在のoffsetを取得
    final offset = selection.baseOffset;

    // offsetの行の先頭のoffsetを取得
    final text = document.toPlainText();
    // 改行のoffset一覧
    final lineBreaks = [];
    var tmp = 0;
    text.split('\n').forEach((e) {
      lineBreaks.add(tmp);
      tmp += e.length + 1;
    });
    final endOffset = lineBreaks.firstWhere((e) => e > offset);
    try {
      replaceText(
        endOffset,
        0,
        '\n',
        TextSelection.collapsed(offset: endOffset),
      );
    } catch (e) {
      // 元のdeltaに戻す
      document = Document.fromDelta(currentDelta);
    }
  }
}

class _UrlPreviewBlockEmbed extends CustomBlockEmbed {
  final String url;

  _UrlPreviewBlockEmbed.fromUrl(this.url) : super('url_preview', url);

  Document get document => Document.fromJson(jsonDecode(data));
}
