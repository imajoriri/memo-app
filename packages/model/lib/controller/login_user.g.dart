// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_user.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$loginUserHash() => r'2bfc769e423b4edde7acfb965609dbabcdcc2e2b';

/// ログインしているユーザーを取得する
///
/// Firebase authentication の匿名ログインを行い、ログインしているユーザーを取得します。
/// ログインしていない場合は匿名ログインを行います。
///
/// Copied from [LoginUser].
@ProviderFor(LoginUser)
final loginUserProvider = AsyncNotifierProvider<LoginUser, User>.internal(
  LoginUser.new,
  name: r'loginUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$loginUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LoginUser = AsyncNotifier<User>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, inference_failure_on_uninitialized_variable, inference_failure_on_function_return_type, inference_failure_on_untyped_parameter, deprecated_member_use_from_same_package
