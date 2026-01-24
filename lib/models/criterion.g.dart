// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'criterion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Criterion _$CriterionFromJson(Map<String, dynamic> json) => Criterion(
  id: json['id'] as String,
  name: json['name'] as String,
  weight: (json['weight'] as num).toDouble(),
  type: $enumDecode(_$CriterionTypeEnumMap, json['type']),
);

Map<String, dynamic> _$CriterionToJson(Criterion instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'weight': instance.weight,
  'type': _$CriterionTypeEnumMap[instance.type]!,
};

const _$CriterionTypeEnumMap = {
  CriterionType.benefit: 'benefit',
  CriterionType.cost: 'cost',
};
