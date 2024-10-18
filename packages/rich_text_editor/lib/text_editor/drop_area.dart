part of 'rich_text_editor.dart';

class DropArea extends StatelessWidget {
  const DropArea({
    super.key,
    required this.data,
    required this.dragNode,
  });

  final DragAreaBuilderData data;
  final Node dragNode;

  @override
  Widget build(BuildContext context) {
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
}
