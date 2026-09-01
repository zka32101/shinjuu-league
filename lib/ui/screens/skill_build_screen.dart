import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// スキルビルド選択画面
/// マッチング成功後・バトル前にプレイヤーが3スキルを選択する
class SkillBuildScreen extends ConsumerStatefulWidget {
  final String mechaId;
  final VoidCallback onBuildConfirmed;

  const SkillBuildScreen({
    required this.mechaId,
    required this.onBuildConfirmed,
  });

  @override
  ConsumerState<SkillBuildScreen> createState() => _SkillBuildScreenState();
}

class _SkillBuildScreenState extends ConsumerState<SkillBuildScreen> {
  late List<SkillDefinition> availableSkills;
  late String selectedQ;
  late String selectedW;
  late String selectedE;
  int _countdownSeconds = 30;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    availableSkills =
        SkillSystemService.getSkillsForMecha(widget.mechaId);

    if (availableSkills.length >= 3) {
      selectedQ = availableSkills[0].skillId;
      selectedW = availableSkills[1].skillId;
      selectedE = availableSkills[2].skillId;
    } else {
      throw Exception('Mecha must have at least 3 skills');
    }

    _startTime = DateTime.now();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds <= 0) {
        _confirmBuild();
        return false;
      }

      return true;
    });
  }

  void _confirmBuild() {
    // TODO: SkillBuild を BattleViewModel に保存
    widget.onBuildConfirmed();
    context.go('/battle');
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
                      ? Colors.red.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
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
                      '${_countdownSeconds}秒でスキルビルドが確定します',
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
                text: 'ビルドを確定',
                onTap: _confirmBuild,
                isEnabled: true,
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
                          visualDensity:
                              VisualDensity.compact,
                          backgroundColor:
                              Colors.blue.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            'CD: ${selectedSkill.cooldownSeconds.toStringAsFixed(1)}s',
                          ),
                          visualDensity:
                              VisualDensity.compact,
                          backgroundColor:
                              Colors.orange.withOpacity(0.2),
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
                    color: AppColors.accentBlue.withOpacity(0.2),
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

    return [
      _buildSkillDetailRow('Q', skillQ!),
      const Divider(),
      _buildSkillDetailRow('W', skillW!),
      const Divider(),
      _buildSkillDetailRow('E', skillE!),
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
    }
  }
}
