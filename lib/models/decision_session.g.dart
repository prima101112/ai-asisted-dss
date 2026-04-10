// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RankingResult _$RankingResultFromJson(Map<String, dynamic> json) =>
    RankingResult(
      alternativeId: json['alternativeId'] as String,
      alternativeName: json['alternativeName'] as String,
      score: (json['score'] as num).toDouble(),
      rank: (json['rank'] as num).toInt(),
    );

Map<String, dynamic> _$RankingResultToJson(RankingResult instance) =>
    <String, dynamic>{
      'alternativeId': instance.alternativeId,
      'alternativeName': instance.alternativeName,
      'score': instance.score,
      'rank': instance.rank,
    };

DecisionSession _$DecisionSessionFromJson(Map<String, dynamic> json) =>
    DecisionSession(
      id: json['id'] as String,
      title: json['title'] as String,
      criteria: (json['criteria'] as List<dynamic>)
          .map((e) => Criterion.fromJson(e as Map<String, dynamic>))
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((e) => Alternative.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedMethod: dssMethodFromJson(json['selectedMethod']),
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => RankingResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculationMatrices: json['calculationMatrices'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'gathering',
    );

Map<String, dynamic> _$DecisionSessionToJson(DecisionSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'criteria': instance.criteria.map((e) => e.toJson()).toList(),
      'alternatives': instance.alternatives.map((e) => e.toJson()).toList(),
      'selectedMethod': dssMethodToJson(instance.selectedMethod),
      'results': instance.results?.map((e) => e.toJson()).toList(),
      'calculationMatrices': instance.calculationMatrices,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': instance.status,
    };

const _$DSSMethodEnumMap = {
  DSSMethod.saw: 'SAW',
  DSSMethod.wp: 'WP',
  DSSMethod.ahp: 'AHP',
  DSSMethod.topsis: 'TOPSIS',
};
