import 'dart:collection';

enum LiuyaoMode { automatic, manual }

enum LiuyaoCoinSide {
  heads(3),
  tails(2);

  const LiuyaoCoinSide(this.points);

  final int points;
}

enum LiuyaoLineNature { yin, yang }

enum LiuyaoLineKind {
  oldYin(value: 6, nature: LiuyaoLineNature.yin, moving: true),
  youngYang(value: 7, nature: LiuyaoLineNature.yang, moving: false),
  youngYin(value: 8, nature: LiuyaoLineNature.yin, moving: false),
  oldYang(value: 9, nature: LiuyaoLineNature.yang, moving: true);

  const LiuyaoLineKind({
    required this.value,
    required this.nature,
    required this.moving,
  });

  final int value;
  final LiuyaoLineNature nature;
  final bool moving;

  LiuyaoLineNature get changedNature => moving
      ? nature == LiuyaoLineNature.yang
            ? LiuyaoLineNature.yin
            : LiuyaoLineNature.yang
      : nature;

  static LiuyaoLineKind fromValue(int value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    throw ArgumentError.value(
      value,
      'value',
      'Line value must be 6, 7, 8, or 9.',
    );
  }
}

enum LiuyaoLineSource { automaticCoins, manualValue }

final class LiuyaoConfig {
  const LiuyaoConfig({this.mode = LiuyaoMode.automatic, this.intention});

  static const maximumIntentionLength = 500;

  final LiuyaoMode mode;
  final String? intention;

  String? get normalizedIntention {
    final value = intention?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  LiuyaoConfig normalized({bool includeIntention = true}) => LiuyaoConfig(
    mode: mode,
    intention: includeIntention ? normalizedIntention : null,
  );

  List<String> validate() {
    final errors = <String>[];
    final value = normalizedIntention;
    if (value != null && value.length > maximumIntentionLength) {
      errors.add('问题或备注不能超过 $maximumIntentionLength 个字符。');
    }
    if (value != null && _containsUnsupportedControlCharacter(value)) {
      errors.add('问题或备注包含不支持的控制字符。');
    }
    return List<String>.unmodifiable(errors);
  }

  static bool _containsUnsupportedControlCharacter(String value) {
    for (final unit in value.codeUnits) {
      if (unit < 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D) {
        return true;
      }
      if (unit == 0x7F) return true;
    }
    return false;
  }
}

final class LiuyaoLine {
  LiuyaoLine({
    required this.index,
    required this.value,
    required this.source,
    Iterable<LiuyaoCoinSide>? coins,
  }) : coins = coins == null
           ? null
           : UnmodifiableListView<LiuyaoCoinSide>(
               List<LiuyaoCoinSide>.of(coins),
             ) {
    if (index < 0 || index >= LiuyaoReading.lineCapacity) {
      throw RangeError.range(index, 0, LiuyaoReading.lineCapacity - 1, 'index');
    }
    LiuyaoLineKind.fromValue(value);
    if (source == LiuyaoLineSource.automaticCoins) {
      if (this.coins == null || this.coins!.length != 3) {
        throw ArgumentError(
          'Automatic lines must contain exactly three coins.',
        );
      }
      final sum = this.coins!.fold<int>(
        0,
        (total, side) => total + side.points,
      );
      if (sum != value) {
        throw ArgumentError(
          'Coin points must add up to the stored line value.',
        );
      }
    } else if (this.coins != null) {
      throw ArgumentError('Manual value lines must not contain coin results.');
    }
  }

  final int index;
  final int value;
  final LiuyaoLineSource source;
  final List<LiuyaoCoinSide>? coins;

  LiuyaoLineKind get kind => LiuyaoLineKind.fromValue(value);
  LiuyaoLineNature get nature => kind.nature;
  LiuyaoLineNature get changedNature => kind.changedNature;
  bool get isMoving => kind.moving;
}

final class LiuyaoReading {
  LiuyaoReading({
    required LiuyaoConfig config,
    Iterable<LiuyaoLine> lines = const <LiuyaoLine>[],
  }) : config = config.normalized(),
       lines = UnmodifiableListView<LiuyaoLine>(List<LiuyaoLine>.of(lines)) {
    final configErrors = this.config.validate();
    if (configErrors.isNotEmpty) throw ArgumentError(configErrors.join(' '));
    if (this.lines.length > lineCapacity) {
      throw ArgumentError('A Liuyao reading can contain at most six lines.');
    }
    for (var index = 0; index < this.lines.length; index++) {
      final line = this.lines[index];
      if (line.index != index) {
        throw ArgumentError('Line indexes must be contiguous from zero.');
      }
      final expectedSource = this.config.mode == LiuyaoMode.automatic
          ? LiuyaoLineSource.automaticCoins
          : LiuyaoLineSource.manualValue;
      if (line.source != expectedSource) {
        throw ArgumentError('Line source does not match the reading mode.');
      }
    }
  }

  static const lineCapacity = 6;

  final LiuyaoConfig config;
  final List<LiuyaoLine> lines;

  bool get isComplete => lines.length == lineCapacity;
  int get nextLineIndex => lines.length;
  List<int> get movingLineIndexes => List<int>.unmodifiable(
    lines.where((line) => line.isMoving).map((line) => line.index),
  );

  LiuyaoReading append(LiuyaoLine line) {
    if (isComplete) {
      throw StateError('A completed Liuyao reading is immutable.');
    }
    if (line.index != nextLineIndex) {
      throw ArgumentError('The next line index must be $nextLineIndex.');
    }
    return LiuyaoReading(config: config, lines: <LiuyaoLine>[...lines, line]);
  }

  LiuyaoReading undoLastLine() {
    if (isComplete) {
      throw StateError('A completed Liuyao reading cannot be edited.');
    }
    if (lines.isEmpty) throw StateError('There is no line to undo.');
    return LiuyaoReading(
      config: config,
      lines: lines.sublist(0, lines.length - 1),
    );
  }
}
