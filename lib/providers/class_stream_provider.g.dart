// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$announcementsHash() => r'b723ff571a31adfd4d208d37d7155458893c2260';

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

/// See also [announcements].
@ProviderFor(announcements)
const announcementsProvider = AnnouncementsFamily();

/// See also [announcements].
class AnnouncementsFamily extends Family<AsyncValue<List<StreamItem>>> {
  /// See also [announcements].
  const AnnouncementsFamily();

  /// See also [announcements].
  AnnouncementsProvider call(
    String classId,
  ) {
    return AnnouncementsProvider(
      classId,
    );
  }

  @override
  AnnouncementsProvider getProviderOverride(
    covariant AnnouncementsProvider provider,
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
  String? get name => r'announcementsProvider';
}

/// See also [announcements].
class AnnouncementsProvider
    extends AutoDisposeStreamProvider<List<StreamItem>> {
  /// See also [announcements].
  AnnouncementsProvider(
    String classId,
  ) : this._internal(
          (ref) => announcements(
            ref as AnnouncementsRef,
            classId,
          ),
          from: announcementsProvider,
          name: r'announcementsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$announcementsHash,
          dependencies: AnnouncementsFamily._dependencies,
          allTransitiveDependencies:
              AnnouncementsFamily._allTransitiveDependencies,
          classId: classId,
        );

  AnnouncementsProvider._internal(
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
    Stream<List<StreamItem>> Function(AnnouncementsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnnouncementsProvider._internal(
        (ref) => create(ref as AnnouncementsRef),
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
    return _AnnouncementsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnnouncementsProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnnouncementsRef on AutoDisposeStreamProviderRef<List<StreamItem>> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _AnnouncementsProviderElement
    extends AutoDisposeStreamProviderElement<List<StreamItem>>
    with AnnouncementsRef {
  _AnnouncementsProviderElement(super.provider);

  @override
  String get classId => (origin as AnnouncementsProvider).classId;
}

String _$assignmentsHash() => r'f02454a757581a4df6681826010ec34127e1e5f0';

/// See also [assignments].
@ProviderFor(assignments)
const assignmentsProvider = AssignmentsFamily();

/// See also [assignments].
class AssignmentsFamily extends Family<AsyncValue<List<StreamItem>>> {
  /// See also [assignments].
  const AssignmentsFamily();

  /// See also [assignments].
  AssignmentsProvider call(
    String classId,
  ) {
    return AssignmentsProvider(
      classId,
    );
  }

  @override
  AssignmentsProvider getProviderOverride(
    covariant AssignmentsProvider provider,
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
  String? get name => r'assignmentsProvider';
}

/// See also [assignments].
class AssignmentsProvider extends AutoDisposeStreamProvider<List<StreamItem>> {
  /// See also [assignments].
  AssignmentsProvider(
    String classId,
  ) : this._internal(
          (ref) => assignments(
            ref as AssignmentsRef,
            classId,
          ),
          from: assignmentsProvider,
          name: r'assignmentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$assignmentsHash,
          dependencies: AssignmentsFamily._dependencies,
          allTransitiveDependencies:
              AssignmentsFamily._allTransitiveDependencies,
          classId: classId,
        );

  AssignmentsProvider._internal(
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
    Stream<List<StreamItem>> Function(AssignmentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AssignmentsProvider._internal(
        (ref) => create(ref as AssignmentsRef),
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
    return _AssignmentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AssignmentsProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AssignmentsRef on AutoDisposeStreamProviderRef<List<StreamItem>> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _AssignmentsProviderElement
    extends AutoDisposeStreamProviderElement<List<StreamItem>>
    with AssignmentsRef {
  _AssignmentsProviderElement(super.provider);

  @override
  String get classId => (origin as AssignmentsProvider).classId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
