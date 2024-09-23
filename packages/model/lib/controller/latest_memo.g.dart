// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latest_memo.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$latestMemoHash() => r'de25c7147e9981d652ac4151163db748486df8c9';

/// 最新のメモを取得する。
///
/// 1件もない場合は、作成して返す。
///
/// Copied from [LatestMemo].
@ProviderFor(LatestMemo)
final latestMemoProvider =
    AutoDisposeStreamNotifierProvider<LatestMemo, Memo?>.internal(
  LatestMemo.new,
  name: r'latestMemoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$latestMemoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LatestMemo = AutoDisposeStreamNotifier<Memo?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, inference_failure_on_uninitialized_variable, inference_failure_on_function_return_type, inference_failure_on_untyped_parameter, deprecated_member_use_from_same_package
