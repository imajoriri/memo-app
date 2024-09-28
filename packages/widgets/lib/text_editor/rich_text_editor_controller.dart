import 'dart:convert';

import 'package:flutter/widgets.dart';
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

  bool isSame(String content) => this.content == content;

  set content(String content) {
    if (content.isEmpty) {
      clear();
      return;
    }
    final delta = Delta.fromJson(jsonDecode(content));
    document = Document.fromDelta(delta);
  }
}
