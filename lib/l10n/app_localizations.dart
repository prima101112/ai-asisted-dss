import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'AI Decision Assistant',
      'tagline': 'Make smarter decisions with AI',
      'signInGoogle': 'Sign in with Google',
      'signInCancelled': 'Sign in was cancelled',
      'signInFailed': 'Failed to sign in. Please try again.',
      'termsText':
          'By signing in, you agree to our Terms of Service\nand Privacy Policy',
      'newChat': 'New Chat',
      'history': 'History',
      'signOut': 'Sign Out',
      'user': 'User',
      'welcome': 'Welcome',
      'welcomeMessage':
          "Hello! I'm your AI decision assistant. What would you like to decide today?",
      'welcomeBackMessage':
          "Welcome back! I've loaded your previous decision data. How can I help you?",
      'helloGreeting': 'Hi',
      'whatHelp': 'What decision do you need help with?',
      'typeMessage': 'Type your message...',
      'useAgain': 'Use Again',
      'criteria': 'Criteria',
      'alternatives': 'Alternatives',
      'rankings': 'Rankings',
      'method': 'Method',
      'language': 'Language',
      'english': 'English',
      'indonesian': 'Indonesian',
      'decisionInsights': 'Decision Insights',
      'currentStatus': 'Current Status',
      'gathering': 'GATHERING',
      'ready': 'READY',
      'calculated': 'CALCULATED',
      'title': 'Title',
      'defined': 'defined',
      'selectMethod': 'Select Calculation Method:',
      'calculationSteps': 'Calculation Steps',

      'alternative': 'Alternative',
      'score': 'Score',
      'gatherMoreInfo': 'Gather more info or select a method to see results.',
      'startConversation': 'Start a conversation to gather decision data.',
      'menu': 'Menu',
      'smartDss': 'Smart DSS',
      'chooseBestOption': 'Choose best option',
      'chooseBestOptionPrompt':
          'I want to compare several options and find the best one',
      'jobCareer': 'Job or career decision',
      'jobCareerPrompt': 'I need help deciding between job opportunities',
      'purchaseDecision': 'Purchase decision',
      'purchaseDecisionPrompt':
          'I want to compare products before making a purchase',
      'locationPlace': 'Location or place',
      'locationPlacePrompt': 'I need help choosing between different locations',
      'businessStrategy': 'Business strategy',
      'businessStrategyPrompt':
          'I want to evaluate business strategies or investments',
      'somethingElse': 'Something else',
      'somethingElsePrompt': 'I have a decision to make',
      'benefit': 'Benefit (Higher is better)',
      'cost': 'Cost (Lower is better)',

      'criteriaHeader': 'Criteria',
      'alternativesHeader': 'Alternatives',
      'rankingsHeader': 'Rankings',
      'methodsHeader': 'Methods',
      'decisionHistory': 'Decision History',
      'noHistory': 'No decision history yet',
      'startNewDecision': 'Start New Decision',
      'errorLoading': 'Error loading history',
      'best': 'Best',
      'decisionDetail': 'Decision Detail',
      'completed': 'Completed',
      'readyToCalculate': 'Ready to Calculate',
      'inProgress': 'In Progress',
      'criteriaDetails': 'Criteria Details',
      'useDataAgain': 'Use This Data Again',
      'showLess': 'Show less',
      'showMore': 'Show {count} more',
      'rank': 'Rank',
      'rankNum': 'Rank #{rank}',
      'benefitDescription': 'Benefit (Higher is better)',
      'costDescription': 'Cost (Lower is better)',
      'weight': 'Weight',
      'scoreCount': '{count} scores',
      'theme': 'Theme',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'systemTheme': 'System',
      'delete': 'Delete',
      'deleteConfirm': 'Delete Decision',
      'deleteConfirmMsg':
          'Are you sure you want to delete this decision? This action cannot be undone.',
      'cancel': 'Cancel',
      'untitledDecision': 'Untitled Decision',
    },
    'id': {
      'appTitle': 'Asisten Keputusan AI',
      'tagline': 'Buat keputusan lebih cerdas dengan AI',
      'signInGoogle': 'Masuk dengan Google',
      'signInCancelled': 'Masuk dibatalkan',
      'signInFailed': 'Gagal masuk. Silakan coba lagi.',
      'termsText':
          'Dengan masuk, Anda menyetujui Ketentuan Layanan\ndan Kebijakan Privasi kami',
      'newChat': 'Chat Baru',
      'history': 'Riwayat',
      'signOut': 'Keluar',
      'user': 'Pengguna',
      'welcome': 'Selamat Datang',
      'welcomeMessage':
          'Halo! Saya asisten keputusan AI Anda. Apa yang ingin Anda putuskan hari ini?',
      'welcomeBackMessage':
          'Selamat kembali! Saya telah memuat data keputusan Anda sebelumnya. Ada yang bisa saya bantu?',
      'helloGreeting': 'Hai',
      'whatHelp': 'Keputusan apa yang perlu dibantu?',
      'typeMessage': 'Ketik pesan Anda...',
      'useAgain': 'Gunakan Lagi',
      'criteria': 'Kriteria',
      'alternatives': 'Alternatif',
      'rankings': 'Peringkat',
      'method': 'Metode',
      'language': 'Bahasa',
      'english': 'Inggris',
      'indonesian': 'Indonesia',
      'decisionInsights': 'Wawasan Keputusan',
      'currentStatus': 'Status Saat Ini',
      'gathering': 'MENGUMPULKAN',
      'ready': 'SIAP',
      'calculated': 'TERHITUNG',
      'title': 'Judul',
      'defined': 'terdefinisi',
      'selectMethod': 'Pilih Metode Perhitungan:',
      'calculationSteps': 'Langkah Perhitungan',

      'alternative': 'Alternatif',
      'score': 'Skor',
      'gatherMoreInfo':
          'Kumpulkan info lagi atau pilih metode untuk melihat hasil.',
      'startConversation':
          'Mulai percakapan untuk mengumpulkan data keputusan.',
      'menu': 'Menu',
      'smartDss': 'Smart DSS',
      'chooseBestOption': 'Pilih opsi terbaik',
      'chooseBestOptionPrompt':
          'Saya ingin membandingkan beberapa opsi dan menemukan yang terbaik',
      'jobCareer': 'Keputusan pekerjaan/karir',
      'jobCareerPrompt':
          'Saya butuh bantuan untuk memutuskan di antara beberapa peluang kerja',
      'purchaseDecision': 'Keputusan pembelian',
      'purchaseDecisionPrompt':
          'Saya ingin membandingkan beberapa produk sebelum membeli',
      'locationPlace': 'Lokasi atau tempat',
      'locationPlacePrompt':
          'Saya butuh bantuan memilih di antara beberapa lokasi',
      'businessStrategy': 'Strategi bisnis',
      'businessStrategyPrompt':
          'Saya ingin mengevaluasi strategi bisnis atau investasi',
      'somethingElse': 'Lainnya',
      'somethingElsePrompt': 'Saya punya keputusan yang perlu dibuat',
      'benefit': 'Benefit (Lebih tinggi lebih baik)',
      'cost': 'Cost (Lebih rendah lebih baik)',

      'criteriaHeader': 'Kriteria',
      'alternativesHeader': 'Alternatif',
      'rankingsHeader': 'Peringkat',
      'methodsHeader': 'Metode',
      'decisionHistory': 'Riwayat Keputusan',
      'noHistory': 'Belum ada riwayat keputusan',
      'startNewDecision': 'Mulai Keputusan Baru',
      'errorLoading': 'Gagal memuat riwayat',
      'best': 'Terbaik',
      'decisionDetail': 'Detail Keputusan',
      'completed': 'Selesai',
      'readyToCalculate': 'Siap Dihitung',
      'inProgress': 'Dalam Proses',
      'criteriaDetails': 'Detail Kriteria',
      'useDataAgain': 'Gunakan Data Ini Lagi',
      'showLess': 'Tampilkan lebih sedikit',
      'showMore': 'Tampilkan {count} lagi',
      'rank': 'Peringkat',
      'rankNum': 'Peringkat #{rank}',
      'benefitDescription': 'Benefit (Lebih tinggi lebih baik)',
      'costDescription': 'Cost (Lebih rendah lebih baik)',
      'weight': 'Bobot',
      'scoreCount': '{count} nilai',
      'theme': 'Tema',
      'lightTheme': 'Terang',
      'darkTheme': 'Gelap',
      'systemTheme': 'Sistem',
      'delete': 'Hapus',
      'deleteConfirm': 'Hapus Keputusan',
      'deleteConfirmMsg':
          'Apakah Anda yakin ingin menghapus keputusan ini? Tindakan ini tidak dapat dibatalkan.',
      'cancel': 'Batal',
      'untitledDecision': 'Keputusan Tanpa Judul',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
