import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/tools/session_actions.dart';

enum ShareLaunchStatus { success, dismissed, unavailable }

typedef PlatformShareOutcome = SessionTextActionOutcome;

abstract interface class ShareLauncher {
  Future<ShareLaunchStatus> share({
    required String title,
    required String text,
  });
}

abstract interface class ClipboardWriter {
  Future<void> writeText(String text);
}

/// Shares already-rendered, privacy-reviewed text without observing sessions.
///
/// An explicit user dismissal remains a dismissal. Only unavailable or failed
/// platform sharing falls back to text-only clipboard copy. No path can mutate
/// the source session.
final class PlatformShareService implements SessionTextGateway {
  const PlatformShareService({required this.launcher, required this.clipboard});

  factory PlatformShareService.system() => PlatformShareService(
    launcher: const SharePlusLauncher(),
    clipboard: const FlutterClipboardWriter(),
  );

  final ShareLauncher launcher;
  final ClipboardWriter clipboard;

  @override
  Future<PlatformShareOutcome> shareText({
    required String title,
    required String text,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'Share title cannot be empty.');
    }
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Share text cannot be empty.');
    }
    try {
      final status = await launcher.share(title: title, text: text);
      if (status == ShareLaunchStatus.success) {
        return SessionTextActionOutcome.shared;
      }
      if (status == ShareLaunchStatus.dismissed) {
        return SessionTextActionOutcome.dismissed;
      }
    } on Object {
      // Clipboard is the non-disruptive fallback for unavailable share APIs.
    }
    try {
      await clipboard.writeText(text);
      return SessionTextActionOutcome.copiedToClipboard;
    } on Object {
      return SessionTextActionOutcome.failed;
    }
  }

  @override
  Future<PlatformShareOutcome> copyText(String text) async {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Copy text cannot be empty.');
    }
    try {
      await clipboard.writeText(text);
      return SessionTextActionOutcome.copiedToClipboard;
    } on Object {
      return SessionTextActionOutcome.failed;
    }
  }
}

final class SharePlusLauncher implements ShareLauncher {
  const SharePlusLauncher();

  @override
  Future<ShareLaunchStatus> share({
    required String title,
    required String text,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(text: text, title: title, subject: title),
    );
    return switch (result.status) {
      ShareResultStatus.success => ShareLaunchStatus.success,
      ShareResultStatus.dismissed => ShareLaunchStatus.dismissed,
      ShareResultStatus.unavailable => ShareLaunchStatus.unavailable,
    };
  }
}

final class FlutterClipboardWriter implements ClipboardWriter {
  const FlutterClipboardWriter();

  @override
  Future<void> writeText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
