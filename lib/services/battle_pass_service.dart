import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battlepass_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// バトルパスの進行（試合ごとの進捗加算）とタイア報酬の受け取りを一手に管理する。
///
/// 元々 `BattlePassScreen` はプレミアムパス購入時に `progress: 0` の
/// `BattlePass` ドキュメントを作るだけで、その後は試合を何戦しても
/// progress を増やす処理がどこにも存在しなかった（購入しても永久に
/// 全タイアロックのまま）。さらに各タイアは progress の閾値を超えると
/// 「解除済み」表示にはなるが、実際にジェム/スキンをユーザーへ付与する
/// 仕組み自体が無かった（SeasonRewardService.claimRewards()と同根の
/// 「記録するだけで何も渡さない」バグ）。このサービスで両方を解消する。
class BattlePassService {
  final FirestoreService _firestoreService;

  /// 1試合終了ごとに加算する進捗（0-100、10タイア×10）。
  /// 10試合でフルタイア解放というペース — 「気軽な5分で本気のチーム戦」という
  /// Visionに沿って、1シーズンのうちに無理なく遊び切れる速度に設定。
  static const progressPerBattle = 10;

  /// 無課金タイア（3の倍数以外）のジェム報酬額。
  static const _gemsPerFreeTier = 50;

  BattlePassService(this._firestoreService);

  /// 試合終了後に呼ばれる想定。まだ今シーズンのBattlePassドキュメントが
  /// 無いユーザー（F2P・未購読）にも無課金トラックの進捗を記録するため、
  /// 無ければ非プレミアムの新規ドキュメントとして作成する。
  Future<void> addProgressForBattle(String userId) async {
    final existing = await _firestoreService.getBattlePass(
      userId,
      AppConfig.currentSeasonId,
    );
    final base = existing ?? _createFreeTierPass(userId);
    final newProgress = (base.progress + progressPerBattle).clamp(0, 100);
    if (newProgress == base.progress && existing != null) return;

    await _firestoreService.saveBattlePass(_withProgress(base, newProgress));
  }

  /// 指定タイアの報酬を受け取る。
  /// - progress がそのタイアの閾値（tier*10）未満なら失敗
  /// - 既に受け取り済みなら失敗
  /// - 3の倍数タイア（プレミアム限定スキン）はプレミアムパス未加入だと失敗
  Future<bool> claimTier(String userId, int tier) async {
    final pass = await _firestoreService.getBattlePass(
      userId,
      AppConfig.currentSeasonId,
    );
    if (pass == null) return false;
    if (pass.progress < tier * 10) return false;
    if (pass.claimedRewards.any((r) => r.tier == tier)) return false;

    final isPremiumTier = tier % 3 == 0;
    if (isPremiumTier && !pass.isPremium) return false;

    final reward = isPremiumTier
        ? BattlePassReward(
            rewardId: 'bp_${pass.seasonId}_tier${tier}_skin',
            type: RewardType.skin,
            name: 'Tier $tier 限定スキン',
            tier: tier,
            isPremium: true,
          )
        : BattlePassReward(
            rewardId: 'bp_${pass.seasonId}_tier${tier}_gems',
            type: RewardType.gems,
            name: 'Tier $tier ジェム',
            tier: tier,
            isPremium: false,
          );

    if (reward.type == RewardType.gems) {
      await _firestoreService.incrementUserGems(userId, _gemsPerFreeTier);
    } else {
      await _firestoreService.addUserCosmetic(userId, reward.rewardId);
    }

    final updated = BattlePass(
      seasonId: pass.seasonId,
      userId: pass.userId,
      progress: pass.progress,
      level: pass.level,
      claimedRewards: [...pass.claimedRewards, reward],
      isPremium: pass.isPremium,
      startDate: pass.startDate,
      endDate: pass.endDate,
    );
    await _firestoreService.saveBattlePass(updated);
    return true;
  }

  BattlePass _createFreeTierPass(String userId) {
    final now = DateTime.now();
    return BattlePass(
      seasonId: AppConfig.currentSeasonId,
      userId: userId,
      progress: 0,
      level: 1,
      claimedRewards: const [],
      isPremium: false,
      startDate: now,
      endDate: now.add(const Duration(days: 90)),
    );
  }

  BattlePass _withProgress(BattlePass pass, int progress) {
    return BattlePass(
      seasonId: pass.seasonId,
      userId: pass.userId,
      progress: progress,
      level: pass.level,
      claimedRewards: pass.claimedRewards,
      isPremium: pass.isPremium,
      startDate: pass.startDate,
      endDate: pass.endDate,
    );
  }
}
