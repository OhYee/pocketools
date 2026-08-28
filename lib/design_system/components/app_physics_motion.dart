import 'dart:math' as math;

import 'package:flutter/widgets.dart';

typedef AppPhysicsMotionBuilder = Widget Function(
  BuildContext context,
  double progress,
  Widget? child,
);

/// Small deterministic motion primitives shared by result animations.
///
/// These functions are deliberately pure. They sample a previously frozen
/// result and never create or consume entropy.
abstract final class AppPhysics {
  static double clampProgress(double progress) => progress.clamp(0.0, 1.0);

  static double spin(double progress, {required double turns}) =>
      clampProgress(progress) * turns * math.pi * 2;

  /// A launch arc that starts and ends on the table.
  static double ballisticArc(
    double progress, {
    required double height,
    double flightEnd = 0.72,
  }) {
    final value = clampProgress(progress);
    if (value >= flightEnd) return 0;
    final flight = (value / flightEnd).clamp(0.0, 1.0);
    return -height * 4 * flight * (1 - flight);
  }

  /// A short damped impact after the object meets the table.
  static double dampedImpact(
    double progress, {
    double impactStart = 0.72,
    double amplitude = 3.0,
    double frequency = 2.4,
    double damping = 5.0,
  }) {
    final value = clampProgress(progress);
    if (value <= impactStart) return 0;
    final local = ((value - impactStart) / (1 - impactStart)).clamp(0.0, 1.0);
    return amplitude *
        math.sin(local * math.pi * frequency) *
        math.exp(-damping * local) *
        (1 - local);
  }

  static double coinLanding(double progress) =>
      ballisticArc(progress, height: 52) +
      dampedImpact(progress, impactStart: 0.72, amplitude: 3.5);

  static double d20Landing(double progress) =>
      ballisticArc(progress, height: 22, flightEnd: 0.78) +
      dampedImpact(progress, impactStart: 0.78, amplitude: 2.6, frequency: 2.1);

  static double tarotLanding(double progress) =>
      ballisticArc(progress, height: 16, flightEnd: 0.82) +
      dampedImpact(progress, impactStart: 0.82, amplitude: 2.0, frequency: 2.0);

  static double settleScale(double progress, {double amount = 0.025}) {
    final value = clampProgress(progress);
    return 1 + amount * dampedImpact(value, amplitude: 1, frequency: 1.8);
  }
}

/// Runs a deterministic 0..1 sample. With animation disabled it immediately
/// samples the final state, which is the reduced-motion contract.
final class AppPhysicsMotion extends StatelessWidget {
  const AppPhysicsMotion({
    required this.duration,
    required this.builder,
    this.animate = true,
    this.child,
    super.key,
  });

  final Duration duration;
  final bool animate;
  final AppPhysicsMotionBuilder builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return builder(context, 1, child);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.linear,
      builder: (context, progress, child) => builder(context, progress, child),
      child: child,
    );
  }
}
