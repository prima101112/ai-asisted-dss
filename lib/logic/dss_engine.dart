import 'dart:math';
import '../models/criterion.dart';
import '../models/alternative.dart';
import '../models/decision_session.dart';

class DSSEngine {
  static List<RankingResult> calculate(
    List<Criterion> criteria,
    List<Alternative> alternatives,
    DSSMethod method,
  ) {
    switch (method) {
      case DSSMethod.saw:
        return _calculateSAW(criteria, alternatives);
      case DSSMethod.wp:
        return _calculateWP(criteria, alternatives);
      case DSSMethod.topsis:
        return _calculateTOPSIS(criteria, alternatives);
    }
  }

  static List<RankingResult> _calculateSAW(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    // 1. Normalization
    Map<String, Map<String, double>> normalized = {};
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

    // 2. Weighted Sum
    List<RankingResult> results = alternatives.map((alt) {
      double totalScore = 0;
      for (var criterion in criteria) {
        totalScore +=
            (normalized[alt.id]![criterion.id] ?? 0) * criterion.weight;
      }
      return RankingResult(
        alternativeId: alt.id,
        alternativeName: alt.name,
        score: totalScore,
        rank: 0,
      );
    }).toList();

    return _rankResults(results);
  }

  static List<RankingResult> _calculateWP(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    double totalWeight = criteria.map((e) => e.weight).reduce((a, b) => a + b);

    // Calculate S value for each alternative
    List<double> sValues = alternatives.map((alt) {
      double s = 1.0;
      for (var criterion in criteria) {
        double w = criterion.weight / totalWeight;
        if (criterion.type == CriterionType.cost) w = -w;
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

    return _rankResults(results);
  }

  static List<RankingResult> _calculateTOPSIS(
    List<Criterion> criteria,
    List<Alternative> alternatives,
  ) {
    // 1. Normalize
    Map<String, Map<String, double>> normalized = {};
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
          .map((alt) => normalized[alt.id]![criterion.id]!)
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
            .map((c) => pow(normalized[alt.id]![c.id]! - ideal[c.id]!, 2))
            .reduce((a, b) => a + b),
      );
      double dMinus = sqrt(
        criteria
            .map((c) => pow(normalized[alt.id]![c.id]! - antiIdeal[c.id]!, 2))
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

    return _rankResults(results);
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
