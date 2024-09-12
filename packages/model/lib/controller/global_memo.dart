import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:model/repository/memo_repository.dart';

part 'global_memo.g.dart';

/// グローバルなメモを管理するController。
@riverpod
class GlobalMemo extends _$GlobalMemo {
  @override
  FutureOr<String> build() async {
    final memo = await ref.read(memoRepositoryProvider).fetchMemo();
    return memo;
  }

  Future<void> updateMemo(String content) async {
    await ref.read(memoRepositoryProvider).updateMemo(content);
  }
}
