part of 'rich_text_editor.dart';

class _RichTextTile extends StatefulWidget {
  const _RichTextTile({
    required this.child,
    required this.feedback,
    required this.blockComponentContext,
    required this.editorState,
    required this.blockComponentBuilders,
    required this.padding,
    required this.hasFocus,
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
  final bool hasFocus;

  @override
  State<_RichTextTile> createState() => _RichTextTileState();
}

class _RichTextTileState extends State<_RichTextTile> {
  bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
  @override
  Widget build(BuildContext context) {
    Widget result = Padding(
      padding: widget.padding,
      child: Stack(
        children: [
          widget.child,
          // Positioned(
          //   top: 0,
          //   right: 0,
          //   child: IconButton(
          //     onPressed: () {
          //       // editorState.insertPlainText('Hello');
          //     },
          //     icon: Icon(Icons.add),
          //   ),
          // ),
        ],
      ),
    );

    // ページブロック以外はドラッグで削除できる
    // if (widget.blockComponentContext.node.type != PageBlockKeys.type &&
    //     isMobile) {
    //   result = Dismissible(
    //     key: Key(widget.blockComponentContext.node.id),
    //     onDismissed: (direction) {},
    //     child: result,
    //   );
    // }

    if (!widget.hasFocus &&
        widget.blockComponentContext.node.type != PageBlockKeys.type) {
      result = LongPressDraggable<Node>(
        data: widget.blockComponentContext.node,
        onDragStarted: widget.onDragStarted,
        onDragUpdate: widget.onDragUpdate,
        onDragEnd: widget.onDragEnd,
        feedback: widget.feedback,
        child: result,
      );
    }

    return result;
  }
}
