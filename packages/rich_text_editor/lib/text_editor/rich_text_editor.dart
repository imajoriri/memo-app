import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rich_text_editor/text_editor/rich_text_editor_controller.dart';

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
    final blockComponentBuilders = useState(_buildBlockComponentBuilders());
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
        blockComponentBuilders: blockComponentBuilders.value,
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
          return LongPressDraggable(
            data: node,
            feedback: _buildFeedback(
              context,
              blockComponentContext,
              node,
              blockComponentBuilders.value[node.type]!,
            ),
            // childWhenDragging: Container(
            //   color: Colors.blue,
            //   height: 100,
            //   width: 100,
            //   child: const Icon(Icons.directions_run),
            // ),
            onDragStarted: () {
              debugPrint('onDragStarted');
              editorState.selectionService.removeDropTarget();
            },
            onDragUpdate: (details) {
              editorState.selectionService.renderDropTargetForOffset(
                details.globalPosition,
                builder: (context, data) => _buildDropArea(
                  context,
                  data,
                  blockComponentContext.node,
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
                blockComponentContext.node,
                data?.cursorNode?.path,
                globalPosition!,
              );
            },
            child: Container(
              // padding: const EdgeInsets.symmetric(vertical: 2),
              child: Dismissible(
                key: Key('dismissible'),
                onDismissed: (direction) {
                  print('dismissed');
                },
                child: Stack(
                  children: [
                    child,
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () {
                          // editorState.insertPlainText('Hello');
                        },
                        icon: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildFeedback(
    BuildContext context,
    BlockComponentContext blockComponentContext,
    Node node,
    BlockComponentBuilder builder,
  ) {
    Widget child;
    if (node.type == TableBlockKeys.type) {
      // unable to render table block without provider/context
      // render a placeholder instead
      child = Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Table'),
      );
    } else {
      child = IntrinsicWidth(
        child: IntrinsicHeight(
          child: builder.build(blockComponentContext),
          // child: Provider.value(
          //   value: editorState,
          //   child: builder.build(blockComponentContext),
          // ),
        ),
      );
    }

    return Opacity(
      opacity: 0.7,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}

enum HorizontalPosition { left, center, right }

enum VerticalPosition { top, middle, bottom }

Widget _buildDropArea(
  BuildContext context,
  DragAreaBuilderData data,
  Node dragNode,
) {
  final targetNode = data.targetNode;

  final shouldIgnoreDrop = _shouldIgnoreDrop(dragNode, targetNode.path);
  if (shouldIgnoreDrop) {
    return const SizedBox.shrink();
  }

  final selectable = targetNode.selectable;
  final renderBox = selectable?.context.findRenderObject() as RenderBox?;
  if (selectable == null || renderBox == null) {
    return const SizedBox.shrink();
  }

  final position = _getPosition(
    context,
    targetNode,
    data.dragOffset,
  );

  if (position == null) {
    return const SizedBox.shrink();
  }

  final (verticalPosition, horizontalPosition, globalBlockRect) = position;

  // 44 is the width of the drag indicator
  const indicatorWidth = 44.0;
  final width = globalBlockRect.width - indicatorWidth;

  Widget child = Container(
    height: 2,
    width: width,
    color: Colors.blue,
  );

  // if (horizontalPosition == HorizontalPosition.right) {
  //   const breakWidth = 22.0;
  //   const padding = 8.0;
  //   child = Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Container(
  //         height: 2,
  //         width: breakWidth,
  //         color: Colors.red,
  //       ),
  //       const SizedBox(width: padding),
  //       Container(
  //         height: 2,
  //         width: width - breakWidth - padding,
  //         color: Colors.red,
  //       ),
  //     ],
  //   );
  // }

  return Positioned(
    top: verticalPosition == VerticalPosition.top
        ? globalBlockRect.top
        : globalBlockRect.bottom,
    left: globalBlockRect.left + 22,
    child: child,
  );
}

(VerticalPosition, HorizontalPosition, Rect)? _getPosition(
  BuildContext context,
  Node dragTargetNode,
  Offset dragOffset,
) {
  final selectable = dragTargetNode.selectable;
  final renderBox = selectable?.context.findRenderObject() as RenderBox?;
  if (selectable == null || renderBox == null) {
    return null;
  }

  final globalBlockOffset = renderBox.localToGlobal(Offset.zero);
  final globalBlockRect = globalBlockOffset & renderBox.size;

  // Check if the dragOffset is within the globalBlockRect
  final isInside = globalBlockRect.contains(dragOffset);

  if (!isInside) {
    debugPrint(
      'the drag offset is not inside the block, dragOffset($dragOffset), globalBlockRect($globalBlockRect)',
    );
    return null;
  }

  debugPrint(
    'the drag offset is inside the block, dragOffset($dragOffset), globalBlockRect($globalBlockRect)',
  );

  // Determine the relative position
  HorizontalPosition horizontalPosition;
  VerticalPosition verticalPosition;

  // Horizontal position
  if (dragOffset.dx < globalBlockRect.left + 44) {
    horizontalPosition = HorizontalPosition.left;
  } else {
    // ignore the middle here, it's not used in this example
    horizontalPosition = HorizontalPosition.right;
  }

  // Vertical position
  if (dragOffset.dy < globalBlockRect.top + globalBlockRect.height / 2) {
    verticalPosition = VerticalPosition.top;
  } else {
    verticalPosition = VerticalPosition.bottom;
  }

  return (verticalPosition, horizontalPosition, globalBlockRect);
}

bool _shouldIgnoreDrop(Node dragNode, Path? targetPath) {
  if (targetPath == null) {
    return true;
  }

  if (dragNode.path.equals(targetPath)) {
    return true;
  }

  if (dragNode.path.isAncestorOf(targetPath)) {
    return true;
  }

  return false;
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
