import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

const useRichTextEditorController = _RichTextEditorControllerHookCreator();

class _RichTextEditorControllerHookCreator {
  const _RichTextEditorControllerHookCreator();

  RichTextEditorController call({Document? document}) {
    return use(_RichTextEditorControllerHook(document));
  }
}

class _RichTextEditorControllerHook extends Hook<RichTextEditorController> {
  const _RichTextEditorControllerHook(this.initialDocument);

  final Document? initialDocument;

  @override
  _RichTextEditorControllerHookState createState() =>
      _RichTextEditorControllerHookState();
}

class _RichTextEditorControllerHookState
    extends HookState<RichTextEditorController, _RichTextEditorControllerHook> {
  late final _controller = RichTextEditorController(
    document: hook.initialDocument ?? Document(),
    selection: const TextSelection.collapsed(offset: 0),
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
  });

  String get content => jsonEncode(document.toDelta().toJson());

  bool isSame(String content) => this.content == content;

  set content(String content) {
    if (content.isEmpty) {
      replaceText(
        0,
        plainTextEditingValue.text.length - 1,
        '',
        const TextSelection.collapsed(offset: 0),
        shouldNotifyListeners: false,
      );
      return;
    }

    replaceText(
      0,
      document.length,
      Delta.fromJson(jsonDecode(content)),
      null,
      // 無駄な更新が走らないように、addListenerを使わないようにする。
      shouldNotifyListeners: false,
    );
  }
}
