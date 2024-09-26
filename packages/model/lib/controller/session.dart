import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'session.g.dart';

/// セッションを管理するコントローラー。
@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  String build() {
    return const Uuid().v4();
  }
}
