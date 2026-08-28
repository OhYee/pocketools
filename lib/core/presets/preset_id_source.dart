import 'dart:math';

import '../session/session_id_source.dart';

/// Stable identity source for user-created presets.
abstract interface class PresetIdSource {
  String next();
}

/// Secure UUID-shaped identity source kept separate from tool randomness.
final class SecurePresetIdSource implements PresetIdSource {
  SecurePresetIdSource({Random? entropy})
    : _delegate = SecureSessionIdSource(entropy: entropy);

  final SecureSessionIdSource _delegate;

  @override
  String next() => 'preset-${_delegate.next()}';
}
