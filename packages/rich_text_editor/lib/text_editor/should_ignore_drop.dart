part of 'rich_text_editor.dart';

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
