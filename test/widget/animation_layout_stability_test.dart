import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/design_system/app_theme.dart';
import 'package:pocketools/design_system/components/app_generation_state_view.dart';
import 'package:pocketools/design_system/components/app_surfaces.dart';
import 'package:pocketools/design_system/components/app_tool_flow_layout.dart';
import 'package:pocketools/features/tarot/domain/tarot_models.dart';
import 'package:pocketools/features/tarot/presentation/widgets/tarot_card_primitive.dart';

void main() {
  testWidgets(
    'entity animation does not push the primary action or advanced options',
    (tester) async {
      var expanded = false;
      late void Function(VoidCallback fn) update;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                body: AppToolFlowLayout(
                  coreEntity: AppSectionCard(
                    child: AnimatedContainer(
                      key: const Key('animated-entity-content'),
                      duration: const Duration(milliseconds: 400),
                      height: expanded ? 320 : 120,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  actionBar: const SizedBox(
                    key: Key('stable-primary-action'),
                    height: 48,
                  ),
                  advancedOptions: const SizedBox(
                    key: Key('stable-advanced-options'),
                    height: 48,
                  ),
                  outcome: const SizedBox(height: 48),
                ),
              );
            },
          ),
        ),
      );

      final actionTop = tester
          .getTopLeft(find.byKey(const Key('stable-primary-action')))
          .dy;
      final advancedTop = tester
          .getTopLeft(find.byKey(const Key('stable-advanced-options')))
          .dy;

      update(() => expanded = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));

      expect(
        tester.getTopLeft(find.byKey(const Key('stable-primary-action'))).dy,
        closeTo(actionTop, 0.001),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('stable-advanced-options'))).dy,
        closeTo(advancedTop, 0.001),
      );
    },
  );

  testWidgets('status and tarot reveal animations stay in fixed visual slots', (
    tester,
  ) async {
    var revealing = false;
    late void Function(VoidCallback fn) update;
    const card = TarotCard.major(
      id: 'major-00',
      name: '愚者',
      deckIndex: 0,
      majorNumber: 0,
    );
    const drawnCard = TarotDrawnCard(
      card: card,
      position: TarotPosition.dailyGuidance,
      orientation: TarotOrientation.upright,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Scaffold(
              body: Column(
                children: <Widget>[
                  KeyedSubtree(
                    key: const Key('stable-generation-state'),
                    child: AppGenerationStateView(
                      phase: revealing
                          ? GenerationPhase.revealing
                          : GenerationPhase.ready,
                      label: revealing ? '结果已生成，正在揭示' : '准备就绪',
                    ),
                  ),
                  TarotCardPrimitive(
                    key: const Key('stable-tarot-card'),
                    drawnCard: drawnCard,
                    animate: revealing,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final statusSize = tester.getSize(
      find.byKey(const Key('stable-generation-state')),
    );
    final cardSize = tester.getSize(find.byKey(const Key('stable-tarot-card')));

    update(() => revealing = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(
      tester.getSize(find.byKey(const Key('stable-generation-state'))),
      statusSize,
    );
    expect(
      tester.getSize(find.byKey(const Key('stable-tarot-card'))),
      cardSize,
    );
  });
}
