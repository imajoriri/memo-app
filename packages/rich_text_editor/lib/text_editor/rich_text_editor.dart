import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:rich_text_editor/controller/rich_text_editor_controller.dart';

part 'feedback.dart';
part 'rich_text_tile.dart';
part 'position.dart';
part 'drop_area.dart';
part 'should_ignore_drop.dart';

class RichTextEditor extends HookWidget {
  const RichTextEditor({
    super.key,
    required this.editorState,
    this.focusNode,
    this.scrollController,
    this.expands = true,
    this.scrollPhysics,
    this.padding,
    this.onContentChanged,
  });

  final RichTextEditorState editorState;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final bool expands;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets? padding;
  final Function(String)? onContentChanged;

  @override
  Widget build(BuildContext context) {
    Offset? globalPosition;

    final editorScrollController = EditorScrollController(
      editorState: editorState,
    );
    editorState.transactionStream.listen((event) {
      if (event.$1 == TransactionTime.after) {
        onContentChanged?.call(jsonEncode(event.$2.document.toJson()));
      }
    });
    final blockComponentBuildersForDragging =
        useState(_buildBlockComponentBuilders());

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: AppFlowyEditor(
        focusNode: focusNode,
        editorState: editorState,
        editorScrollController: editorScrollController,
        enableAutoComplete: true,
        shrinkWrap: true,
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
        autoFocus: true,
        dropTargetStyle: const AppFlowyDropTargetStyle(
          color: Colors.red,
        ),
        buildWrapper: (context, child, node, blockComponentContext) {
          final blockComponentContextForFeedback = BlockComponentContext(
            context,
            blockComponentContext.node.copyWith(),
          );
          return _RichTextTile(
            blockComponentContext: blockComponentContext,
            editorState: editorState,
            blockComponentBuilders: blockComponentBuildersForDragging.value,
            onDragStarted: () {
              debugPrint('onDragStarted');
              editorState.selectionService.removeDropTarget();
            },
            onDragUpdate: (details) {
              editorState.selectionService.renderDropTargetForOffset(
                details.globalPosition,
                builder: (context, data) => DropArea(
                  data: data,
                  dragNode: node,
                ),
              );

              globalPosition = details.globalPosition;

              editorState.scrollService
                  ?.startAutoScroll(details.globalPosition);
            },
            onDragEnd: (details) {
              editorState.selectionService.removeDropTarget();

              if (globalPosition == null) {
                return;
              }

              final data = editorState.selectionService.getDropTargetRenderData(
                globalPosition!,
              );

              _moveNodeToNewPosition(
                context,
                editorState,
                blockComponentContext,
                node,
                data?.cursorNode?.path,
                globalPosition!,
              );
            },
            feedback: _Feedback(
              editorState: editorState,
              blockComponentBuilders: blockComponentBuildersForDragging.value,
              blockComponentContext: blockComponentContextForFeedback,
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

  map.forEach((key, value) {
    // 1行ごとのpaddingを設定
    value.configuration = value.configuration.copyWith(
      padding: (_) => const EdgeInsets.symmetric(vertical: 8.0),
    );
  });
  return map;
}

final isMobile = switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS => true,
  _ => false,
};
