import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rich_text_editor/controller/rich_text_editor_controller.dart';

part 'feedback.dart';
part 'rich_text_tile.dart';
part 'position.dart';
part 'drop_area.dart';
part 'should_ignore_drop.dart';

class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    super.key,
    required this.editorState,
    required this.focusNode,
    this.scrollController,
    this.scrollPhysics,
    this.padding,
    this.onContentChanged,
    this.header,
    this.footer,
  });

  final RichTextEditorState editorState;
  final FocusNode focusNode;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets? padding;
  final Function(String)? onContentChanged;
  final Widget? header;
  final Widget? footer;

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  bool hasFocus = false;
  late final Map<String, BlockComponentBuilder>
      blockComponentBuildersForDragging;
  late final EditorScrollController editorScrollController;

  @override
  void initState() {
    super.initState();
    blockComponentBuildersForDragging = _buildBlockComponentBuilders();

    editorScrollController = EditorScrollController(
      editorState: widget.editorState,
    );

    widget.focusNode.addListener(() {
      print('focusNode: ${widget.focusNode.hasFocus}');
      setState(() {
        hasFocus = widget.focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Offset? globalPosition;

    widget.editorState.transactionStream.listen((event) {
      if (event.$1 == TransactionTime.after) {
        widget.onContentChanged?.call(jsonEncode(event.$2.document.toJson()));
      }
    });
    const tilePadding = EdgeInsets.symmetric(horizontal: 4, vertical: 2);

    return MobileFloatingToolbar(
      editorState: widget.editorState,
      editorScrollController: editorScrollController,
      toolbarBuilder: (context, anchor, closeToolbar) {
        return AdaptiveTextSelectionToolbar.editable(
          clipboardStatus: ClipboardStatus.pasteable,
          onCopy: () {
            copyCommand.execute(widget.editorState);
            closeToolbar();
          },
          onCut: () => cutCommand.execute(widget.editorState),
          onPaste: () => pasteCommand.execute(widget.editorState),
          onSelectAll: () => selectAllCommand.execute(widget.editorState),
          onLiveTextInput: null,
          onLookUp: null,
          onSearchWeb: null,
          onShare: null,
          anchors: TextSelectionToolbarAnchors(
            primaryAnchor: anchor,
          ),
        );
      },
      child: AppFlowyEditor(
        header: widget.header,
        footer: widget.footer,
        focusNode: widget.focusNode,
        editorState: widget.editorState,
        editorScrollController: editorScrollController,
        enableAutoComplete: true,
        editorStyle: const EditorStyle.mobile(
          padding: EdgeInsets.zero,
        ),
        blockComponentBuilders: _buildBlockComponentBuilders(),
        commandShortcutEvents: [
          ...standardCommandShortcutEvents,
        ],
        characterShortcutEvents: [
          ...standardCharacterShortcutEvents,
        ],
        buildWrapper: (context, child, node, blockComponentContext) {
          final blockComponentContextForFeedback = BlockComponentContext(
            context,
            blockComponentContext.node.copyWith(),
          );
          return _RichTextTile(
            padding: tilePadding,
            blockComponentContext: blockComponentContext,
            editorState: widget.editorState,
            blockComponentBuilders: blockComponentBuildersForDragging,
            hasFocus: hasFocus,
            onDragStarted: () {
              widget.editorState.selectionService.removeDropTarget();
            },
            onDragUpdate: (details) {
              widget.editorState.selectionService.renderDropTargetForOffset(
                details.globalPosition,
                builder: (context, data) => DropArea(
                  data: data,
                  dragNode: node,
                ),
              );

              globalPosition = details.globalPosition;

              widget.editorState.scrollService
                  ?.startAutoScroll(details.globalPosition);
            },
            onDragEnd: (details) {
              widget.editorState.selectionService.removeDropTarget();

              if (globalPosition == null) {
                return;
              }

              final data =
                  widget.editorState.selectionService.getDropTargetRenderData(
                globalPosition!,
              );

              _moveNodeToNewPosition(
                context,
                widget.editorState,
                blockComponentContext,
                node,
                data?.cursorNode?.path,
                globalPosition!,
              );
            },
            feedback: _Feedback(
              editorState: widget.editorState,
              blockComponentBuilders: blockComponentBuildersForDragging,
              blockComponentContext: blockComponentContextForFeedback,
              padding: tilePadding,
            ),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _moveNodeToNewPosition(
    BuildContext context,
    EditorState editorState,
    BlockComponentContext blockComponentContext,
    Node node,
    Path? acceptedPath,
    Offset dragOffset,
  ) async {
    if (acceptedPath == null) return;

    final targetNode = editorState.getNodeAtPath(acceptedPath);
    if (targetNode == null) return;

    final position = _getPosition(context, targetNode, dragOffset);
    if (position == null) return;

    final (verticalPosition, horizontalPosition, _) = position;
    Path newPath = targetNode.path;

    // Determine the new path based on drop position
    // For VerticalPosition.top, we keep the target node's path
    if (verticalPosition == VerticalPosition.bottom) {
      newPath = horizontalPosition == HorizontalPosition.left
          ? newPath.next // Insert after target node
          : newPath.child(0); // Insert as first child of target node
    }

    // Check if the drop should be ignored
    if (_shouldIgnoreDrop(node, newPath)) {
      debugPrint(
        'Drop ignored: node($node, ${node.path}), path($acceptedPath)',
      );
      return;
    }

    final realNode = blockComponentContext.node;
    debugPrint('Moving node($realNode, ${realNode.path}) to path($newPath)');

    // Perform the node move operation
    final transaction = editorState.transaction;
    transaction.moveNode(newPath, realNode);
    await editorState.apply(transaction);
  }
}

Map<String, BlockComponentBuilder> _buildBlockComponentBuilders() {
  final map = {
    ...standardBlockComponentBuilderMap,
  };
  // Headerをカスタマイズ
  final levelToFontSize = isMobile
      ? [
          24.0,
          20.0,
          16.0,
          14.0,
          12.0,
          10.0,
        ]
      : [
          30.0,
          26.0,
          22.0,
          18.0,
          16.0,
          14.0,
        ];
  map[HeadingBlockKeys.type] = HeadingBlockComponentBuilder(
    textStyleBuilder: (level) => TextStyle(
      fontSize: levelToFontSize.elementAtOrNull(level - 1) ?? 14.0,
      fontWeight: FontWeight.w700,
    ),
  );

  // map.forEach((key, value) {
  //   // 1行ごとのpaddingを設定
  //   value.configuration = value.configuration.copyWith(
  //     padding: (_) => const EdgeInsets.symmetric(vertical: 8.0),
  //   );
  // });
  return map;
}

final isMobile = switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS => true,
  _ => false,
};
