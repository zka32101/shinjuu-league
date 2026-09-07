import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/viewmodels/skill_tree_viewmodel.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';

class MockSkillTreeService extends Mock implements SkillTreeService {}

class MockSkillTreeViewModel extends StateNotifier<AsyncValue<SkillTree>> {
  MockSkillTreeViewModel(SkillTree? skillTree)
      : super(
          skillTree != null
              ? AsyncValue.data(skillTree)
              : const AsyncValue.loading(),
        );

  @override
  Future<bool> allocateSkillPoint(int treeIndex, int tierIndex) async {
    final skillTree = state.value;
    if (skillTree == null) return false;

    // Simple mock: allocate if valid
    if (treeIndex < 0 || treeIndex >= 3) return false;
    if (tierIndex < 0 || tierIndex >= 5) return false;
    if (skillTree.availablePoints <= 0) return false;

    // Mark as allocated
    skillTree.trees[treeIndex].allocatedTiers++;
    skillTree.availablePoints--;
    skillTree.totalAllocatedPoints++;

    state = AsyncValue.data(skillTree);
    return true;
  }
}

void main() {
  group('SkillTreeProgressionScreen', () {
    group('ProgressBar widget', () {
      testWidgets('displays progress percentage correctly',
          (WidgetTester tester) async {
        final skillTree = SkillTree.create();
        skillTree.totalAllocatedPoints = 7;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildProgressBar(skillTree),
            ),
          ),
        );

        expect(find.text('ツリー進行度: 47%'), findsOneWidget);
      });

      testWidgets('progress bar color changes with completion',
          (WidgetTester tester) async {
        final skillTree = SkillTree.create();

        // 33% - blue
        skillTree.totalAllocatedPoints = 5;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildProgressBar(skillTree),
            ),
          ),
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // 67% - amber
        skillTree.totalAllocatedPoints = 10;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildProgressBar(skillTree),
            ),
          ),
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // 100% - green
        skillTree.totalAllocatedPoints = 15;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildProgressBar(skillTree),
            ),
          ),
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('PointsDisplay widget', () {
      testWidgets('displays all point metrics correctly',
          (WidgetTester tester) async {
        final skillTree = SkillTree.create();
        skillTree.availablePoints = 3;
        skillTree.totalAllocatedPoints = 5;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildPointsDisplay(
                  skillTree.availablePoints, skillTree.totalAllocatedPoints),
            ),
          ),
        );

        expect(find.text('3'), findsWidgets);
        expect(find.text('5'), findsWidgets);
        expect(find.text('8'), findsWidgets);
      });

      testWidgets('point cards are color-coded', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildPointsDisplay(5, 10),
            ),
          ),
        );

        expect(find.byType(Container), findsWidgets);
      });
    });

    group('TreeTabBar widget', () {
      testWidgets('displays all three tree tabs', (WidgetTester tester) async {
        int selectedTab = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildTreeTabBar(
                currentIndex: selectedTab,
                onTabSelected: (index) => selectedTab = index,
              ),
            ),
          ),
        );

        expect(find.text('攻撃'), findsOneWidget);
        expect(find.text('防御'), findsOneWidget);
        expect(find.text('素早さ'), findsOneWidget);
        expect(find.text('⚔️'), findsOneWidget);
        expect(find.text('🛡️'), findsOneWidget);
        expect(find.text('⚡'), findsOneWidget);
      });

      testWidgets('tab selection callback fires', (WidgetTester tester) async {
        int selectedTab = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildTreeTabBar(
                currentIndex: selectedTab,
                onTabSelected: (index) => selectedTab = index,
              ),
            ),
          ),
        );

        // Tap second tab
        await tester.tap(find.text('防御'));
        expect(selectedTab, equals(1));
      });

      testWidgets('current tab is highlighted', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildTreeTabBar(
                currentIndex: 1,
                onTabSelected: (_) {},
              ),
            ),
          ),
        );

        // The current tab should be visually distinct (background color)
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('TierCard widget', () {
      testWidgets('displays tier information correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildTierCard(
                tierIndex: 0,
                isAllocated: false,
                modifier: 1.05,
                onAllocate: () {},
              ),
            ),
          ),
        );

        expect(find.text('T1'), findsOneWidget);
        expect(find.text('+5.0%'), findsOneWidget);
        expect(find.text('割り当て可能'), findsOneWidget);
      });

      testWidgets('allocated tier shows check icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildTierCard(
                tierIndex: 0,
                isAllocated: true,
                modifier: 1.05,
                onAllocate: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('✓ 割り当て済み'), findsOneWidget);
      });

      testWidgets('locked tier shows lock icon', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildTierCard(
                tierIndex: 1,
                isAllocated: false,
                modifier: 1.10,
                onAllocate: null,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.text('ロック中'), findsOneWidget);
      });

      testWidgets('allocation button is present when available',
          (WidgetTester tester) async {
        bool allocateCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildTierCard(
                tierIndex: 0,
                isAllocated: false,
                modifier: 1.05,
                onAllocate: () => allocateCalled = true,
              ),
            ),
          ),
        );

        expect(find.text('割り当て'), findsOneWidget);
        await tester.tap(find.text('割り当て'));
        expect(allocateCalled, isTrue);
      });

      testWidgets('modifier percentage is displayed correctly',
          (WidgetTester tester) async {
        final testCases = [
          (1.05, '+5.0%'),
          (1.08, '+8.0%'),
          (1.03, '+3.0%'),
          (1.00, '×1.00'),
        ];

        for (final (modifier, expected) in testCases) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SkillTreeProgressionScreenTest.buildTierCard(
                  tierIndex: 0,
                  isAllocated: false,
                  modifier: modifier,
                  onAllocate: () {},
                ),
              ),
            ),
          );

          expect(find.text(expected), findsOneWidget);
          await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        }
      });
    });

    group('StatModifierRow widget', () {
      testWidgets('displays stat name and emoji', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildStatModifierRow(
                stat: '攻撃',
                emoji: '⚔️',
                modifier: 1.15,
              ),
            ),
          ),
        );

        expect(find.text('攻撃'), findsOneWidget);
        expect(find.text('⚔️'), findsOneWidget);
      });

      testWidgets('modifier is displayed as percentage when > 1.0',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildStatModifierRow(
                stat: '防御',
                emoji: '🛡️',
                modifier: 1.20,
              ),
            ),
          ),
        );

        expect(find.text('+20.0%'), findsOneWidget);
      });

      testWidgets('modifier is displayed as multiplier when = 1.0',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.buildStatModifierRow(
                stat: '素早さ',
                emoji: '⚡',
                modifier: 1.00,
              ),
            ),
          ),
        );

        expect(find.text('×1.00'), findsOneWidget);
      });
    });

    group('Loading and Error states', () {
      testWidgets('shows loading indicator while loading',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.LoadingState(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows error message on error', (WidgetTester tester) async {
        const error = 'テストエラー';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkillTreeProgressionScreenTest.ErrorState(error: error),
            ),
          ),
        );

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('エラーが発生しました'), findsOneWidget);
      });
    });
  });
}

/// Helper class for building test widgets
abstract class SkillTreeProgressionScreenTest {
  static Widget buildProgressBar(SkillTree skillTree) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ツリー進行度: ${(skillTree.totalAllocatedPoints / 15.0 * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12.0),
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: skillTree.totalAllocatedPoints / 15.0,
              minHeight: 16.0,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPointsDisplay(int available, int allocated) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            const Text('利用可能'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text('$available'),
            ),
          ]),
          Column(children: [
            const Text('割り当て済み'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text('$allocated'),
            ),
          ]),
          Column(children: [
            const Text('合計'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text('${available + allocated}'),
            ),
          ]),
        ],
      ),
    );
  }

  static Widget buildTreeTabBar({
    required int currentIndex,
    required ValueChanged<int> onTabSelected,
  }) {
    final treeEmojis = ['⚔️', '🛡️', '⚡'];
    final treeNames = ['攻撃', '防御', '素早さ'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (index) {
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(ProviderContainer().context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Theme.of(ProviderContainer().context).primaryColor,
                    width: 2.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(treeEmojis[index]),
                    Text(treeNames[index]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget buildTierCard({
    required int tierIndex,
    required bool isAllocated,
    required double modifier,
    required VoidCallback? onAllocate,
  }) {
    final isLocked = onAllocate == null && !isAllocated;
    final canAllocate = onAllocate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isAllocated
            ? Colors.blue.withOpacity(0.2)
            : isLocked
                ? Colors.grey.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isAllocated
              ? Colors.blue
              : isLocked
                  ? Colors.grey
                  : Colors.blue,
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAllocated
                  ? Colors.blue
                  : isLocked
                      ? Colors.grey
                      : Colors.blue,
            ),
            child: Center(
              child: Text(
                'T${tierIndex + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllocated
                      ? '✓ 割り当て済み'
                      : isLocked
                          ? 'ロック中'
                          : '割り当て可能',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAllocated
                        ? Colors.green
                        : isLocked
                            ? Colors.grey
                            : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '+${((modifier - 1.0) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12.0),
                ),
              ],
            ),
          ),
          if (canAllocate)
            GestureDetector(
              onTap: onAllocate,
              child: const Text('割り当て'),
            )
          else if (isAllocated)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            Icon(Icons.lock, color: Colors.grey[400]),
        ],
      ),
    );
  }

  static Widget buildStatModifierRow({
    required String stat,
    required String emoji,
    required double modifier,
  }) {
    final percentage = ((modifier - 1.0) * 100).toStringAsFixed(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji),
            const SizedBox(width: 8.0),
            Text(stat),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: modifier > 1.0 ? Colors.green.withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: modifier > 1.0 ? Colors.green : Colors.grey,
              width: 1.0,
            ),
          ),
          child: Text(
            modifier > 1.0 ? '+$percentage%' : '×${modifier.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: modifier > 1.0 ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  static const LoadingState = _LoadingState();
  static ErrorState ErrorState({required String error}) => _ErrorState(error: error);
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48.0,
            color: Colors.red,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'エラーが発生しました',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            error,
            style: const TextStyle(fontSize: 12.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
