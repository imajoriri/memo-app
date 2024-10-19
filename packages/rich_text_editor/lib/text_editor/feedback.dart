part of 'rich_text_editor.dart';

const _feedbackAnimationDuration = Duration(milliseconds: 200);

class _Feedback extends StatefulWidget {
  const _Feedback({
    required this.editorState,
    required this.blockComponentBuilders,
    required this.blockComponentContext,
    required this.padding,
  });

  final RichTextEditorState editorState;
  final Map<String, BlockComponentBuilder> blockComponentBuilders;
  final BlockComponentContext blockComponentContext;
  final EdgeInsets padding;
  @override
  State<_Feedback> createState() => _FeedbackState();
}

class _FeedbackState extends State<_Feedback>
    with SingleTickerProviderStateMixin {
  late final animationController;
  late final shadowAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: _feedbackAnimationDuration,
      vsync: this,
    );
    shadowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 画面幅より40px小さい
    final width = MediaQuery.of(context).size.width - 40;
    return Opacity(
      opacity: 0.7,
      child: Material(
        child: AnimatedBuilder(
          animation: shadowAnimation,
          builder: (context, child) {
            return Container(
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    offset: const Offset(0, 0),
                    blurRadius: 20.0 * shadowAnimation.value,
                  ),
                ],
              ),
              padding: widget.padding,
              child: child,
            );
          },
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: Provider.value(
                value: widget.editorState as EditorState,
                child: widget.blockComponentBuilders[
                        widget.blockComponentContext.node.type]!
                    .build(widget.blockComponentContext),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
