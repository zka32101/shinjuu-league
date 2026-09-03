import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/app_routes.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/match_result_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

const _selectTimeoutSeconds = 30;

/// スキルビルド選択画面
/// 進化選択後、バトル前にプレイヤーが3スキルを選択する
class SkillBuildScreen extends ConsumerStatefulWidget {
  const SkillBuildScreen({super.key, required this.match});
  final MatchResult match;

  @override
  ConsumerState<SkillBuildScreen> createState() => _SkillBuildScreenState();
}

class _SkillBuildScreenState extends ConsumerState<SkillBuildScreen> {
  Timer? _countdownTimer;
  int _countdownSeconds = _selectTimeoutSeconds;
  bool _isLocked = false;

  late List<SkillDefinition> availableSkills;
  late String selectedQ;
  late String selectedW;
  late String selectedE;

  @override
  void initState() {
    super.initState();

    // スキルリストを初期化（デフォルト神獣を使用）
    // 注：プレイヤーの選択中の神獣はMatchResultから取得するか、
    // BattleViewModelで既に設定されている状態で使用
    final mechaId = defaultMechaId;
    availableSkills = SkillSystemService.getSkillsForMecha(mechaId);

    if (availableSkills.length >= 3) {
      selectedQ = availableSkills[0].skillId;
      selectedW = availableSkills[1].skillId;
      selectedE = availableSkills[2].skillId;
    } else {
      throw Exception('Mecha must have at least 3 skills');
    }

    // 30秒のカウントダウンを開始
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdownSeconds--);
      if (_countdownSeconds <= 0) {
        _confirmBuild(); // タイムアウト時は現在の選択で確定
      }
    });
  }

  void _confirmBuild() {
    if (_isLocked) return;
    _isLocked = true;
    _countdownTimer?.cancel();

    if (!mounted) return;

    // スキルビルドを作成・確定
    final skillBuild = SkillBuild(
      skillId1: selectedQ,
      level1: 1,
      skillId2: selectedW,
      level2: 1,
      skillId3: selectedE,
      level3: 1,
    );

    final viewModel = ref.read(battleViewModelProvider.notifier);
    viewModel.selectSkillBuild(skillBuild);
    viewModel.beginCombat();

    context.pushReplacement(AppRoutes.battle, extra: widget.match);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('スキルビルド選択'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // タイムアウト表示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _countdownSeconds <= 5
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _countdownSeconds <= 5
                        ? Colors.red
                        : AppColors.accentBlue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _countdownSeconds <= 5
                          ? Colors.red
                          : AppColors.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_countdownSeconds秒でスキルビルドが確定します',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _countdownSeconds <= 5
                            ? Colors.red
                            : AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // スキルスロット表示
              _buildSkillSlot(
                label: 'Q（攻撃スキル）',
                selectedSkillId: selectedQ,
                onSelect: (skillId) => setState(() => selectedQ = skillId),
              ),
              const SizedBox(height: 16),

              _buildSkillSlot(
                label: 'W（防御スキル）',
                selectedSkillId: selectedW,
                onSelect: (skillId) => setState(() => selectedW = skillId),
              ),
              const SizedBox(height: 16),

              _buildSkillSlot(
                label: 'E（補助スキル）',
                selectedSkillId: selectedE,
                onSelect: (skillId) => setState(() => selectedE = skillId),
              ),
              const SizedBox(height: 32),

              // 詳細表示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ビルド詳細',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildSkillDetails(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 確定ボタン
              CustomButton(
                label: 'ビルドを確定',
                onPressed: _confirmBuild,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillSlot({
    required String label,
    required String selectedSkillId,
    required Function(String) onSelect,
  }) {
    final selectedSkill = SkillSystemService.getSkillDefinition(selectedSkillId);
    if (selectedSkill == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // スキルバッジ
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getSkillTypeColor(selectedSkill.type),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    selectedSkill.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // スキル情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedSkill.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedSkill.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Chip(
                          label: Text('コスト: ${selectedSkill.baseCost}'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            'CD: ${selectedSkill.cooldownSeconds.toStringAsFixed(1)}s',
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 変更ボタン
              PopupMenuButton<String>(
                onSelected: onSelect,
                itemBuilder: (BuildContext context) {
                  return availableSkills.map((skill) {
                    return PopupMenuItem<String>(
                      value: skill.skillId,
                      child: Text(skill.name),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkillDetails() {
    final skillQ = SkillSystemService.getSkillDefinition(selectedQ);
    final skillW = SkillSystemService.getSkillDefinition(selectedW);
    final skillE = SkillSystemService.getSkillDefinition(selectedE);

    // Gracefully handle missing skill definitions
    if (skillQ == null || skillW == null || skillE == null) {
      return [
        const Center(
          child: Text('スキル定義が見つかりません'),
        ),
      ];
    }

    return [
      _buildSkillDetailRow('Q', skillQ),
      const Divider(),
      _buildSkillDetailRow('W', skillW),
      const Divider(),
      _buildSkillDetailRow('E', skillE),
    ];
  }

  Widget _buildSkillDetailRow(String slot, SkillDefinition skill) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getSkillTypeColor(skill.type),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                slot,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Lv.1: ダメージ${(skill.baseDamageMultiplier * 100).toStringAsFixed(0)}% | コスト${skill.baseCost}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSkillTypeColor(SkillType type) {
    switch (type) {
      case SkillType.offensive:
        return Colors.red;
      case SkillType.defensive:
        return Colors.blue;
      case SkillType.utility:
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}
