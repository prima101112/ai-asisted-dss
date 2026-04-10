import 'package:ai_assisted_dss/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('untitled decision fallback is localized in English and Indonesian', () {
    expect(
      AppLocalizations(const Locale('en')).translate('untitledDecision'),
      'Untitled Decision',
    );
    expect(
      AppLocalizations(const Locale('id')).translate('untitledDecision'),
      'Keputusan Tanpa Judul',
    );
  });
}
