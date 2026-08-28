import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/app/presentation/preset_management_page.dart';
import 'package:pocketools/app/registry/default_tool_registry.dart';
import 'package:pocketools/core/presets/preset.dart';
import 'package:pocketools/core/presets/preset_controller.dart';
import 'package:pocketools/core/presets/preset_id_source.dart';
import 'package:pocketools/core/presets/preset_repository.dart';
import 'package:pocketools/design_system/app_theme.dart';

void main() {
  testWidgets(
    'management page copies, renames, deletes, and applies generically',
    (tester) async {
      ToolPreset? applied;
      final controller = PresetController(
        registry: buildDefaultToolRegistry(),
        repository: InMemoryPresetRepository(),
        idSource: _FixedPresetIdSource(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PresetManagementPage(
              controller: controller,
              onApply: (preset) => applied = preset,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preset-management-page')), findsOneWidget);
      expect(find.textContaining('系统预设（只读）'), findsWidgets);
      await tester.tap(find.byKey(const Key('apply-preset-tarot.daily-card')));
      expect(applied?.id, 'tarot.daily-card');

      final copyButton = find.byKey(const Key('copy-preset-tarot.daily-card'));
      await tester.ensureVisible(copyButton);
      await tester.tap(copyButton);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '我的牌阵');
      await tester.tap(find.widgetWithText(FilledButton, '保存副本'));
      await tester.pump();

      expect(find.text('我的牌阵'), findsWidgets);
      final userId = 'preset-widget-0';
      final renameButton = find.byKey(Key('rename-preset-$userId'));
      expect(renameButton, findsOneWidget);

      await tester.ensureVisible(renameButton);
      await tester.tap(renameButton);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '我的改名牌阵');
      await tester.tap(find.widgetWithText(FilledButton, '保存名称'));
      await tester.pump();
      expect(find.text('我的改名牌阵'), findsWidgets);

      final deleteButton = find.byKey(Key('delete-preset-$userId'));
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '删除').last);
      await tester.pump();
      expect(find.byKey(Key('delete-preset-$userId')), findsNothing);
      expect(find.text('今日一牌'), findsWidgets);
    },
  );
}

final class _FixedPresetIdSource implements PresetIdSource {
  var _index = 0;

  @override
  String next() => 'preset-widget-${_index++}';
}
