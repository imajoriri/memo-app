import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:model/model/memo.dart';
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

  /// 最新のメモを1件取得するStream。
  ///
  /// 1件もない場合は、nullを返す。
  Stream<Memo?> latest(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection("memos")
        .orderBy("createdAt", descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return Memo.fromDocument(snapshot.docs.first);
    });
  }

  /// 最新のメモを1件取得する。
  ///
  /// 1件もない場合は、nullを返す。
  Future<Memo?> fetchLatest(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection("memos")
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return Memo.fromDocument(snapshot.docs.first);
  }

  Future<void> addMemo({
    required String userId,
    required Memo memo,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection("memos")
        .doc(memo.id)
        .set(memo.toJson());
  }

  Future<void> updateMemo({
    required String userId,
    required Memo memo,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection("memos")
        .doc(memo.id)
        .set(memo.toJson());
  }
}
