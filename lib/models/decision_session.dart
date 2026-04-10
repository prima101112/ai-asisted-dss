import 'package:json_annotation/json_annotation.dart';
import 'criterion.dart';
import 'alternative.dart';

part 'decision_session.g.dart';

enum DSSMethod {
  @JsonValue('SAW')
  saw,
  @JsonValue('WP')
  wp,
  @JsonValue('AHP')
  ahp,
  @JsonValue('TOPSIS')
  topsis,
}

DSSMethod? dssMethodFromJson(Object? value) {
  if (value == null) return null;
  if (value is DSSMethod) return value;

  switch (value.toString().trim().toUpperCase()) {
    case 'SAW':
      return DSSMethod.saw;
    case 'WP':
      return DSSMethod.wp;
    case 'AHP':
      return DSSMethod.ahp;
    case 'TOPSIS':
      return DSSMethod.topsis;
    default:
      return null;
  }
}

String? dssMethodToJson(DSSMethod? method) {
  switch (method) {
    case DSSMethod.saw:
      return 'SAW';
    case DSSMethod.wp:
      return 'WP';
    case DSSMethod.ahp:
      return 'AHP';
    case DSSMethod.topsis:
      return 'TOPSIS';
    case null:
      return null;
  }
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
  @JsonKey(fromJson: dssMethodFromJson, toJson: dssMethodToJson)
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
