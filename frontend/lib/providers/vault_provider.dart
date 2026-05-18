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
    // Initial pre-loaded custom items to demonstrate dynamic smart-tagging
    return [
      CustomDoc(name: 'Statement of Purpose (SOP)', key: 'sop', fileName: 'sop_fast_graduate.pdf'),
      CustomDoc(name: 'Recommendation Letter (LOR)', key: 'lor', fileName: 'lor_dean_computers.pdf'),
    ];
  }

  void addDoc(String name, String fileName) {
    final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    // Remove if already exists, then append to avoid duplicates
    state = [
      ...state.where((doc) => doc.key != key),
      CustomDoc(name: name, key: key, fileName: fileName),
    ];
  }

  bool isAvailable(String docName) {
    final search = docName.toLowerCase();
    for (final doc in state) {
      if (search.contains(doc.key) || 
          search.contains(doc.name.toLowerCase()) || 
          doc.name.toLowerCase().contains(search)) {
        return true;
      }
    }
    return false;
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, List<CustomDoc>>(VaultNotifier.new);
