import 'package:json_annotation/json_annotation.dart';
import 'criterion.dart';
import 'alternative.dart';

part 'decision_session.g.dart';

enum DSSMethod {
  @JsonValue('SAW')
  saw,
  @JsonValue('WP')
  wp,
  @JsonValue('TOPSIS')
  topsis,
}

@JsonSerializable()
class RankingResult {
  final String alternativeId;
  final String alternativeName;
  final double score;
  final int rank;

  RankingResult({
    required this.alternativeId,
    required this.alternativeName,
    required this.score,
    required this.rank,
  });

  factory RankingResult.fromJson(Map<String, dynamic> json) =>
      _$RankingResultFromJson(json);
  Map<String, dynamic> toJson() => _$RankingResultToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DecisionSession {
  final String id;
  final String title;
  final List<Criterion> criteria;
  final List<Alternative> alternatives;
  final DSSMethod? selectedMethod;
  final List<RankingResult>? results;
  final Map<String, dynamic>? calculationMatrices;
  final DateTime createdAt;
  final String status; // 'gathering', 'ready', 'calculated'

  DecisionSession({
    required this.id,
    required this.title,
    required this.criteria,
    required this.alternatives,
    this.selectedMethod,
    this.results,
    this.calculationMatrices,
    required this.createdAt,
    this.status = 'gathering',
  });

  factory DecisionSession.fromJson(Map<String, dynamic> json) =>
      _$DecisionSessionFromJson(json);
  Map<String, dynamic> toJson() => _$DecisionSessionToJson(this);
}
