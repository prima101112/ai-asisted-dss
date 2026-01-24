import 'package:json_annotation/json_annotation.dart';

part 'criterion.g.dart';

enum CriterionType {
  @JsonValue('benefit')
  benefit,
  @JsonValue('cost')
  cost,
}

@JsonSerializable()
class Criterion {
  final String id;
  final String name;
  final double weight;
  final CriterionType type;

  Criterion({
    required this.id,
    required this.name,
    required this.weight,
    required this.type,
  });

  factory Criterion.fromJson(Map<String, dynamic> json) => _$CriterionFromJson(json);
  Map<String, dynamic> toJson() => _$CriterionToJson(this);
}
