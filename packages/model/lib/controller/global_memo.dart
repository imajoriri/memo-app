import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:model/repository/memo_repository.dart';

part 'global_memo.g.dart';

/// Controller。
@riverpod
class GlobalMemo extends _$GlobalMemo {
  StreamSubscription? _streamSub;

  @override
  Stream<String> build() {
    _listen();
    ref.onDispose(() {
      _streamSub?.cancel();
    });
    return const Stream.empty();
  }

  _listen() {
    _streamSub = ref.watch(memoRepositoryProvider).stream().listen((event) {
      if (!event.isLocalChange) {
        state = AsyncValue.data(event.content);
      }
    });
  }

  Future<void> updateMemo(String content) async {
    await ref.read(memoRepositoryProvider).updateMemo(content);
  }
}
