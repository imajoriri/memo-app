import 'package:model/controller/login_user.dart';
import 'package:model/controller/session.dart';
import 'package:model/model/memo.dart';
import 'package:model/repository/memo_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'latest_memo.g.dart';

/// 最新のメモを取得する。
///
/// 1件もない場合は、作成して返す。
@riverpod
class LatestMemo extends _$LatestMemo {
  @override
  Stream<Memo?> build() {
    final userId = ref.watch(loginUserProvider).valueOrNull?.id;
    if (userId == null) {
      return const Stream.empty();
    }

    final repository = ref.watch(memoRepositoryProvider);

    return repository.latest(userId).map((memo) {
      if (memo == null) {
        // TODO: memoがnullの時なぜか2回作成されている。
        repository.addMemo(
          memo: Memo(
            id: const Uuid().v4(),
            content: '',
            session: ref.read(sessionProvider),
            createdAt: DateTime.now(),
          ),
          userId: userId,
        );
      }
      return memo;
    });
  }

  /// メモの末尾に新しいメモを追加する。
  Future<void> addToBottom(String content) async {
    final userId = ref.watch(loginUserProvider).valueOrNull?.id;
    if (userId == null) {
      return;
    }
    final memo = await ref.read(memoRepositoryProvider).fetchLatest(userId);
    await ref.read(memoRepositoryProvider).updateMemo(
          memo: memo!.copyWith(content: "${memo.content}\n$content"),
          userId: userId,
        );
  }

  /// メモを更新する。
  Future<void> updateMemo(String content) async {
    final userId = ref.watch(loginUserProvider).valueOrNull?.id;
    if (userId == null) {
      return;
    }

    final memo = state.valueOrNull;
    if (memo == null) {
      return;
    }

    // 現在のcontentと一致する場合は何もしない。
    if (memo.content == content) {
      return;
    }

    await ref.read(memoRepositoryProvider).updateMemo(
          memo: memo.copyWith(
            content: content,
            session: ref.read(sessionProvider),
          ),
          userId: userId,
        );
  }

  /// 新しいメモを作成する。
  Future<void> createMemo() async {
    final userId = ref.watch(loginUserProvider).valueOrNull?.id;
    if (userId == null) {
      return;
    }

    await ref.read(memoRepositoryProvider).addMemo(
          memo: Memo(
            id: const Uuid().v4(),
            content: '',
            session: ref.read(sessionProvider),
            createdAt: DateTime.now(),
          ),
          userId: userId,
        );
  }
}
