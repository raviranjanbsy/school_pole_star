import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/providers/auth_provider.dart';
import 'package:school_management/services/auth_service.dart';

@riverpod
Stream<List<StreamItem>> homePageStream(HomePageStreamRef ref, String classId) {
  final authService = ref.watch(authServiceProvider);
  // The getStreamForClass method already returns a combined list of
  // announcements and assignments, sorted by the newest timestamp first.
  return authService.getStreamForClass(classId);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homePageStreamHash() => r'8c3a72a537f26415779069354460c5717616654e';

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

/// See also [homePageStream].
@ProviderFor(homePageStream)
const homePageStreamProvider = HomePageStreamFamily();

/// See also [homePageStream].
class HomePageStreamFamily extends Family<AsyncValue<List<StreamItem>>> {
  /// See also [homePageStream].
  const HomePageStreamFamily();

  /// See also [homePageStream].
  HomePageStreamProvider call(
    String classId,
  ) {
    return HomePageStreamProvider(
      classId,
    );
  }

  @override
  HomePageStreamProvider getProviderOverride(
    covariant HomePageStreamProvider provider,
  ) {
    return call(
      provider.classId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'homePageStreamProvider';
}

/// See also [homePageStream].
class HomePageStreamProvider
    extends AutoDisposeStreamProvider<List<StreamItem>> {
  /// See also [homePageStream].
  HomePageStreamProvider(
    String classId,
  ) : this._internal(
          (ref) => homePageStream(
            ref as HomePageStreamRef,
            classId,
          ),
          from: homePageStreamProvider,
          name: r'homePageStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$homePageStreamHash,
          dependencies: HomePageStreamFamily._dependencies,
          allTransitiveDependencies:
              HomePageStreamFamily._allTransitiveDependencies,
          classId: classId,
        );

  HomePageStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  Override overrideWith(
    Stream<List<StreamItem>> Function(HomePageStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomePageStreamProvider._internal(
        (ref) => create(ref as HomePageStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<StreamItem>> createElement() {
    return _HomePageStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomePageStreamProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin HomePageStreamRef on AutoDisposeStreamProviderRef<List<StreamItem>> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _HomePageStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<StreamItem>>
    with HomePageStreamRef {
  _HomePageStreamProviderElement(super.provider);

  @override
  String get classId => (origin as HomePageStreamProvider).classId;
}
