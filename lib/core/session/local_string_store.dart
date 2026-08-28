import 'dart:collection';

/// Primitive-only storage boundary shared by local platform services.
abstract interface class LocalStringStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);

  Future<void> clearOwned(Set<String> allowList);
}

/// Ephemeral injectable backend for tests and storage-unavailable fallback.
final class MemoryLocalStringStore implements LocalStringStore {
  MemoryLocalStringStore([Map<String, String>? initialValues])
    : _values = <String, String>{...?initialValues};

  final Map<String, String> _values;

  Map<String, String> get values => Map<String, String>.unmodifiable(_values);

  @override
  Future<void> clearOwned(Set<String> allowList) async {
    for (final key in allowList) {
      _values.remove(key);
    }
  }

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}

final class AllowlistedLocalStringStore implements LocalStringStore {
  AllowlistedLocalStringStore({
    required this.delegate,
    required Set<String> allowedKeys,
  }) : allowedKeys = UnmodifiableSetView<String>(Set<String>.of(allowedKeys));

  final LocalStringStore delegate;
  final Set<String> allowedKeys;

  void _validateKey(String key) {
    if (!allowedKeys.contains(key)) {
      throw ArgumentError.value(key, 'key', 'Key is not owned by Pocketools.');
    }
  }

  @override
  Future<void> clearOwned(Set<String> allowList) {
    for (final key in allowList) {
      _validateKey(key);
    }
    return delegate.clearOwned(Set<String>.unmodifiable(allowList));
  }

  @override
  Future<String?> readString(String key) {
    _validateKey(key);
    return delegate.readString(key);
  }

  @override
  Future<void> remove(String key) {
    _validateKey(key);
    return delegate.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) {
    _validateKey(key);
    return delegate.writeString(key, value);
  }
}
