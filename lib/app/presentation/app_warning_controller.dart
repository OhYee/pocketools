import 'package:flutter/foundation.dart';

final class AppWarningController extends ChangeNotifier {
  String? _message;

  String? get message => _message;

  void show(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty || normalized == _message) return;
    _message = normalized;
    notifyListeners();
  }

  void clear() {
    if (_message == null) return;
    _message = null;
    notifyListeners();
  }
}
