part of 'rich_text_editor.dart';

enum HorizontalPosition { left, center, right }

enum VerticalPosition { top, middle, bottom }

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
