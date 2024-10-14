// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_future_builder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$urlPreviewControllerHash() =>
    r'93a57907339cad6f87d9f7562857aa7a32d33a41';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$UrlPreviewController
    extends BuildlessAsyncNotifier<UrlPreview> {
  late final String url;

  FutureOr<UrlPreview> build({
    required String url,
  });
}

/// OGP情報を取得するコントローラー。
///
/// 表示のたびにAPIを叩くのは非効率なので、keepAliveをtrueにしている。
///
/// Copied from [UrlPreviewController].
@ProviderFor(UrlPreviewController)
const urlPreviewControllerProvider = UrlPreviewControllerFamily();

/// OGP情報を取得するコントローラー。
///
/// 表示のたびにAPIを叩くのは非効率なので、keepAliveをtrueにしている。
///
/// Copied from [UrlPreviewController].
class UrlPreviewControllerFamily extends Family {
  /// OGP情報を取得するコントローラー。
  ///
  /// 表示のたびにAPIを叩くのは非効率なので、keepAliveをtrueにしている。
  ///
  /// Copied from [UrlPreviewController].
  const UrlPreviewControllerFamily();

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'urlPreviewControllerProvider';

  /// OGP情報を取得するコントローラー。
  ///
  /// 表示のたびにAPIを叩くのは非効率なので、keepAliveをtrueにしている。
  ///
  /// Copied from [UrlPreviewController].
  UrlPreviewControllerProvider call({
    required String url,
  }) {
    return UrlPreviewControllerProvider(
      url: url,
    );
  }

  @visibleForOverriding
  @override
  UrlPreviewControllerProvider getProviderOverride(
    covariant UrlPreviewControllerProvider provider,
  ) {
    return call(
      url: provider.url,
    );
  }

  /// Enables overriding the behavior of this provider, no matter the parameters.
  Override overrideWith(UrlPreviewController Function() create) {
    return _$UrlPreviewControllerFamilyOverride(this, create);
  }
}

class _$UrlPreviewControllerFamilyOverride implements FamilyOverride {
  _$UrlPreviewControllerFamilyOverride(this.overriddenFamily, this.create);

  final UrlPreviewController Function() create;

  @override
  final UrlPreviewControllerFamily overriddenFamily;

  @override
  UrlPreviewControllerProvider getProviderOverride(
    covariant UrlPreviewControllerProvider provider,
  ) {
    return provider._copyWith(create);
  }
}

/// OGP情報を取得するコントローラー。
///
/// 表示のたびにAPIを叩くのは非効率なので、keepAliveをtrueにしている。
///
/// Copied from [UrlPreviewController].
class UrlPreviewControllerProvider
    extends AsyncNotifierProviderImpl<UrlPreviewController, UrlPreview> {
  /// OGP情報を取得するコントローラー。
  ///
  /// 表示のたびにAPIを叩くのは非効率なので、keepAliveをtrueにしている。
  ///
  /// Copied from [UrlPreviewController].
  UrlPreviewControllerProvider({
    required String url,
  }) : this._internal(
          () => UrlPreviewController()..url = url,
          from: urlPreviewControllerProvider,
          name: r'urlPreviewControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$urlPreviewControllerHash,
          dependencies: UrlPreviewControllerFamily._dependencies,
          allTransitiveDependencies:
              UrlPreviewControllerFamily._allTransitiveDependencies,
          url: url,
        );

  UrlPreviewControllerProvider._internal(
    super.create, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.url,
  }) : super.internal();

  final String url;

  @override
  FutureOr<UrlPreview> runNotifierBuild(
    covariant UrlPreviewController notifier,
  ) {
    return notifier.build(
      url: url,
    );
  }

  @override
  Override overrideWith(UrlPreviewController Function() create) {
    return ProviderOverride(
      origin: this,
      override: UrlPreviewControllerProvider._internal(
        () => create()..url = url,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        url: url,
      ),
    );
  }

  @override
  ({
    String url,
  }) get argument {
    return (url: url,);
  }

  @override
  AsyncNotifierProviderElement<UrlPreviewController, UrlPreview>
      createElement() {
    return _UrlPreviewControllerProviderElement(this);
  }

  UrlPreviewControllerProvider _copyWith(
    UrlPreviewController Function() create,
  ) {
    return UrlPreviewControllerProvider._internal(
      () => create()..url = url,
      name: name,
      dependencies: dependencies,
      allTransitiveDependencies: allTransitiveDependencies,
      debugGetCreateSourceHash: debugGetCreateSourceHash,
      from: from,
      url: url,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UrlPreviewControllerProvider && other.url == url;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UrlPreviewControllerRef on AsyncNotifierProviderRef<UrlPreview> {
  /// The parameter `url` of this provider.
  String get url;
}

class _UrlPreviewControllerProviderElement
    extends AsyncNotifierProviderElement<UrlPreviewController, UrlPreview>
    with UrlPreviewControllerRef {
  _UrlPreviewControllerProviderElement(super.provider);

  @override
  String get url => (origin as UrlPreviewControllerProvider).url;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, inference_failure_on_uninitialized_variable, inference_failure_on_function_return_type, inference_failure_on_untyped_parameter, deprecated_member_use_from_same_package
