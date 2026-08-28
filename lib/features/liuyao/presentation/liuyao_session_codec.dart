import '../../../core/session/session.dart';
import '../content/liuyao_content_catalog.dart';
import '../domain/liuyao_hexagrams.dart';
import '../domain/liuyao_models.dart';
import 'liuyao_labels.dart';

final class LiuyaoSessionCodec implements ToolSessionCodec {
  const LiuyaoSessionCodec();

  @override
  String get toolId => 'liuyao';

  @override
  Map<String, Object?> encodeInput(Object input) {
    if (input is! LiuyaoConfig) {
      throw const FormatException('Liuyao input must be a LiuyaoConfig.');
    }
    final config = input.normalized();
    final errors = config.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join(' '));
    return <String, Object?>{
      'mode': config.mode.name,
      'intention': config.normalizedIntention,
      'lineCapacity': LiuyaoReading.lineCapacity,
    };
  }

  @override
  LiuyaoConfig decodeInput(Map<String, Object?> input) {
    _requireExactKeys(input, const <String>{
      'mode',
      'intention',
      'lineCapacity',
    }, 'Liuyao input');
    final mode = _enumByName(
      LiuyaoMode.values,
      _requiredString(input, 'mode', 'Liuyao input'),
      'Liuyao input mode',
    );
    final capacity = _requiredInt(input, 'lineCapacity', 'Liuyao input');
    if (capacity != LiuyaoReading.lineCapacity) {
      throw FormatException(
        'Liuyao input lineCapacity must be ${LiuyaoReading.lineCapacity}.',
      );
    }
    final config = LiuyaoConfig(
      mode: mode,
      intention: _optionalString(input, 'intention', 'Liuyao input'),
    ).normalized();
    final errors = config.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join(' '));
    return config;
  }

  @override
  Map<String, Object?> encodeOutcome(Object outcome) {
    if (outcome is! LiuyaoReading) {
      throw const FormatException('Liuyao outcome must be a LiuyaoReading.');
    }
    final reading = LiuyaoReading(config: outcome.config, lines: outcome.lines);
    final primary = reading.isComplete
        ? LiuyaoHexagrams.resolve(reading.lines)
        : null;
    final changed = reading.isComplete && reading.movingLineIndexes.isNotEmpty
        ? LiuyaoHexagrams.resolve(reading.lines, changed: true)
        : null;
    return <String, Object?>{
      'lineCount': reading.lines.length,
      'lines': reading.lines.map(_encodeLine).toList(growable: false),
      'complete': reading.isComplete,
      'primaryHexagramId': primary?.id,
      'changedHexagramId': changed?.id,
      'contentVersion': LiuyaoContentCatalog.contentVersion,
    };
  }

  @override
  LiuyaoReading decodeOutcome(Map<String, Object?> outcome, Object input) {
    if (input is! LiuyaoConfig) {
      throw const FormatException('Decoded Liuyao input has an invalid type.');
    }
    _requireExactKeys(outcome, const <String>{
      'lineCount',
      'lines',
      'complete',
      'primaryHexagramId',
      'changedHexagramId',
      'contentVersion',
    }, 'Liuyao outcome');
    final lineCount = _requiredInt(outcome, 'lineCount', 'Liuyao outcome');
    if (lineCount < 0 || lineCount > LiuyaoReading.lineCapacity) {
      throw const FormatException(
        'Liuyao outcome lineCount must be 0 through 6.',
      );
    }
    final rawLines = outcome['lines'];
    if (rawLines is! List || rawLines.length != lineCount) {
      throw const FormatException(
        'Liuyao outcome lines length must match lineCount.',
      );
    }
    final lines = <LiuyaoLine>[];
    for (var index = 0; index < rawLines.length; index++) {
      final rawLine = rawLines[index];
      if (rawLine is! Map) {
        throw FormatException('Liuyao outcome lines[$index] must be a map.');
      }
      final lineMap = <String, Object?>{};
      for (final entry in rawLine.entries) {
        if (entry.key is! String) {
          throw FormatException(
            'Liuyao outcome lines[$index] keys must be strings.',
          );
        }
        lineMap[entry.key as String] = entry.value;
      }
      lines.add(_decodeLine(lineMap, index));
    }
    final complete = _requiredBool(outcome, 'complete', 'Liuyao outcome');
    if (complete != (lineCount == LiuyaoReading.lineCapacity)) {
      throw const FormatException(
        'Liuyao outcome complete must match whether six lines exist.',
      );
    }
    final version = _requiredString(
      outcome,
      'contentVersion',
      'Liuyao outcome',
    );
    if (version != LiuyaoContentCatalog.contentVersion) {
      throw FormatException('Unsupported Liuyao contentVersion: $version.');
    }

    late final LiuyaoReading reading;
    try {
      reading = LiuyaoReading(config: input, lines: lines);
    } on Object catch (error) {
      throw FormatException('Invalid Liuyao reading: $error');
    }
    final primaryId = _optionalString(
      outcome,
      'primaryHexagramId',
      'Liuyao outcome',
    );
    final changedId = _optionalString(
      outcome,
      'changedHexagramId',
      'Liuyao outcome',
    );
    if (!complete) {
      if (primaryId != null || changedId != null) {
        throw const FormatException(
          'Incomplete Liuyao outcomes must not contain hexagram ids.',
        );
      }
      return reading;
    }
    final expectedPrimary = LiuyaoHexagrams.resolve(lines).id;
    if (primaryId != expectedPrimary) {
      throw FormatException(
        'Liuyao primaryHexagramId must be $expectedPrimary.',
      );
    }
    if (reading.movingLineIndexes.isEmpty) {
      if (changedId != null) {
        throw const FormatException(
          'A static Liuyao outcome must not contain changedHexagramId.',
        );
      }
    } else {
      final expectedChanged = LiuyaoHexagrams.resolve(lines, changed: true).id;
      if (changedId != expectedChanged) {
        throw FormatException(
          'Liuyao changedHexagramId must be $expectedChanged.',
        );
      }
    }
    return reading;
  }

  @override
  String summarize(SessionRecord session) {
    final config = decodeInput(session.input);
    final reading = decodeOutcome(session.outcome, config);
    if (!reading.isComplete) {
      return '${liuyaoModeLabel(config.mode)} · 已完成 ${reading.lines.length}/6 爻';
    }
    final primary = LiuyaoHexagrams.resolve(reading.lines);
    final moving = reading.movingLineIndexes;
    return moving.isEmpty
        ? '第 ${primary.kingWenNumber} 卦 ${primary.name} · 无动爻'
        : '第 ${primary.kingWenNumber} 卦 ${primary.name} · '
              '动爻 ${moving.map((index) => index + 1).join('、')}';
  }

  Map<String, Object?> _encodeLine(LiuyaoLine line) => <String, Object?>{
    'sequence': line.index,
    'value': line.value,
    'source': line.source.name,
    'coins': line.coins?.map((side) => side.name).toList(growable: false),
  };

  LiuyaoLine _decodeLine(Map<String, Object?> payload, int expectedIndex) {
    _requireExactKeys(payload, const <String>{
      'sequence',
      'value',
      'source',
      'coins',
    }, 'Liuyao line $expectedIndex');
    final sequence = _requiredInt(payload, 'sequence', 'Liuyao line');
    if (sequence != expectedIndex) {
      throw FormatException(
        'Liuyao line sequence must be $expectedIndex; got $sequence.',
      );
    }
    final value = _requiredInt(payload, 'value', 'Liuyao line');
    final source = _enumByName(
      LiuyaoLineSource.values,
      _requiredString(payload, 'source', 'Liuyao line'),
      'Liuyao line source',
    );
    List<LiuyaoCoinSide>? coins;
    final rawCoins = payload['coins'];
    if (rawCoins != null) {
      if (rawCoins is! List || rawCoins.length != 3) {
        throw const FormatException(
          'Automatic Liuyao lines must contain exactly three coins.',
        );
      }
      coins = List<LiuyaoCoinSide>.generate(rawCoins.length, (index) {
        final rawSide = rawCoins[index];
        if (rawSide is! String) {
          throw FormatException('Liuyao coin $index must be a string.');
        }
        return _enumByName(
          LiuyaoCoinSide.values,
          rawSide,
          'Liuyao coin $index',
        );
      }, growable: false);
    }
    try {
      return LiuyaoLine(
        index: sequence,
        value: value,
        source: source,
        coins: coins,
      );
    } on Object catch (error) {
      throw FormatException('Invalid Liuyao line $sequence: $error');
    }
  }

  void _requireExactKeys(
    Map<String, Object?> payload,
    Set<String> expected,
    String source,
  ) {
    final actual = payload.keys.toSet();
    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw FormatException(
        '$source keys must be exactly ${expected.toList()..sort()}.',
      );
    }
  }

  String _requiredString(
    Map<String, Object?> payload,
    String key,
    String source,
  ) {
    final value = payload[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$source $key must be a non-empty string.');
    }
    return value;
  }

  String? _optionalString(
    Map<String, Object?> payload,
    String key,
    String source,
  ) {
    final value = payload[key];
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw FormatException('$source $key must be null or a non-empty string.');
    }
    return value;
  }

  int _requiredInt(Map<String, Object?> payload, String key, String source) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('$source $key must be an integer.');
    }
    return value;
  }

  bool _requiredBool(Map<String, Object?> payload, String key, String source) {
    final value = payload[key];
    if (value is! bool) {
      throw FormatException('$source $key must be a boolean.');
    }
    return value;
  }

  T _enumByName<T extends Enum>(
    Iterable<T> values,
    String name,
    String source,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('$source has unsupported value: $name.');
  }
}
