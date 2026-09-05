import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/skill_tree_service.dart';
import 'package:shinjuu_league/viewmodels/skill_tree_viewmodel.dart';

class MockSkillTreeService extends Mock implements SkillTreeService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('SkillTreeViewModel', () {
    late MockSkillTreeService mockSkillTreeService;
    late MockAuthService mockAuthService;
    late SkillTreeViewModel viewModel;

    setUp(() {
      mockSkillTreeService = MockSkillTreeService();
      mockAuthService = MockAuthService();
    });

    group('初期化', () {
      test('ユーザーがログインしていない場合は空のツリーを返す', () async {
        when(mockAuthService.currentUser).thenReturn(null);

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        // 初期化が完了するまで待機
        await Future.delayed(const Duration(milliseconds: 100));

        final skillTree = viewModel.state.value;
        expect(skillTree, isNotNull);
        expect(skillTree!.totalAllocatedPoints, equals(0));
      });

      test('初期状態ではLoadingを表示', () {
        when(mockAuthService.currentUser).thenReturn(null);

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        expect(viewModel.state, isA<AsyncValue>());
      });
    });

    group('スキルツリー読み込み', () {
      test('スキルツリーを正常に読み込める', () async {
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 1;

        when(mockSkillTreeService.getSkillTree('test_user'))
            .thenAnswer((_) async => skillTree);
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        final loadedTree = viewModel.state.value;
        expect(loadedTree, isNotNull);
        expect(loadedTree!.trees[0].allocatedTiers, equals(1));
      });

      test('読み込み失敗時はnullのツリーを作成', () async {
        when(mockSkillTreeService.getSkillTree('test_user'))
            .thenAnswer((_) async => null);
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        final tree = viewModel.state.value;
        expect(tree, isNotNull);
        expect(tree!.totalAllocatedPoints, equals(0));
      });
    });

    group('スキルポイント割り当て検証', () {
      test('有効な割り当てではtrueを返す', () async {
        final skillTree = SkillTree.create();
        skillTree.availablePoints = 1;
        skillTree.trees[0].allocatedTiers = 0;

        when(mockSkillTreeService.allocateSkillPoint('test_user', 0, 0))
            .thenAnswer((_) async => true);
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        final result = await viewModel.allocateSkillPoint(0, 0);
        expect(result, isTrue);
      });

      test('不正な割り当てではfalseを返す', () async {
        when(mockSkillTreeService.allocateSkillPoint('test_user', -1, 0))
            .thenAnswer((_) async => false);
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        final result = await viewModel.allocateSkillPoint(-1, 0);
        expect(result, isFalse);
      });

      test('割り当てできるかの検証が正しく動作', () {
        final skillTree = SkillTree.create();
        skillTree.availablePoints = 1;
        skillTree.trees[0].allocatedTiers = 0;

        when(mockSkillTreeService.getSkillTree('test_user'))
            .thenAnswer((_) async => skillTree);
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        // 手動でstateを設定
        viewModel.state = AsyncValue.data(skillTree);

        // 有効な割り当て
        expect(viewModel.canAllocateSkillPoint(0, 0), isTrue);

        // 無効なツリーインデックス
        expect(viewModel.canAllocateSkillPoint(-1, 0), isFalse);
        expect(viewModel.canAllocateSkillPoint(3, 0), isFalse);

        // ポイント不足
        skillTree.availablePoints = 0;
        expect(viewModel.canAllocateSkillPoint(0, 0), isFalse);
      });

      test('ツリーの順序を守る必要がある', () {
        final skillTree = SkillTree.create();
        skillTree.availablePoints = 1;
        skillTree.trees[0].allocatedTiers = 1; // 既に1ティア割り当て

        when(mockSkillTreeService.getSkillTree('test_user'))
            .thenAnswer((_) async => skillTree);
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = AsyncValue.data(skillTree);

        // 2ティア目は割り当て可能（tierIndex=1）
        expect(viewModel.canAllocateSkillPoint(0, 1), isTrue);

        // 3ティア目はスキップできない（tierIndex=2）
        expect(viewModel.canAllocateSkillPoint(0, 2), isFalse);
      });
    });

    group('進捗率計算', () {
      test('初期状態では0%', () {
        final skillTree = SkillTree.create();

        when(mockSkillTreeService.getSkillTree('test_user'))
            .thenAnswer((_) async => skillTree);
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = AsyncValue.data(skillTree);
        expect(viewModel.getProgressPercentage(), equals(0));
      });

      test('5ポイント割り当て時は33%', () {
        final skillTree = SkillTree.create();
        skillTree.totalAllocatedPoints = 5;

        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = AsyncValue.data(skillTree);
        expect(viewModel.getProgressPercentage(), equals(33));
      });

      test('15ポイント割り当て時は100%', () {
        final skillTree = SkillTree.create();
        skillTree.totalAllocatedPoints = 15;

        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = AsyncValue.data(skillTree);
        expect(viewModel.getProgressPercentage(), equals(100));
      });
    });

    group('ステータス修正', () {
      test('修正倍率を取得できる', () {
        final skillTree = SkillTree.create();
        skillTree.trees[0].allocatedTiers = 1; // ATK 1.05倍

        when(mockSkillTreeService.calculateStatModifiers(skillTree)).thenReturn({
          'atk': 1.05,
          'def': 1.0,
          'spd': 1.0,
        });
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = AsyncValue.data(skillTree);
        final modifiers = viewModel.getStatModifiers();

        expect(modifiers['atk'], closeTo(1.05, 0.001));
        expect(modifiers['def'], equals(1.0));
        expect(modifiers['spd'], equals(1.0));
      });

      test('修正倍率が存在しない場合はデフォルト値を返す', () {
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = const AsyncValue.data(null);
        final modifiers = viewModel.getStatModifiers();

        expect(modifiers['atk'], equals(1.0));
        expect(modifiers['def'], equals(1.0));
        expect(modifiers['spd'], equals(1.0));
      });
    });

    group('スキルツリー統計', () {
      test('統計情報を取得できる', () {
        final skillTree = SkillTree.create();
        skillTree.totalAllocatedPoints = 5;
        skillTree.availablePoints = 1;
        skillTree.trees[0].allocatedTiers = 2;

        when(mockSkillTreeService.getSkillTreeStats(skillTree)).thenReturn({
          'total_points': 15,
          'allocated_points': 5,
          'available_points': 1,
          'progress_percentage': 33,
          'atk_multiplier': '110.0',
          'def_multiplier': '100.0',
          'spd_multiplier': '100.0',
          'trees': [],
        });
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = AsyncValue.data(skillTree);
        final stats = viewModel.getSkillTreeStats();

        expect(stats['total_points'], equals(15));
        expect(stats['allocated_points'], equals(5));
        expect(stats['available_points'], equals(1));
        expect(stats['progress_percentage'], equals(33));
      });

      test('ツリーが空の場合はデフォルト統計を返す', () {
        when(mockAuthService.currentUser).thenReturn(
          _createMockUser('test_user'),
        );

        viewModel = SkillTreeViewModel(
          skillTreeService: mockSkillTreeService,
          authService: mockAuthService,
        );

        viewModel.state = const AsyncValue.data(null);
        final stats = viewModel.getSkillTreeStats();

        expect(stats['total_points'], equals(0));
        expect(stats['allocated_points'], equals(0));
        expect(stats['available_points'], equals(0));
      });
    });
  });
}

// Mock user creation helper
class MockUser {
  final String uid;
  MockUser(this.uid);
}

MockUser _createMockUser(String uid) => MockUser(uid);
