import '../session/session.dart';
import 'tool_session_adapter.dart';

final class ToolLaunchRequest {
  const ToolLaunchRequest({
    required this.toolId,
    this.initialConfig,
    this.parentSessionId,
  });

  final String toolId;
  final Object? initialConfig;
  final String? parentSessionId;
}

/// Optional transformation for privacy-sensitive configuration replay.
abstract interface class ToolReplayCapability {
  Object replayInput(SessionRecord session, DecodedToolSession decoded);
}

final class ToolOptionalShareField {
  const ToolOptionalShareField({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final String value;
}

/// Privacy-sensitive field categories reviewed for explicit sharing in v0.1.
///
/// Adding a category is a public security-policy change and requires shared
/// policy tests. Modules without optional private data do not use this type.
enum ToolOptionalShareFieldKind { question, intention }

/// Fail-closed validation for module-declared optional share fields.
final class ToolOptionalShareFieldPolicy {
  const ToolOptionalShareFieldPolicy._();

  static const int maxIdLength = 32;
  static const int maxLabelLength = 64;
  static const int maxValueLength = 2000;

  static final RegExp _controlCharacters = RegExp(
    r'[\u0000-\u001f\u007f-\u009f]',
  );
  static final RegExp _camelCaseBoundary = RegExp(r'([a-z0-9])([A-Z])');
  static final RegExp _nonAsciiWord = RegExp(r'[^a-z0-9]+');
  static final RegExp _nonAsciiAlphaNumeric = RegExp(r'[^a-z0-9]');

  static const Set<String> _identifierWords = <String>{
    'session',
    'parent',
    'device',
    'identifier',
    'identity',
    'id',
    'uuid',
    'guid',
    'imei',
    'serial',
    'fingerprint',
  };

  static const Set<String> _identifierFragments = <String>{
    'session',
    'parent',
    'device',
    'identifier',
    'identity',
  };

  static const Set<String> _identifierCjkFragments = <String>{
    '会话',
    '會話',
    '设备',
    '設備',
    '装置',
    '裝置',
    '标识',
    '標識',
    '识别码',
    '識別碼',
    '编号',
    '編號',
  };

  static List<ToolOptionalShareField> review({
    required SessionRecord session,
    required Iterable<ToolOptionalShareField> declaredFields,
  }) {
    final fields = List<ToolOptionalShareField>.of(declaredFields);
    final idCounts = <String, int>{};
    for (final field in fields) {
      final normalizedId = field.id.trim().toLowerCase();
      idCounts.update(normalizedId, (count) => count + 1, ifAbsent: () => 1);
    }

    final approved = <ToolOptionalShareField>[];
    for (final field in fields) {
      final id = field.id.trim();
      final label = field.label.trim();
      final value = field.value.trim();
      final normalizedId = id.toLowerCase();
      if (idCounts[normalizedId] != 1 ||
          _classify(id) == null ||
          !_hasValidShape(field.id, maxIdLength) ||
          !_hasValidShape(field.label, maxLabelLength) ||
          !_hasValidShape(field.value, maxValueLength) ||
          _isIdentifierShaped(id) ||
          _isIdentifierShaped(label) ||
          containsSessionIdentifier(value, session)) {
        continue;
      }
      approved.add(ToolOptionalShareField(id: id, label: label, value: value));
    }
    return List<ToolOptionalShareField>.unmodifiable(approved);
  }

  static bool containsSessionIdentifier(String text, SessionRecord session) {
    final normalizedText = text.toLowerCase();
    final identifiers = <String>[session.id, ?session.parentSessionId];
    return identifiers.any(
      (identifier) =>
          identifier.isNotEmpty &&
          normalizedText.contains(identifier.toLowerCase()),
    );
  }

  static ToolOptionalShareFieldKind? _classify(String id) => switch (id) {
    'question' => ToolOptionalShareFieldKind.question,
    'intention' => ToolOptionalShareFieldKind.intention,
    _ => null,
  };

  static bool _hasValidShape(String value, int maxLength) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        value.runes.length <= maxLength &&
        !_controlCharacters.hasMatch(value);
  }

  static bool _isIdentifierShaped(String value) {
    final lower = value.toLowerCase();
    if (_identifierCjkFragments.any(lower.contains)) return true;

    final separated = value
        .replaceAllMapped(
          _camelCaseBoundary,
          (match) => '${match[1]} ${match[2]}',
        )
        .toLowerCase();
    final words = separated
        .split(_nonAsciiWord)
        .where((word) => word.isNotEmpty);
    if (words.any(_identifierWords.contains)) return true;

    final compact = lower.replaceAll(_nonAsciiAlphaNumeric, '');
    return _identifierFragments.any(compact.contains) ||
        compact == 'id' ||
        compact.endsWith('id');
  }
}

/// Optional fields are never part of the default share payload.
abstract interface class ToolShareOptionsCapability {
  List<ToolOptionalShareField> optionalShareFields(
    SessionRecord session,
    DecodedToolSession decoded,
  );
}

/// Shared marker for modules offering both replay privacy and optional share
/// fields without coupling the registry to a concrete feature.
mixin ToolPrivacyCapabilities
    implements ToolReplayCapability, ToolShareOptionsCapability {}
