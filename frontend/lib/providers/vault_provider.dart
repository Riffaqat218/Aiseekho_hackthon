import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomDoc {
  final String name;
  final String key;
  final String fileName;
  final bool isUploaded;

  CustomDoc({
    required this.name,
    required this.key,
    required this.fileName,
    this.isUploaded = true,
  });
}

class VaultNotifier extends Notifier<List<CustomDoc>> {
  @override
  List<CustomDoc> build() {
    return [];
  }

  void addDoc(String name, String fileName) {
    final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    // Remove if already exists, then append to avoid duplicates
    state = [
      ...state.where((doc) => doc.key != key),
      CustomDoc(name: name, key: key, fileName: fileName),
    ];
  }

  String _normalize(String s) {
    var val = s.toLowerCase().trim();
    // Common typo and acronym normalization for Pakistani scholarships
    if (val.contains('tofel') || val.contains('toefl')) return 'toefl';
    if (val.contains('ielts') || val.contains('ielts certificate') || val.contains('ielts score')) return 'ielts';
    if (val.contains('cnic') || val.contains('identity') || val.contains('national card') || val.contains('b-form') || val.contains('shanaxti')) return 'cnic';
    if (val.contains('domicile') || val.contains('domicil')) return 'domicile';
    if (val.contains('passport')) return 'passport';
    if (val.contains('transcript') || val.contains('mark') || val.contains('result')) return 'transcript';
    return val;
  }

  bool isAvailable(String docName) {
    final normalizedSearch = _normalize(docName);
    for (final doc in state) {
      final normalizedDocKey = _normalize(doc.key);
      final normalizedDocName = _normalize(doc.name);
      
      if (normalizedSearch == normalizedDocKey ||
          normalizedSearch == normalizedDocName ||
          normalizedSearch.contains(normalizedDocKey) ||
          normalizedDocName.contains(normalizedSearch) ||
          docName.toLowerCase().contains(doc.key) ||
          doc.name.toLowerCase().contains(docName.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, List<CustomDoc>>(VaultNotifier.new);
