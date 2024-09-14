import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:model/repository/memo_repository.dart';

part 'global_memo.g.dart';

/// Controller。
@riverpod
class GlobalMemo extends _$GlobalMemo {
  @override
  Stream<String> build() {
    return ref
        .watch(memoRepositoryProvider)
        .stream()
        .map((event) => event.content);
  }

  Future<void> updateMemo(String content) async {
    await ref.read(memoRepositoryProvider).updateMemo(content);
  }

  Future<void> addToBottom(String content) async {
    final current = await ref.read(memoRepositoryProvider).fetch();
    await ref.read(memoRepositoryProvider).updateMemo('$current\n$content');
  }
}
