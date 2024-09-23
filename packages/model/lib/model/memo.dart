import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:model/systems/timestamp_converter.dart';

part 'memo.freezed.dart';
part 'memo.g.dart';

@freezed
class Memo with _$Memo {
  const factory Memo({
    required String id,
    required String content,
    @TimestampConverter() required DateTime createdAt,
  }) = _Memo;

  factory Memo.fromJson(Map<String, dynamic> json) => _$MemoFromJson(json);

  factory Memo.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    var data = doc.data();
    data['id'] = doc.id;
    return Memo.fromJson(data);
  }
}
