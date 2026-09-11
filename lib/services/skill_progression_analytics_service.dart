import 'package:shinjuu_league/data/models/evolution_model.dart';
import 'package:shinjuu_league/data/models/skill_catalog.dart';
import 'package:shinjuu_league/services/analytics_service.dart';

/// スキル進行システムのAnalytics イベント追跡
///
/// ユーザーのスキル進行（レベルアップ・進化選択・スキル使用）を
/// Firebase Analytics へ自動的に記録し、プレイパターン分析に活用。
class SkillProgressionAnalyticsService {
  final AnalyticsService _analyticsService;

  SkillProgressionAnalyticsService({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService ?? AnalyticsService();

  /// プレイヤーがレベルアップした時に呼び出す
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - newLevel: 新しいレベル（2-8）
  /// - isEvolutionRequired: Lv3/Lv6 で進化選択が必要か
  Future<void> logLevelUp(
    String userId,
    int newLevel,
    bool isEvolutionRequired,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_level_up',
        parameters: {
          'user_id': userId,
          'new_level': newLevel,
          'is_evolution_required': isEvolutionRequired,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理（Analytics 失敗でゲーム流れを止めない）
    }
  }

  /// プレイヤーが進化を確認した時に呼び出す
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - level: 進化が確定したレベル（3 or 6）
  /// - evolutionChoice: 選択された進化タイプ（offensive/defensive/support）
  /// - selectionTimeMs: 選択画面が表示されてから確定までの時間（ミリ秒）
  /// - isAutoSelected: true の場合はタイムアウト自動選択
  Future<void> logEvolutionConfirmed(
    String userId,
    int level,
    EvolutionType evolutionChoice,
    int selectionTimeMs,
    bool isAutoSelected,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_evolution_confirmed',
        parameters: {
          'user_id': userId,
          'level': level,
          'evolution_choice': evolutionChoice.toString().split('.').last,
          'selection_time_ms': selectionTimeMs,
          'is_auto_selected': isAutoSelected,
          'selection_type': level == 3 ? 'first_evolution' : 'second_evolution',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// プレイヤーが進化を切り替えた時に呼び出す（Lv6のみ）
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - previousEvolution: 前の進化タイプ
  /// - newEvolution: 新しい進化タイプ
  /// - switchCount: これまでの切り替え回数
  Future<void> logEvolutionSwitched(
    String userId,
    EvolutionType previousEvolution,
    EvolutionType newEvolution,
    int switchCount,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_evolution_switched',
        parameters: {
          'user_id': userId,
          'previous_evolution': previousEvolution.toString().split('.').last,
          'new_evolution': newEvolution.toString().split('.').last,
          'switch_count': switchCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// プレイヤーがスキルを使用した時に呼び出す
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - skillSlot: 使用したスキルスロット（Q/R/E/ULT）
  /// - currentLevel: スキル使用時のレベル
  /// - damageDealt: 与えたダメージ
  /// - hasEvolutionBonus: 進化ボーナスが適用されているか
  /// - isCritical: クリティカルヒットか
  Future<void> logSkillUsed(
    String userId,
    SkillSlot skillSlot,
    int currentLevel,
    int damageDealt,
    bool hasEvolutionBonus,
    bool isCritical,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_skill_used',
        parameters: {
          'user_id': userId,
          'skill_slot': skillSlot.toString().split('.').last,
          'current_level': currentLevel,
          'damage_dealt': damageDealt,
          'has_evolution_bonus': hasEvolutionBonus,
          'is_critical': isCritical,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// ULT スキルが解放された時に呼び出す
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  Future<void> logUltUnlocked(String userId) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_ult_unlocked',
        parameters: {
          'user_id': userId,
          'level': 7,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// ULT スキルが使用された時に呼び出す
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - damageDealt: 与えたダメージ
  /// - targetsHit: ヒットした対象数
  Future<void> logUltActivated(
    String userId,
    int damageDealt,
    int targetsHit,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_ult_activated',
        parameters: {
          'user_id': userId,
          'damage_dealt': damageDealt,
          'targets_hit': targetsHit,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// プレイヤーが最大レベル（Lv8）に到達した時に呼び出す
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - timeToMaxLevelSeconds: ゲーム開始からレベル8到達までの時間
  /// - finalEvolution: 最終進化タイプ
  /// - totalKills: 到達時点でのキル数
  Future<void> logMaxLevelReached(
    String userId,
    int timeToMaxLevelSeconds,
    EvolutionType finalEvolution,
    int totalKills,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_max_level_reached',
        parameters: {
          'user_id': userId,
          'level': 8,
          'time_to_max_level_seconds': timeToMaxLevelSeconds,
          'final_evolution': finalEvolution.toString().split('.').last,
          'total_kills': totalKills,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// プレイヤーの最終的なスキル進行統計を記録する（バトル終了時）
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - finalLevel: 到達した最終レベル
  /// - totalSkillsUsed: 使用したスキルの総数
  /// - totalDamageDealt: 与えた総ダメージ
  /// - battleDurationSeconds: バトルの継続時間
  /// - won: バトルに勝利したか
  Future<void> logBattleSkillProgressionSummary({
    required String userId,
    required int finalLevel,
    required int totalSkillsUsed,
    required int totalDamageDealt,
    required int battleDurationSeconds,
    required bool won,
    required EvolutionType? finalEvolution,
  }) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_battle_summary',
        parameters: {
          'user_id': userId,
          'final_level': finalLevel,
          'total_skills_used': totalSkillsUsed,
          'total_damage_dealt': totalDamageDealt,
          'battle_duration_seconds': battleDurationSeconds,
          'won': won,
          'final_evolution': finalEvolution?.toString().split('.').last,
          'skills_per_minute': (totalSkillsUsed / (battleDurationSeconds / 60.0)).toStringAsFixed(2),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// 進化ボーナスの有効性を記録（ボーナス種別ごとのダメージ増加）
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - evolutionType: 進化タイプ
  /// - bonusPercentage: ボーナス率（0.0-1.0）
  /// - damageIncreasePercent: 実測されたダメージ増加率
  Future<void> logEvolutionBonusEffectiveness(
    String userId,
    EvolutionType evolutionType,
    double bonusPercentage,
    double damageIncreasePercent,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_evolution_bonus_effectiveness',
        parameters: {
          'user_id': userId,
          'evolution_type': evolutionType.toString().split('.').last,
          'bonus_percentage': (bonusPercentage * 100).toStringAsFixed(1),
          'damage_increase_percent': damageIncreasePercent.toStringAsFixed(1),
          'bonus_efficiency':
              (damageIncreasePercent / (bonusPercentage * 100)).toStringAsFixed(2),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// スキル使用パターン分析用の詳細ログ
  ///
  /// 各スキルスロットの使用頻度を記録し、プレイヤーのスキル選択傾向を分析。
  Future<void> logSkillUsagePattern(
    String userId,
    Map<SkillSlot, int> usageCountBySlot,
    Map<SkillSlot, int> totalDamageBySlot,
  ) async {
    try {
      await _analyticsService.logEvent(
        'skill_progression_usage_pattern',
        parameters: {
          'user_id': userId,
          'q_usage_count': usageCountBySlot[SkillSlot.q] ?? 0,
          'r_usage_count': usageCountBySlot[SkillSlot.r] ?? 0,
          'e_usage_count': usageCountBySlot[SkillSlot.e] ?? 0,
          'ult_usage_count': usageCountBySlot[SkillSlot.ult] ?? 0,
          'q_total_damage': totalDamageBySlot[SkillSlot.q] ?? 0,
          'r_total_damage': totalDamageBySlot[SkillSlot.r] ?? 0,
          'e_total_damage': totalDamageBySlot[SkillSlot.e] ?? 0,
          'ult_total_damage': totalDamageBySlot[SkillSlot.ult] ?? 0,
          'total_skill_uses': (usageCountBySlot.values.fold<int>(
                0,
                (sum, count) => sum + count))
              .toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  /// ユーザーの進化選択の傾向を分析（全体統計）
  ///
  /// Parameters:
  /// - offensiveCount: 攻撃を選択した回数
  /// - defensiveCount: 防御を選択した回数
  /// - supportCount: 支援を選択した回数
  /// - autoSelectCount: 自動選択された回数
  Future<void> logEvolutionPreference(
    String userId, {
    required int offensiveCount,
    required int defensiveCount,
    required int supportCount,
    required int autoSelectCount,
  }) async {
    try {
      final total = offensiveCount + defensiveCount + supportCount + autoSelectCount;
      if (total == 0) return;

      await _analyticsService.logEvent(
        'skill_progression_evolution_preference',
        parameters: {
          'user_id': userId,
          'offensive_count': offensiveCount,
          'defensive_count': defensiveCount,
          'support_count': supportCount,
          'auto_select_count': autoSelectCount,
          'offensive_percentage': ((offensiveCount / total) * 100).toStringAsFixed(1),
          'defensive_percentage': ((defensiveCount / total) * 100).toStringAsFixed(1),
          'support_percentage': ((supportCount / total) * 100).toStringAsFixed(1),
          'most_preferred': _getMostPreferredEvolution(
            offensiveCount,
            defensiveCount,
            supportCount,
          ),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }

  String _getMostPreferredEvolution(
    int offensive,
    int defensive,
    int support,
  ) {
    final maxCount = [offensive, defensive, support].reduce((a, b) => a > b ? a : b);
    if (offensive == maxCount) return 'offensive';
    if (defensive == maxCount) return 'defensive';
    return 'support';
  }

  /// スキル進行システムのエラーログ（不正な状態遷移など）
  ///
  /// Parameters:
  /// - userId: プレイヤーID
  /// - errorType: エラーの種類
  /// - errorDetail: エラーの詳細
  Future<void> logSkillProgressionError(
    String userId,
    String errorType,
    String errorDetail,
  ) async {
    try {
      await _analyticsService.recordError(
        Exception(errorType),
        null,
        reason: 'Skill progression error',
        information: 'userId: $userId, type: $errorType, detail: $errorDetail',
      );
    } catch (e) {
      // エラーは無言で処理
    }
  }
}
