import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier to hold the current language ('en' for English, 'ur' for Urdu)
class LanguageNotifier extends Notifier<String> {
  @override
  String build() => 'en';

  void toggle() {
    state = state == 'en' ? 'ur' : 'en';
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);
