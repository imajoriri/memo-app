import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_repository.g.dart';

@riverpod
MemoRepository memoRepository(MemoRepositoryRef ref) =>
    MemoRepository(ref: ref);

class MemoRepository {
  MemoRepository({
    required this.ref,
  });
  final Ref ref;

  Future<String> fetchMemo() async {
    final result =
        await FirebaseFirestore.instance.collection('users').doc("test").get();
    if (result.exists) {
      final data = result.data() as Map<String, dynamic>;
      final content = data["content"] as String?;
      return content ?? '';
    }
    return '';
  }

  Stream<
      ({
        String content,
        bool isLocalChange,
      })> stream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc("test")
        .snapshots()
        .map((event) {
      final content = event.data()?['content'] as String?;
      return (
        content: content ?? '',
        isLocalChange: event.metadata.hasPendingWrites,
      );
    });
  }

  Future<String> fetch() async {
    final result =
        await FirebaseFirestore.instance.collection('users').doc("test").get();
    if (result.exists) {
      final data = result.data() as Map<String, dynamic>;
      final content = data["content"] as String?;
      return content ?? '';
    }
    return '';
  }

  Future<void> updateMemo(String content) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc("test")
        .set({'content': content});
  }
}
