import '../../../core/session/session.dart';
import '../domain/encyclopedia_models.dart';

final class EncyclopediaSessionCodec implements ToolSessionCodec {
  const EncyclopediaSessionCodec();

  @override
  String get toolId => 'encyclopedia';

  @override
  Map<String, Object?> encodeInput(Object input) => <String, Object?>{
    'section': _sectionFromObject(input).name,
  };

  @override
  EncyclopediaSection decodeInput(Map<String, Object?> input) =>
      _decodeSection(input, '图鉴输入');

  @override
  Map<String, Object?> encodeOutcome(Object outcome) => <String, Object?>{
    'section': _sectionFromObject(outcome).name,
  };

  @override
  EncyclopediaSection decodeOutcome(
    Map<String, Object?> outcome,
    Object input,
  ) {
    if (input is! EncyclopediaSection) {
      throw const FormatException('图鉴结果需要有效的图鉴分类。');
    }
    final section = _decodeSection(outcome, '图鉴结果');
    if (section != input) {
      throw const FormatException('图鉴结果分类与输入不一致。');
    }
    return section;
  }

  @override
  String summarize(SessionRecord session) {
    final section = decodeInput(session.input);
    return '图鉴 · ${encyclopediaSectionLabel(section)}';
  }

  static EncyclopediaSection _sectionFromObject(Object value) {
    if (value is! EncyclopediaSection) {
      throw const FormatException('图鉴分类无效。');
    }
    return value;
  }

  static EncyclopediaSection _decodeSection(
    Map<String, Object?> input,
    String source,
  ) {
    if (input.length != 1 || !input.containsKey('section')) {
      throw FormatException('$source字段不完整或包含未知字段。');
    }
    final encoded = input['section'];
    if (encoded is! String) {
      throw FormatException('$source分类必须是字符串。');
    }
    try {
      return EncyclopediaSection.values.byName(encoded);
    } on ArgumentError {
      throw FormatException('$source分类无效：$encoded。');
    }
  }
}
