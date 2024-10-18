part of 'rich_text_editor.dart';

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.editorState,
    required this.blockComponentBuilders,
    required this.blockComponentContext,
  });

  final RichTextEditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilders;
  final BlockComponentContext blockComponentContext;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Material(
        color: Colors.transparent,
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Provider.value(
              value: editorState as EditorState,
              child: blockComponentBuilders[blockComponentContext.node.type]!
                  .build(blockComponentContext),
            ),
          ),
        ),
      ),
    );
  }
}
