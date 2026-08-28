import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/platform/shared_preferences_async_store.dart';
import 'package:pocketools/core/presets/preset_repository.dart';
import 'package:pocketools/core/session/persistent_session_repository.dart';

void main() {
  test('production preferences allowlist contains only Pocketools keys', () {
    final keys = SharedPreferencesAsyncStringStore.pocketoolsPreferenceKeys;

    expect(keys, containsAll(PersistentSessionRepository.ownedKeys));
    expect(keys, containsAll(PersistentPresetRepository.ownedKeys));
    expect(keys, everyElement(startsWith('pocketools.')));
    expect(keys, hasLength(7));
  });
}
