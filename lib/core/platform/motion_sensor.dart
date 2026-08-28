import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum MotionSensorStatus { unknown, available, unsupported, unavailable }

@immutable
final class MotionSample {
  const MotionSample({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;

  double get magnitude => math.sqrt(x * x + y * y + z * z);
}

/// Platform boundary for optional motion input.
///
/// A tool must remain usable when this stream is unsupported, unavailable, or
/// fails after startup. Implementations are deliberately injectable so the
/// shake policy can be tested without physical hardware.
abstract interface class MotionSensor {
  factory MotionSensor.system() => _PlatformMotionSensor();

  Stream<MotionSample> get samples;

  Future<MotionSensorStatus> start();

  Future<void> stop();
}

/// Pure shake policy shared by the platform adapter and widget tests.
///
/// Android's accelerometer reports m/s² including gravity. A magnitude above
/// this threshold is intentionally a deliberate shake rather than a normal
/// orientation change. The cooldown prevents one physical shake from
/// generating several tosses.
final class ShakeMotionTrigger {
  ShakeMotionTrigger({
    this.threshold = 18.0,
    this.cooldown = const Duration(milliseconds: 900),
  });

  final double threshold;
  final Duration cooldown;
  DateTime? _lastTriggeredAt;

  bool accept(MotionSample sample, DateTime now) {
    if (sample.magnitude < threshold) return false;
    final previous = _lastTriggeredAt;
    if (previous != null && now.difference(previous) < cooldown) return false;
    _lastTriggeredAt = now;
    return true;
  }
}

final class _PlatformMotionSensor implements MotionSensor {
  _PlatformMotionSensor();

  static const _controlChannel = MethodChannel('pocketools/motion_sensor');
  static const _eventChannel = EventChannel('pocketools/motion_sensor/events');

  MotionSensorStatus _status = MotionSensorStatus.unknown;

  @override
  Stream<MotionSample> get samples =>
      _eventChannel.receiveBroadcastStream().map<MotionSample>(_decodeSample);

  @override
  Future<MotionSensorStatus> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _status = MotionSensorStatus.unsupported;
      return _status;
    }
    if (_status == MotionSensorStatus.available) return _status;
    try {
      final started =
          await _controlChannel.invokeMethod<bool>('start') ?? false;
      _status = started
          ? MotionSensorStatus.available
          : MotionSensorStatus.unavailable;
    } on MissingPluginException {
      _status = MotionSensorStatus.unavailable;
    } on PlatformException {
      _status = MotionSensorStatus.unavailable;
    } on Object {
      _status = MotionSensorStatus.unavailable;
    }
    return _status;
  }

  @override
  Future<void> stop() async {
    if (_status != MotionSensorStatus.available) return;
    try {
      await _controlChannel.invokeMethod<bool>('stop');
    } on MissingPluginException {
      // The platform is already unavailable; manual input remains active.
    } on PlatformException {
      // Stopping an optional sensor must never block the coin tool.
    } on Object {
      // Keep shutdown best-effort for the same reason.
    }
    _status = MotionSensorStatus.unknown;
  }

  static MotionSample _decodeSample(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Motion sensor sample is not a map.');
    }
    final x = _number(value['x']);
    final y = _number(value['y']);
    final z = _number(value['z']);
    if (x == null || y == null || z == null) {
      throw const FormatException('Motion sensor sample has invalid axes.');
    }
    return MotionSample(x: x, y: y, z: z);
  }

  static double? _number(Object? value) => switch (value) {
    num number => number.toDouble(),
    _ => null,
  };
}
