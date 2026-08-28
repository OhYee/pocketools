import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/platform/motion_sensor.dart';

void main() {
  test('accepts a deliberate shake at the threshold', () {
    final trigger = ShakeMotionTrigger();

    expect(
      trigger.accept(
        const MotionSample(x: 18, y: 0, z: 0),
        DateTime(2026, 8, 23),
      ),
      isTrue,
    );
  });

  test('rejects orientation noise below the threshold', () {
    final trigger = ShakeMotionTrigger();

    expect(
      trigger.accept(
        const MotionSample(x: 3, y: 4, z: 0),
        DateTime(2026, 8, 23),
      ),
      isFalse,
    );
  });

  test('cooldown prevents one shake from creating repeated tosses', () {
    final trigger = ShakeMotionTrigger();
    final start = DateTime(2026, 8, 23);
    const shake = MotionSample(x: 20, y: 0, z: 0);

    expect(trigger.accept(shake, start), isTrue);
    expect(
      trigger.accept(shake, start.add(const Duration(milliseconds: 899))),
      isFalse,
    );
    expect(
      trigger.accept(shake, start.add(const Duration(milliseconds: 900))),
      isTrue,
    );
  });

  test('magnitude uses all three accelerometer axes', () {
    final trigger = ShakeMotionTrigger();

    expect(
      trigger.accept(
        const MotionSample(x: 11, y: 11, z: 11),
        DateTime(2026, 8, 23),
      ),
      isTrue,
    );
  });
}
