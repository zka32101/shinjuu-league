import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';

void main() {
  group('SkillSystemService', () {
    test('神獣のスキル取得', () {
      final skills = SkillSystemService.getSkillsForMecha('mecha_east_01');
      expect(skills.length, 3);
      expect(skills[0].type, SkillType.offensive);
      expect(skills[1].type, SkillType.defensive);
      expect(skills[2].type, SkillType.utility);
    });

    test('スキル定義の取得', () {
      final skill = SkillSystemService.getSkillDefinition('skill_east_01_q');
      expect(skill, isNotNull);
      expect(skill!.name, '焔撃');
      expect(skill.baseCost, 40);
    });

    test('レベルに応じたスキルコスト計算', () {
      final skill = SkillSystemService.getSkillDefinition('skill_east_01_q')!;
      expect(skill.getCostAtLevel(1), 40); // 基本値
      expect(skill.getCostAtLevel(2), 50); // 25%増
      expect(skill.getCostAtLevel(3), 60); // 50%増
    });

    test('レベルに応じたダメージ倍率', () {
      final skill = SkillSystemService.getSkillDefinition('skill_east_01_q')!;
      expect(skill.getDamageMultiplierAtLevel(1), 1.5);
      expect(skill.getDamageMultiplierAtLevel(2), 1.95);
      expect(skill.getDamageMultiplierAtLevel(3), 2.4);
    });

    test('レベルに応じたクールダウン短縮', () {
      final skill = SkillSystemService.getSkillDefinition('skill_east_01_q')!;
      expect(skill.getCooldownAtLevel(1), 4.0);
      expect(skill.getCooldownAtLevel(2), closeTo(3.33, 0.01));
      expect(skill.getCooldownAtLevel(3), closeTo(2.86, 0.01));
    });

    test('ビルド妥当性検証', () {
      final validBuild = SkillBuild(
        skillId1: 'skill_east_01_q',
        skillId2: 'skill_east_01_w',
        skillId3: 'skill_east_01_e',
      );
      expect(
        SkillSystemService.isValidBuild(validBuild, 'mecha_east_01'),
        true,
      );

      final invalidBuild = SkillBuild(
        skillId1: 'skill_west_01_q', // 違う神獣のスキル
        skillId2: 'skill_east_01_w',
        skillId3: 'skill_east_01_e',
      );
      expect(
        SkillSystemService.isValidBuild(invalidBuild, 'mecha_east_01'),
        false,
      );
    });

    test('アイテム取得', () {
      final items = SkillSystemService.getAllItems();
      expect(items.isNotEmpty, true);
      expect(
        items.any((item) => item.itemId == 'item_sword_01'),
        true,
      );
    });

    test('アイテム定義の取得', () {
      final item = SkillSystemService.getItemDefinition('item_sword_01');
      expect(item, isNotNull);
      expect(item!.name, '鋭い剣');
      expect(item.atkBonus, 10);
    });

    test('ステータスボーナス計算', () {
      final bonuses = SkillSystemService.calculateItemBonuses(
        ownedItemIds: ['item_sword_01', 'item_armor_01'],
      );
      expect(bonuses.atk, 10);
      // Note: BaseStats only has hp, atk, spd (no def property)
    });
  });

  group('PlayerResources', () {
    test('マナが十分か判定', () {
      final resources = PlayerResources(
        currentMana: 50,
        maxMana: 100,
        gold: 0,
      );
      expect(resources.canAffordMana(40), true);
      expect(resources.canAffordMana(51), false);
    });

    test('ゴールが十分か判定', () {
      final resources = PlayerResources(
        currentMana: 50,
        maxMana: 100,
        gold: 300,
      );
      expect(resources.canAffordGold(200), true);
      expect(resources.canAffordGold(301), false);
    });

    test('マナ消費', () {
      final resources = PlayerResources(
        currentMana: 100,
        maxMana: 100,
        gold: 0,
      );
      final afterSpend = resources.spendMana(40);
      expect(afterSpend.currentMana, 60);
      expect(afterSpend.maxMana, 100);
    });

    test('ゴール消費（アイテム購入）', () {
      final resources = PlayerResources(
        currentMana: 100,
        maxMana: 100,
        gold: 300,
      );
      final afterSpend = resources.spendGold(200);
      expect(afterSpend.gold, 100);
    });

    test('マナ回復', () {
      final resources = PlayerResources(
        currentMana: 50,
        maxMana: 100,
        gold: 0,
      );
      final afterRegen = resources.regenMana(30);
      expect(afterRegen.currentMana, 80);

      // 最大値を超えない
      final afterRegenMax = afterRegen.regenMana(50);
      expect(afterRegenMax.currentMana, 100);
    });

    test('ゴール獲得', () {
      final resources = PlayerResources(
        currentMana: 100,
        maxMana: 100,
        gold: 100,
      );
      final afterAdd = resources.addGold(150);
      expect(afterAdd.gold, 250);
    });

    test('アイテム購入', () {
      final resources = PlayerResources(
        currentMana: 100,
        maxMana: 100,
        gold: 500,
        ownedItemIds: const [],
      );
      final afterPurchase = resources.purchaseItem('item_sword_01', 300);
      expect(afterPurchase.gold, 200);
      expect(afterPurchase.ownedItemIds.contains('item_sword_01'), true);
      expect(afterPurchase.ownedItemIds.length, 1);
    });

    test('JSON シリアライズ・デシリアライズ', () {
      final resources = PlayerResources(
        currentMana: 75,
        maxMana: 100,
        gold: 250,
        ownedItemIds: ['item_sword_01', 'item_armor_01'],
      );
      final json = resources.toJson();
      final restored = PlayerResources.fromJson(json);

      expect(restored.currentMana, 75);
      expect(restored.maxMana, 100);
      expect(restored.gold, 250);
      expect(restored.ownedItemIds.length, 2);
    });
  });

  group('SkillBuild', () {
    test('スキルアップグレード', () {
      final build = SkillBuild(
        skillId1: 'skill_east_01_q',
        skillId2: 'skill_east_01_w',
        skillId3: 'skill_east_01_e',
        level1: 1,
        level2: 1,
        level3: 1,
      );

      final upgraded = build.upgradeSkill(1);
      expect(upgraded.level1, 2);
      expect(upgraded.level2, 1);
      expect(upgraded.level3, 1);

      // 最大レベルで止まる
      final maxUpgrade = upgraded.upgradeSkill(1).upgradeSkill(1).upgradeSkill(1);
      expect(maxUpgrade.level1, 3);
    });

    test('JSON シリアライズ・デシリアライズ', () {
      final build = SkillBuild(
        skillId1: 'skill_east_01_q',
        skillId2: 'skill_east_01_w',
        skillId3: 'skill_east_01_e',
        level1: 2,
        level2: 1,
        level3: 3,
      );
      final json = build.toJson();
      final restored = SkillBuild.fromJson(json);

      expect(restored.skillId1, 'skill_east_01_q');
      expect(restored.level1, 2);
      expect(restored.level2, 1);
      expect(restored.level3, 3);
    });
  });
}
