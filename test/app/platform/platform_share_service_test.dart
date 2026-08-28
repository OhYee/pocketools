import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/platform/platform_share_service.dart';

void main() {
  test('successful text share does not touch clipboard', () async {
    final launcher = _Launcher(ShareLaunchStatus.success);
    final clipboard = _Clipboard();
    final service = PlatformShareService(
      launcher: launcher,
      clipboard: clipboard,
    );

    final result = await service.shareText(title: 'Cards', text: 'A, K, 4');

    expect(result, PlatformShareOutcome.shared);
    expect(launcher.lastTitle, 'Cards');
    expect(launcher.lastText, 'A, K, 4');
    expect(clipboard.values, isEmpty);
  });

  test(
    'explicit share dismissal remains cancelled without clipboard side effect',
    () async {
      final clipboard = _Clipboard();
      final service = PlatformShareService(
        launcher: _Launcher(ShareLaunchStatus.dismissed),
        clipboard: clipboard,
      );

      final result = await service.shareText(title: 'Coin', text: '正、反、正');

      expect(result, PlatformShareOutcome.dismissed);
      expect(clipboard.values, isEmpty);
    },
  );

  test('unavailable share copies final text as fallback', () async {
    final clipboard = _Clipboard();
    final service = PlatformShareService(
      launcher: _Launcher(ShareLaunchStatus.unavailable),
      clipboard: clipboard,
    );

    final result = await service.shareText(title: 'Coin', text: '正、反、正');

    expect(result, PlatformShareOutcome.copiedToClipboard);
    expect(clipboard.values, <String>['正、反、正']);
  });

  test(
    'share exceptions fall back and clipboard exceptions remain no-op',
    () async {
      final copied = await PlatformShareService(
        launcher: _Launcher(ShareLaunchStatus.unavailable, throws: true),
        clipboard: _Clipboard(),
      ).shareText(title: 'Dice', text: '41');
      final failed = await PlatformShareService(
        launcher: _Launcher(ShareLaunchStatus.unavailable, throws: true),
        clipboard: _Clipboard(throws: true),
      ).shareText(title: 'Dice', text: '41');

      expect(copied, PlatformShareOutcome.copiedToClipboard);
      expect(failed, PlatformShareOutcome.failed);
    },
  );

  test(
    'empty title or text is rejected before launching platform UI',
    () async {
      final launcher = _Launcher(ShareLaunchStatus.success);
      final service = PlatformShareService(
        launcher: launcher,
        clipboard: _Clipboard(),
      );

      await expectLater(
        service.shareText(title: ' ', text: 'result'),
        throwsArgumentError,
      );
      await expectLater(
        service.shareText(title: 'title', text: ' '),
        throwsArgumentError,
      );
      expect(launcher.calls, 0);
    },
  );
}

final class _Launcher implements ShareLauncher {
  _Launcher(this.status, {this.throws = false});

  final ShareLaunchStatus status;
  final bool throws;
  int calls = 0;
  String? lastTitle;
  String? lastText;

  @override
  Future<ShareLaunchStatus> share({
    required String title,
    required String text,
  }) async {
    calls++;
    lastTitle = title;
    lastText = text;
    if (throws) throw StateError('controlled failure');
    return status;
  }
}

final class _Clipboard implements ClipboardWriter {
  _Clipboard({this.throws = false});

  final bool throws;
  final List<String> values = <String>[];

  @override
  Future<void> writeText(String text) async {
    if (throws) throw StateError('controlled failure');
    values.add(text);
  }
}
