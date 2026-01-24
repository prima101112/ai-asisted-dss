import 'package:json_annotation/json_annotation.dart';

part 'alternative.g.dart';

@JsonSerializable(explicitToJson: true)
class Alternative {
  final String id;
  final String name;
  final Map<String, double> scores; // Key is Criterion ID

  Alternative({required this.id, required this.name, required this.scores});

  factory Alternative.fromJson(Map<String, dynamic> json) =>
      _$AlternativeFromJson(json);
  Map<String, dynamic> toJson() => _$AlternativeToJson(this);
}
