import 'package:ai_assisted_dss/models/decision_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecisionSession JSON', () {
    test('decodes AHP selectedMethod from stored history data', () {
      final session = DecisionSession.fromJson({
        'id': 'history-ahp',
        'title': 'Pilih Laptop',
        'criteria': [],
        'alternatives': [],
        'selectedMethod': 'AHP',
        'createdAt': '2026-04-10T12:00:00.000Z',
        'status': 'calculated',
      });

      expect(session.selectedMethod, DSSMethod.ahp);
    });

    test('keeps unknown selectedMethod values from crashing history loads', () {
      final session = DecisionSession.fromJson({
        'id': 'history-unknown',
        'title': 'Pilih Laptop',
        'criteria': [],
        'alternatives': [],
        'selectedMethod': 'UNKNOWN',
        'createdAt': '2026-04-10T12:00:00.000Z',
        'status': 'calculated',
      });

      expect(session.selectedMethod, isNull);
    });
  });
}
