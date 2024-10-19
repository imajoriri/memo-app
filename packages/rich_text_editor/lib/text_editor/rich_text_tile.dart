part of 'rich_text_editor.dart';

class _RichTextTile extends StatelessWidget {
  const _RichTextTile({
    super.key,
    required this.child,
    required this.feedback,
    required this.blockComponentContext,
    required this.editorState,
    required this.blockComponentBuilders,
    required this.padding,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
  });

  final Widget child;
  final Widget feedback;
  final BlockComponentContext blockComponentContext;
  final RichTextEditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilders;

  final void Function()? onDragStarted;
  final void Function(DragUpdateDetails)? onDragUpdate;
  final void Function(DraggableDetails)? onDragEnd;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tile = Dismissible(
      key: Key(blockComponentContext.node.id),
      onDismissed: (direction) {
        print('dismissed');
      },
      child: Padding(
        padding: padding,
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
    );

    return LongPressDraggable<Node>(
      data: blockComponentContext.node,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      feedback: feedback,
      child: tile,
    );
  }
}
