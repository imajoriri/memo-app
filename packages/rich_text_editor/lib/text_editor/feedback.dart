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
    // 画面幅より40px小さい
    final width = MediaQuery.of(context).size.width - 20;
    return Opacity(
      opacity: 0.7,
      child: Material(
        child: Container(
          width: width,
          // shadow
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                offset: const Offset(0, 0),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
      ),
    );
  }
}
