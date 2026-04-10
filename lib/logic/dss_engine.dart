import 'dart:math';
import '../models/criterion.dart';
import '../models/alternative.dart';
import '../models/decision_session.dart';

class CalculationResult {
  final List<RankingResult> rankings;
  final Map<String, dynamic> matrices;

  CalculationResult({required this.rankings, required this.matrices});
}

class DSSEngine {
  static CalculationResult calculate(
    List<Criterion> criteria,
    List<Alternative> alternatives,
    DSSMethod method,
  ) {
    if (alternatives.isEmpty || criteria.isEmpty) {
      return CalculationResult(rankings: [], matrices: {});
    }

    switch (method) {
      case DSSMethod.saw:
        return _calculateSAW(criteria, alternatives);
      case DSSMethod.wp:
        return _calculateWP(criteria, alternatives);
      case DSSMethod.ahp:
        return _calculateAHP(criteria, alternatives);
      case DSSMethod.topsis:
        return _calculateTOPSIS(criteria, alternatives);
    }
  }

  static CalculationResult _calculateSAW(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    // 1. Normalization
    Map<String, Map<String, dynamic>> normalized = {};
    for (var criterion in criteria) {
      double maxVal = alternatives
          .map((e) => e.scores[criterion.id] ?? 0)
          .reduce(max);
      double minVal = alternatives
          .map((e) => e.scores[criterion.id] ?? 0)
          .reduce(min);

      for (var alt in alternatives) {
        normalized[alt.id] ??= {};
        double val = alt.scores[criterion.id] ?? 0;
        if (criterion.type == CriterionType.benefit) {
          normalized[alt.id]![criterion.id] = maxVal == 0 ? 0 : val / maxVal;
        } else {
          normalized[alt.id]![criterion.id] = val == 0 ? 0 : minVal / val;
        }
      }
    }

    // 2. Weighted Sum Matrix
    Map<String, Map<String, dynamic>> weighted = {};
    List<RankingResult> results = alternatives.map((alt) {
      double totalScore = 0;
      weighted[alt.id] ??= {};
      for (var criterion in criteria) {
        double normVal = normalized[alt.id]![criterion.id] as double;
        double weightedVal = normVal * criterion.weight;
        weighted[alt.id]![criterion.id] = weightedVal;
        totalScore += weightedVal;
      }
      return RankingResult(
        alternativeId: alt.id,
        alternativeName: alt.name,
        score: totalScore,
        rank: 0,
      );
    }).toList();

    return CalculationResult(
      rankings: _rankResults(results),
      matrices: {
        "Normalization Matrix": normalized,
        "Weighted Matrix": weighted,
      },
    );
  }

  static CalculationResult _calculateWP(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    double totalWeight = criteria.map((e) => e.weight).reduce((a, b) => a + b);

    // 1. Normalized Weights & S values
    Map<String, Map<String, dynamic>> weightMatrix = {};
    List<double> sValues = alternatives.map((alt) {
      double s = 1.0;
      weightMatrix[alt.id] ??= {};
      for (var criterion in criteria) {
        double w = criterion.weight / totalWeight;
        if (criterion.type == CriterionType.cost) w = -w;
        weightMatrix[alt.id]![criterion.id] = w;
        s *= pow(alt.scores[criterion.id] ?? 1e-9, w);
      }
      return s;
    }).toList();

    double totalS = sValues.reduce((a, b) => a + b);

    List<RankingResult> results = [];
    for (int i = 0; i < alternatives.length; i++) {
      results.add(
        RankingResult(
          alternativeId: alternatives[i].id,
          alternativeName: alternatives[i].name,
          score: totalS == 0 ? 0 : sValues[i] / totalS,
          rank: 0,
        ),
      );
    }

    return CalculationResult(
      rankings: _rankResults(results),
      matrices: {
        "Weight Normalization": weightMatrix,
        "S-Values": {
          for (int i = 0; i < alternatives.length; i++)
            alternatives[i].name: sValues[i],
        },
      },
    );
  }

  static CalculationResult _calculateTOPSIS(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    // 1. Normalize
    Map<String, Map<String, dynamic>> normalized = {};
    for (var criterion in criteria) {
      double divider = sqrt(
        alternatives
            .map((e) => pow(e.scores[criterion.id] ?? 0, 2))
            .reduce((a, b) => a + b),
      );

      for (var alt in alternatives) {
        normalized[alt.id] ??= {};
        double val = alt.scores[criterion.id] ?? 0;
        normalized[alt.id]![criterion.id] =
            (divider == 0 ? 0 : val / divider) * criterion.weight;
      }
    }

    // 2. Ideal & Anti-Ideal
    Map<String, double> ideal = {};
    Map<String, double> antiIdeal = {};

    for (var criterion in criteria) {
      var values = alternatives
          .map((alt) => normalized[alt.id]![criterion.id]! as double)
          .toList();
      if (criterion.type == CriterionType.benefit) {
        ideal[criterion.id] = values.reduce(max);
        antiIdeal[criterion.id] = values.reduce(min);
      } else {
        ideal[criterion.id] = values.reduce(min);
        antiIdeal[criterion.id] = values.reduce(max);
      }
    }

    // 3. Distance & Preference
    List<RankingResult> results = alternatives.map((alt) {
      double dPlus = sqrt(
        criteria
            .map(
              (c) =>
                  pow((normalized[alt.id]![c.id]! as double) - ideal[c.id]!, 2),
            )
            .reduce((a, b) => a + b),
      );
      double dMinus = sqrt(
        criteria
            .map(
              (c) => pow(
                (normalized[alt.id]![c.id]! as double) - antiIdeal[c.id]!,
                2,
              ),
            )
            .reduce((a, b) => a + b),
      );

      double score = (dPlus + dMinus) == 0 ? 0 : dMinus / (dPlus + dMinus);
      return RankingResult(
        alternativeId: alt.id,
        alternativeName: alt.name,
        score: score,
        rank: 0,
      );
    }).toList();

    return CalculationResult(
      rankings: _rankResults(results),
      matrices: {
        "Weighted Normalized Matrix": normalized,
        "Ideal Solutions": ideal,
        "Anti-Ideal Solutions": antiIdeal,
      },
    );
  }

  static CalculationResult _calculateAHP(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    final criteriaPairwise = _buildCriteriaPairwiseMatrix(criteria);
    final criteriaNormalized = _normalizePairwiseMatrix(
      criteriaPairwise,
      criteria.map((criterion) => criterion.id).toList(),
    );
    final criteriaPriority = _averageRows(criteriaNormalized);

    final alternativePriorityByCriterion = <String, Map<String, double>>{};
    final matrices = <String, dynamic>{
      'Criteria Pairwise Matrix': criteriaPairwise,
      'Criteria Normalized Matrix': criteriaNormalized,
      'Criteria Priority Vector': criteriaPriority,
    };

    for (final criterion in criteria) {
      final alternativePairwise = _buildAlternativePairwiseMatrix(
        criterion,
        alternatives,
      );
      final alternativeNormalized = _normalizePairwiseMatrix(
        alternativePairwise,
        alternatives.map((alternative) => alternative.id).toList(),
      );
      final localPriority = _averageRows(alternativeNormalized);

      alternativePriorityByCriterion[criterion.id] = localPriority;
      matrices['${criterion.name} Pairwise Matrix'] = alternativePairwise;
      matrices['${criterion.name} Normalized Matrix'] = alternativeNormalized;
      matrices['${criterion.name} Local Priority'] = localPriority;
    }

    final results = alternatives.map((alternative) {
      double score = 0;
      for (final criterion in criteria) {
        final criterionWeight = criteriaPriority[criterion.id] ?? 0;
        final localPriority =
            alternativePriorityByCriterion[criterion.id]?[alternative.id] ?? 0;
        score += criterionWeight * localPriority;
      }

      return RankingResult(
        alternativeId: alternative.id,
        alternativeName: alternative.name,
        score: score,
        rank: 0,
      );
    }).toList();

    return CalculationResult(
      rankings: _rankResults(results),
      matrices: matrices,
    );
  }

  static Map<String, Map<String, double>> _buildCriteriaPairwiseMatrix(
    List<Criterion> criteria,
  ) {
    final matrix = <String, Map<String, double>>{};
    for (final rowCriterion in criteria) {
      matrix[rowCriterion.id] = <String, double>{};
      for (final columnCriterion in criteria) {
        final rowWeight = _safePositive(rowCriterion.weight);
        final columnWeight = _safePositive(columnCriterion.weight);
        matrix[rowCriterion.id]![columnCriterion.id] = rowWeight / columnWeight;
      }
    }
    return matrix;
  }

  static Map<String, Map<String, double>> _buildAlternativePairwiseMatrix(
    Criterion criterion,
    List<Alternative> alternatives,
  ) {
    final matrix = <String, Map<String, double>>{};
    for (final rowAlternative in alternatives) {
      matrix[rowAlternative.id] = <String, double>{};
      for (final columnAlternative in alternatives) {
        final rowValue = _safePositive(
          rowAlternative.scores[criterion.id] ?? 0,
        );
        final columnValue = _safePositive(
          columnAlternative.scores[criterion.id] ?? 0,
        );

        matrix[rowAlternative.id]![columnAlternative.id] =
            criterion.type == CriterionType.benefit
            ? rowValue / columnValue
            : columnValue / rowValue;
      }
    }
    return matrix;
  }

  static Map<String, Map<String, double>> _normalizePairwiseMatrix(
    Map<String, Map<String, double>> matrix,
    List<String> keys,
  ) {
    final columnTotals = <String, double>{};
    for (final columnKey in keys) {
      columnTotals[columnKey] = keys
          .map((rowKey) => matrix[rowKey]![columnKey] ?? 0)
          .fold(0.0, (sum, value) => sum + value);
    }

    final normalized = <String, Map<String, double>>{};
    for (final rowKey in keys) {
      normalized[rowKey] = <String, double>{};
      for (final columnKey in keys) {
        final total = columnTotals[columnKey] ?? 0;
        final value = matrix[rowKey]![columnKey] ?? 0;
        normalized[rowKey]![columnKey] = total == 0 ? 0 : value / total;
      }
    }
    return normalized;
  }

  static Map<String, double> _averageRows(
    Map<String, Map<String, double>> matrix,
  ) {
    final averages = <String, double>{};
    for (final entry in matrix.entries) {
      if (entry.value.isEmpty) {
        averages[entry.key] = 0;
        continue;
      }
      final total = entry.value.values.fold(0.0, (sum, value) => sum + value);
      averages[entry.key] = total / entry.value.length;
    }
    return averages;
  }

  static double _safePositive(double value) {
    return value <= 0 ? 1e-9 : value;
  }

  static List<RankingResult> _rankResults(List<RankingResult> results) {
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.asMap().entries.map((entry) {
      var res = entry.value;
      return RankingResult(
        alternativeId: res.alternativeId,
        alternativeName: res.alternativeName,
        score: res.score,
        rank: entry.key + 1,
      );
    }).toList();
  }
}
