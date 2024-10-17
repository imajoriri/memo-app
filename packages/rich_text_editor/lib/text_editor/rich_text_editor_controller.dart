import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rich_text_editor_controller.g.dart';

/*
- EditorState
  - Document
  - Transaction
  - Selection
- Document
  - root: Node
- Node
  - type: String
  - children: List<Node>
- Transaction
  - Document
- Selection
  - start: Position
  - end: Position
- Position
  - path: List<int>
  - offset: int
- Path: List<int>
*/

class RichTextEditorState extends EditorState {
  RichTextEditorState({
    Document? document,
  }) : super(document: document ?? Document.blank());

  RichTextEditorState.blank() : super(document: Document.blank());
}

@riverpod
class RichTextEditorController extends _$RichTextEditorController {
  @override
  RichTextEditorState build() {
    return RichTextEditorState();
  }

  void updateContent(String content) {
    // TODO: 本来はEditorStateを直接更新するのではなく、
    // EditorStateかそのdocumentのメソッドで更新したい。
    if (content.isEmpty) {
      state = RichTextEditorState.blank();
      return;
    }
    final json = Map<String, Object>.from(jsonDecode(content));
    final document = Document.fromJson(json);
    state = RichTextEditorState(document: document);
  }

  /// 先頭に改行を入れ、フォーカスする。
  void addNewLineAndMoveCursorToStart() {
    state.document.insert(
      [0],
      [
        paragraphNode(delta: Delta()..insert('\n')),
      ],
    );
    // フォーカスを先頭に移動する。
    state.updateSelectionWithReason(
      Selection.single(
        path: [0],
        startOffset: 0,
      ),
      reason: SelectionUpdateReason.uiEvent,
    );
  }

  /// 現在の行を削除する。
  void deleteCurrentLine() {
    // 現在のpath
    final path = state.selection?.start.path;
    if (path == null) {
      return;
    }
    final node = state.getNodeAtPath(path);

    final transaction = state.transaction;
    transaction.deleteNode(
      node!,
    );
    state.apply(
      transaction,
      withUpdateSelection: false,
    );

    // 元いた行にフォーカスを移動する。
    state.updateSelectionWithReason(
      Selection.single(
        path: path,
        startOffset: 0,
      ),
      reason: SelectionUpdateReason.uiEvent,
    );
  }

  /// 現在の行の下に新しい行を追加する。
  void addNewLineToCurrentLine() {
    final currentPath = state.selection?.end.path;
    if (currentPath == null) {
      return;
    }
    final transaction = state.transaction;
    transaction.insertNodes(
      [currentPath.first + 1],
      [paragraphNode(delta: Delta()..insert(''))],
    );
    state.apply(
      transaction,
      withUpdateSelection: false,
    );

    // 追加した行にフォーカスを移動する。
    state.updateSelectionWithReason(
      Selection.single(
        path: [currentPath.first + 1],
        startOffset: 0,
      ),
      reason: SelectionUpdateReason.uiEvent,
    );
  }

  /// 現在の行をチェックボックスにする。
  void toggleCheckbox() {
    final selection = state.selection;
    if (selection == null) {
      return;
    }
    final node = state.getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    final isTodoList = node.type == TodoListBlockKeys.type;

    state.formatNode(
      selection,
      (node) => node.copyWith(
        type: isTodoList ? ParagraphBlockKeys.type : TodoListBlockKeys.type,
        attributes: {
          TodoListBlockKeys.checked: false,
          ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
        },
      ),
    );
  }

  /// 現在の行をbulletにする。
  void toggleBullet() {
    final selection = state.selection;
    if (selection == null) {
      return;
    }
    final node = state.getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    final isTodoList = node.type == BulletedListBlockKeys.type;

    state.formatNode(
      selection,
      (node) => node.copyWith(
        type: isTodoList ? ParagraphBlockKeys.type : BulletedListBlockKeys.type,
        attributes: {
          ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
        },
      ),
    );
  }

  /// インデントをプラスする
  void increaseIndent() {
    indentCommand.execute(state);
  }

  /// インデントをマイナスする
  void decreaseIndent() {
    outdentCommand.execute(state);
  }

  /// Headerにする。
  void toggleHeader(int level) {
    final selection = state.selection;
    if (selection == null) {
      return;
    }
    final node = state.getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    // Headerかつlevelが一致しているかどうか。
    // Header1の場合にHeader2に変更するときに、Paragraphに変更されてしまうため。
    final isHeader = node.type == HeadingBlockKeys.type &&
        node.attributes[HeadingBlockKeys.level] == level;
    state.formatNode(
      selection,
      (node) => node.copyWith(
        type: isHeader ? ParagraphBlockKeys.type : HeadingBlockKeys.type,
        attributes: {
          HeadingBlockKeys.level: level,
          HeadingBlockKeys.delta: (node.delta ?? Delta()).toJson(),
        },
      ),
    );
  }
}
