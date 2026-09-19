// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemBonus _$ItemBonusFromJson(Map<String, dynamic> json) => ItemBonus(
  attackBonus: (json['attackBonus'] as num?)?.toDouble(),
  defenseBonus: (json['defenseBonus'] as num?)?.toDouble(),
  hpBonus: (json['hpBonus'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ItemBonusToJson(ItemBonus instance) => <String, dynamic>{
  'attackBonus': instance.attackBonus,
  'defenseBonus': instance.defenseBonus,
  'hpBonus': instance.hpBonus,
};

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  itemId: json['itemId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$ItemTypeEnumMap, json['type']),
  rarity: $enumDecode(_$ItemRarityEnumMap, json['rarity']),
  bonus: json['bonus'] == null
      ? null
      : ItemBonus.fromJson(json['bonus'] as Map<String, dynamic>),
  purchasePrice: (json['purchasePrice'] as num).toInt(),
  acquiredAt: json['acquiredAt'] == null
      ? null
      : DateTime.parse(json['acquiredAt'] as String),
  isEquipped: json['isEquipped'] as bool? ?? false,
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'itemId': instance.itemId,
  'name': instance.name,
  'description': instance.description,
  'type': _$ItemTypeEnumMap[instance.type]!,
  'rarity': _$ItemRarityEnumMap[instance.rarity]!,
  'bonus': instance.bonus,
  'purchasePrice': instance.purchasePrice,
  'acquiredAt': instance.acquiredAt?.toIso8601String(),
  'isEquipped': instance.isEquipped,
};

const _$ItemTypeEnumMap = {
  ItemType.weapon: 'weapon',
  ItemType.armor: 'armor',
  ItemType.charm: 'charm',
};

const _$ItemRarityEnumMap = {
  ItemRarity.common: 'common',
  ItemRarity.rare: 'rare',
  ItemRarity.epic: 'epic',
  ItemRarity.legend: 'legend',
};
