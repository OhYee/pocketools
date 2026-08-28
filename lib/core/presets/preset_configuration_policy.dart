import 'dart:collection';

import 'preset_capabilities.dart';

/// Validates the untrusted, provider-owned part of a tool preset.
///
/// Preset configuration is deliberately narrower than the values accepted by
/// session payloads: only JSON-compatible maps and lists are allowed, and
/// field names may not identify private or session-owned data.
final class ToolPresetConfigurationPolicy {
  const ToolPresetConfigurationPolicy._();

  static const int maximumDepth = 8;
  static const int maximumNodes = 256;
  static const int maximumStringLength = 4096;

  static const Set<String> _sensitiveWords = <String>{
    'private',
    'prompt',
    'question',
    'intention',
    'note',
    'result',
    'outcome',
    'session',
    'parent',
    'device',
    'analytics',
    'telemetry',
    'identifier',
    'id',
    'uuid',
    'seed',
    'timestamp',
    'history',
  };

  static const List<List<String>> _sensitiveTokenSequences = <List<String>>[
    <String>['created', 'at'],
    <String>['updated', 'at'],
  ];

  static const Set<String> _compactOnlyWords = <String>{'text', 'value'};
  static final Set<String> _compactTokenWords = <String>{
    ..._sensitiveWords,
    ..._compactOnlyWords,
  };

  static const Set<String> _sensitiveCjkWords = <String>{
    '私密',
    '私人',
    '私有',
    '提示词',
    '提示',
    '问题',
    '意图',
    '备注',
    '笔记',
    '注释',
    '结果',
    '结局',
    '会话',
    '对话',
    '父级',
    '设备',
    '分析',
    '埋点',
    '遥测',
    '标识符',
    '标识',
    '编号',
    '唯一标识',
    '种子',
    '时间戳',
    '历史',
  };

  static const Set<String> _sensitiveCjkKeys = <String>{
    '父会话标识',
    '私密备注',
    '会话标识',
    '创建时间',
    '更新时间',
    '随机种子',
  };

  /// Validates and returns an independent, deeply immutable copy.
  static Map<String, Object?> validateAndCopy(
    Map<String, Object?> configuration,
  ) => _Validator().validate(configuration);

  /// Alias intended for callers that only need to validate a configuration.
  static Map<String, Object?> validate(Map<String, Object?> configuration) =>
      validateAndCopy(configuration);

  static bool _hasSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    if (_sensitiveCjkKeys.contains(normalized)) return true;
    final asciiTokens = _asciiTokens(key).toList(growable: false);
    if (asciiTokens.any(_sensitiveWords.contains)) return true;
    if (_cjkTokens(key).any(_sensitiveCjkWords.contains)) return true;
    if (_sensitiveTokenSequences.any(
      (sequence) => _containsTokenSequence(asciiTokens, sequence),
    )) {
      return true;
    }
    final compactKey = _asciiCompactKey(key);
    if (compactKey == null) return false;
    if (_sensitiveTokenSequences.any(
      (sequence) => compactKey == sequence.join(),
    )) {
      return true;
    }
    return _containsSensitiveCompactSequence(compactKey);
  }

  static String? _asciiCompactKey(String key) {
    final compact = StringBuffer();
    for (final codePoint in key.runes) {
      if (!_isAsciiAlphaNumeric(codePoint)) return null;
      compact.writeCharCode(_toAsciiLower(codePoint));
    }
    return compact.toString();
  }

  static bool _containsSensitiveCompactSequence(String compactKey) {
    final canTokenize = List<bool>.filled(compactKey.length + 1, false);
    final canTokenizeSensitive = List<bool>.filled(
      compactKey.length + 1,
      false,
    );
    canTokenize[compactKey.length] = true;
    for (var offset = compactKey.length - 1; offset >= 0; offset--) {
      for (final token in _compactTokenWords) {
        if (!compactKey.startsWith(token, offset)) continue;
        final nextOffset = offset + token.length;
        if (!canTokenize[nextOffset]) continue;
        canTokenize[offset] = true;
        canTokenizeSensitive[offset] =
            _sensitiveWords.contains(token) || canTokenizeSensitive[nextOffset];
        if (canTokenizeSensitive[offset]) break;
      }
    }
    return canTokenizeSensitive.first;
  }

  static bool _containsTokenSequence(
    List<String> tokens,
    List<String> sequence,
  ) {
    if (tokens.length < sequence.length) return false;
    for (var start = 0; start <= tokens.length - sequence.length; start++) {
      var matches = true;
      for (var offset = 0; offset < sequence.length; offset++) {
        if (tokens[start + offset] != sequence[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  static Iterable<String> _asciiTokens(String key) sync* {
    final tokens = <String>[];
    final buffer = StringBuffer();
    final codePoints = key.runes.toList(growable: false);

    void flush() {
      if (buffer.length > 0) {
        tokens.add(buffer.toString());
        buffer.clear();
      }
    }

    for (var index = 0; index < codePoints.length; index++) {
      final codePoint = codePoints[index];
      if (!_isAsciiAlphaNumeric(codePoint)) {
        flush();
        continue;
      }
      final previous = index == 0 ? null : codePoints[index - 1];
      final next = index + 1 == codePoints.length
          ? null
          : codePoints[index + 1];
      if (_isAsciiUpper(codePoint) &&
          buffer.length > 0 &&
          ((_isAsciiLower(previous) || _isAsciiDigit(previous)) ||
              (_isAsciiUpper(previous) && _isAsciiLower(next)))) {
        flush();
      }
      buffer.writeCharCode(_toAsciiLower(codePoint));
    }
    flush();
    yield* tokens;
  }

  static Iterable<String> _cjkTokens(String key) sync* {
    final tokens = <String>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.length > 0) {
        tokens.add(buffer.toString());
        buffer.clear();
      }
    }

    for (final codePoint in key.runes) {
      if (_isCjk(codePoint)) {
        buffer.writeCharCode(codePoint);
      } else {
        flush();
      }
    }
    flush();
    yield* tokens;
  }

  static bool _isCjk(int codePoint) =>
      (codePoint >= 0x3400 && codePoint <= 0x4dbf) ||
      (codePoint >= 0x4e00 && codePoint <= 0x9fff) ||
      (codePoint >= 0xf900 && codePoint <= 0xfaff);

  static bool _isAsciiAlphaNumeric(int? codePoint) =>
      _isAsciiLower(codePoint) ||
      _isAsciiUpper(codePoint) ||
      _isAsciiDigit(codePoint);

  static bool _isAsciiLower(int? codePoint) =>
      codePoint != null && codePoint >= 0x61 && codePoint <= 0x7a;

  static bool _isAsciiUpper(int? codePoint) =>
      codePoint != null && codePoint >= 0x41 && codePoint <= 0x5a;

  static bool _isAsciiDigit(int? codePoint) =>
      codePoint != null && codePoint >= 0x30 && codePoint <= 0x39;

  static int _toAsciiLower(int codePoint) =>
      _isAsciiUpper(codePoint) ? codePoint + 0x20 : codePoint;
}

/// Shared boundary for future provider encode implementations.
Map<String, Object?> validatedToolPresetConfiguration(
  Map<String, Object?> configuration,
) => ToolPresetConfigurationPolicy.validateAndCopy(configuration);

final class _Validator {
  _Validator() : _activeCollections = HashSet<Object>.identity();

  final Set<Object> _activeCollections;
  var _nodes = 0;

  Map<String, Object?> validate(Map<String, Object?> configuration) =>
      _visitMap(configuration, path: 'configuration', depth: 0);

  Map<String, Object?> _visitMap(
    Map value, {
    required String path,
    required int depth,
  }) => _withCollection(value, path, () {
    _checkDepth(path, depth);
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        _fail(path, 'map keys must be strings');
      }
      final key = entry.key as String;
      _checkString(key, '$path.$key');
      if (ToolPresetConfigurationPolicy._hasSensitiveKey(key)) {
        _fail('$path.$key', 'field name is reserved');
      }
      result[key] = _visit(entry.value, path: '$path.$key', depth: depth + 1);
    }
    return Map<String, Object?>.unmodifiable(result);
  });

  Object? _visit(Object? value, {required String path, required int depth}) {
    _countNode(path);
    if (value == null || value is bool || value is int) return value;
    if (value is double) {
      if (!value.isFinite) _fail(path, 'numbers must be finite');
      return value;
    }
    if (value is String) {
      _checkString(value, path);
      return value;
    }
    if (value is Map) return _visitMap(value, path: path, depth: depth);
    if (value is List) {
      return _withCollection(value, path, () {
        _checkDepth(path, depth);
        return List<Object?>.unmodifiable(
          value.indexed
              .map(
                (entry) => _visit(
                  entry.$2,
                  path: '$path[${entry.$1}]',
                  depth: depth + 1,
                ),
              )
              .toList(growable: false),
        );
      });
    }
    _fail(path, 'value is not JSON-compatible');
  }

  void _countNode(String path) {
    _nodes++;
    if (_nodes > ToolPresetConfigurationPolicy.maximumNodes) {
      _fail(path, 'node limit exceeded');
    }
  }

  void _checkDepth(String path, int depth) {
    if (depth > ToolPresetConfigurationPolicy.maximumDepth) {
      _fail(path, 'nesting depth limit exceeded');
    }
  }

  void _checkString(String value, String path) {
    if (value.runes.length >
        ToolPresetConfigurationPolicy.maximumStringLength) {
      _fail(path, 'string length limit exceeded');
    }
    if (RegExp(r'[\u0000-\u001f\u007f-\u009f]').hasMatch(value)) {
      _fail(path, 'control characters are not allowed');
    }
  }

  T _withCollection<T>(Object collection, String path, T Function() build) {
    if (!_activeCollections.add(collection)) {
      _fail(path, 'cyclic collections are not allowed');
    }
    try {
      return build();
    } finally {
      _activeCollections.remove(collection);
    }
  }

  Never _fail(String path, String reason) {
    throw PresetConfigurationException(
      'Invalid preset configuration at $path: $reason.',
    );
  }
}
