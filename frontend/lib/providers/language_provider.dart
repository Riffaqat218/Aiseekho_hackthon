import 'package:flutter_riverpod/flutter_riverpod.dart';

// State Provider to hold the current language ('en' for English, 'ur' for Urdu)
final languageProvider = StateProvider<String>((ref) => 'en');
