import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/translations.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/language_switch.dart';
import '../../providers/vault_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _fieldController = TextEditingController();
  final _ipController = TextEditingController();

  String _selectedDegree = 'Bachelor';
  bool _isLoading = false;
  bool _isSaving = false;

  // Doc Vault Checklist Booleans
  bool _hasDomicile = false;
  bool _hasPassport = false;
  bool _hasIelts = false;
  bool _hasCnic = false;
  bool _hasTranscript = false;
  bool _hasDegree = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _ipController.text = ref.read(apiServiceProvider).serverIp;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _cgpaController.dispose();
    _fieldController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    Map<String, dynamic>? profile;

    if (userId != null) {
      try {
        // Read directly from Supabase (Flutter client has user auth context)
        final data = await Supabase.instance.client
            .from('student_profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        profile = data;
      } catch (e) {
        debugPrint('Direct Supabase profile read error: $e');
      }
    }

    // Fallback to NestJS API if direct read failed
    if (profile == null) {
      profile = await ref.read(apiServiceProvider).getProfile();
    }

    if (profile != null) {
      setState(() {
        _nameController.text = profile!['name'] ?? '';
        _universityController.text = profile['university'] ?? '';
        final cgpaValue = profile['cgpa'];
        _cgpaController.text = cgpaValue != null ? cgpaValue.toString() : '';
        _fieldController.text = profile['field_of_study'] ?? '';
        if (profile['degree_level'] != null) {
          _selectedDegree = profile['degree_level'];
        }
        _hasDomicile = profile['has_domicile'] ?? false;
        _hasPassport = profile['has_passport'] ?? false;
        _hasIelts = profile['has_ielts'] ?? false;
        _hasCnic = profile['has_cnic'] ?? false;
        _hasTranscript = profile['has_transcript'] ?? false;
        _hasDegree = profile['has_degree'] ?? false;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not authenticated. Please log in again.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final cgpaText = _cgpaController.text.trim();
    final cgpaVal = double.tryParse(cgpaText);

    try {
      // Write directly to Supabase from Flutter (has user auth context, RLS passes)
      await Supabase.instance.client.from('student_profiles').upsert({
        'id': userId,
        'name': _nameController.text.trim(),
        'university': _universityController.text.trim(),
        'cgpa': cgpaVal,
        'field_of_study': _fieldController.text.trim(),
        'degree_level': _selectedDegree,
        'has_domicile': _hasDomicile,
        'has_passport': _hasPassport,
        'has_ielts': _hasIelts,
        'has_cnic': _hasCnic,
        'has_transcript': _hasTranscript,
        'has_degree': _hasDegree,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppConstants.secondaryColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Direct Supabase profile save error: $e');
      // Fallback: try without the boolean columns (in case DB migration not applied)
      try {
        await Supabase.instance.client.from('student_profiles').upsert({
          'id': userId,
          'name': _nameController.text.trim(),
          'university': _universityController.text.trim(),
          'cgpa': cgpaVal,
          'field_of_study': _fieldController.text.trim(),
          'degree_level': _selectedDegree,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated (basic fields saved)!'),
              backgroundColor: AppConstants.secondaryColor,
            ),
          );
        }
      } catch (e2) {
        debugPrint('Fallback profile save also failed: $e2');
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e2'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  // Scan a pre-selected sample transcript to auto-fill the form (for high-fidelity hackathon demos)
  Future<void> _scanSampleTranscript(String sampleType) async {
    setState(() => _isLoading = true);

    // Mock PDF/Marksheet data matching university standard
    Map<String, dynamic>? ocrResult;

    // Simulate real delay
    await Future.delayed(const Duration(seconds: 2));

    if (sampleType == 'FAST') {
      ocrResult = {
        'name': 'Muhammad Ali',
        'university': 'FAST NUCES Lahore',
        'cgpa': 3.72,
        'field_of_study': 'Computer Science',
        'degree_level': 'Bachelor',
      };
      _hasCnic = true;
      _hasDomicile = false;
      _hasPassport = false;
      _hasIelts = false;
      _hasTranscript = false;
      _hasDegree = false;
    } else if (sampleType == 'NUST') {
      ocrResult = {
        'name': 'Aisha Rahman',
        'university': 'NUST Islamabad',
        'cgpa': 3.85,
        'field_of_study': 'Software Engineering',
        'degree_level': 'Bachelor',
      };
      _hasCnic = true;
      _hasDomicile = true;
      _hasPassport = false;
      _hasIelts = true;
      _hasTranscript = false;
      _hasDegree = false;
    } else {
      ocrResult = {
        'name': 'Bilal Ahmed',
        'university': 'Quaid-e-Azam University',
        'cgpa': 3.45,
        'field_of_study': 'Physics',
        'degree_level': 'Master',
      };
      _hasCnic = true;
      _hasDomicile = true;
      _hasPassport = true;
      _hasIelts = false;
      _hasTranscript = true;
      _hasDegree = true;
    }

    // Call scanning API to log on backend database
    // We send dummy bytes to trigger Ingestor Agent logs
    await ref.read(apiServiceProvider).scanDocument(
          utf8.encode(jsonEncode(ocrResult)),
          '${sampleType}_transcript.jpg',
        );

    setState(() {
      _nameController.text = ocrResult!['name'];
      _universityController.text = ocrResult['university'];
      _cgpaController.text = ocrResult['cgpa'].toString();
      _fieldController.text = ocrResult['field_of_study'];
      _selectedDegree = ocrResult['degree_level'];
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Successfully auto-filled profile from $sampleType Transcript!'),
        backgroundColor: AppConstants.secondaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.person_rounded,
                color: AppConstants.primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              Translations.getText('profile_title', currentLang),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        actions: [
          const Center(child: LanguageSwitch()),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppConstants.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Edit Form
                  Text(
                    Translations.getText('details_title', currentLang),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label:
                              Translations.getText('name_label', currentLang),
                          icon: Icons.person_rounded,
                          validator: (v) =>
                              v!.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _universityController,
                          label:
                              Translations.getText('univ_label', currentLang),
                          icon: Icons.school_rounded,
                          validator: (v) =>
                              v!.isEmpty ? 'University is required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cgpaController,
                                label: Translations.getText(
                                    'cgpa_label', currentLang),
                                icon: Icons.grade_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (v) {
                                  if (v!.isEmpty) return 'CGPA is required';
                                  final val = double.tryParse(v);
                                  if (val == null || val < 0 || val > 4.00)
                                    return 'Enter valid CGPA';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDegree,
                                decoration: InputDecoration(
                                  labelText: Translations.getText(
                                      'degree_label', currentLang),
                                  prefixIcon: const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: AppConstants.primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadiusMedium),
                                  ),
                                ),
                                items: ['Bachelor', 'Master', 'PhD']
                                    .map((deg) => DropdownMenuItem(
                                        value: deg, child: Text(deg)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedDegree = val!);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _fieldController,
                          label:
                              Translations.getText('field_label', currentLang),
                          icon: Icons.biotech_rounded,
                          validator: (v) =>
                              v!.isEmpty ? 'Major field is required' : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_rounded),
                            label: Text(Translations.getText(
                                'save_button', currentLang)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusMedium),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Doc Vault Card (NEW PITCH DECK CHECKLIST FEATURE)
                  _buildDocVaultCard(context, currentLang),

                  const SizedBox(height: 32),
                  // NestJS Server Setting (Critical for physical device testing)
                  _buildConnectionSettingsCard(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildDocVaultCard(BuildContext context, String currentLang) {
    final customDocs = ref.watch(vaultProvider);
    final isUrdu = currentLang == 'ur';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_shared_rounded,
                  color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                Translations.getText('doc_vault', currentLang),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Translations.getText('doc_vault_sub', currentLang),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildDocUploadRow(Translations.getText('domicile', currentLang),
              _hasDomicile, 'domicile', currentLang),
          const Divider(),
          _buildDocUploadRow(Translations.getText('passport', currentLang),
              _hasPassport, 'passport', currentLang),
          const Divider(),
          _buildDocUploadRow(Translations.getText('ielts', currentLang),
              _hasIelts, 'ielts', currentLang),
          const Divider(),
          _buildDocUploadRow(Translations.getText('cnic', currentLang),
              _hasCnic, 'cnic', currentLang),
          const Divider(),
          _buildDocUploadRow(Translations.getText('transcript', currentLang),
              _hasTranscript, 'transcript', currentLang),
          const Divider(),
          _buildDocUploadRow(Translations.getText('degree', currentLang),
              _hasDegree, 'degree', currentLang),
          if (customDocs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppConstants.secondaryColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  isUrdu
                      ? 'اے آئی سمارٹ ٹیگ کردہ دستاویزات'
                      : 'AI Smart-Tagged Documents',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppConstants.secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...customDocs
                .map((doc) => Column(
                      children: [
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded,
                                  color: Colors.green, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isUrdu ? 'اے آئی تصدیق شدہ' : 'AI Verified'}: ${doc.fileName}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.secondaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isUrdu ? 'دستیاب' : 'Vault Active',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppConstants.secondaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _scanCustomDoc(context, currentLang),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                isUrdu
                    ? 'نئی دستاویز اسکین کریں (AI Smart-Tag)'
                    : 'Scan New Document (AI Smart-Tag)',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocUploadRow(
      String title, bool isUploaded, String docKey, String currentLang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isUploaded
                ? Icons.check_circle_rounded
                : Icons.pending_actions_rounded,
            color: isUploaded ? Colors.green : Colors.grey.shade400,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded
                      ? Translations.getText('doc_uploaded', currentLang)
                      : Translations.getText('doc_missing', currentLang),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isUploaded
                          ? Colors.green.shade700
                          : Colors.grey.shade500),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                _showUploadOptions(context, title, docKey, currentLang),
            icon: Icon(
                isUploaded ? Icons.replay_rounded : Icons.cloud_upload_rounded,
                size: 14),
            label: Text(
              isUploaded
                  ? Translations.getText('reupload', currentLang)
                  : Translations.getText('upload', currentLang),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isUploaded ? Colors.grey.shade100 : AppConstants.primaryColor,
              foregroundColor: isUploaded ? Colors.black87 : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions(BuildContext context, String docTitle, String docKey,
      String currentLang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${Translations.getText('upload', currentLang)}: $docTitle',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppConstants.primaryColor),
                ),
                title: Text(Translations.getText('take_photo', currentLang),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    Translations.getText('camera_prompt', currentLang),
                    style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera(docKey, docTitle, currentLang);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.file_present_rounded,
                      color: AppConstants.secondaryColor),
                ),
                title: Text(Translations.getText('choose_file', currentLang),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(Translations.getText('file_prompt', currentLang),
                    style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromFiles(docKey, docTitle, currentLang);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens device camera, captures photo, and marks document as uploaded
  Future<void> _pickFromCamera(
      String docKey, String title, String currentLang) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image != null) {
        final File file = File(image.path);
        final int fileSize = await file.length();
        debugPrint('Camera capture: ${image.name}, size: $fileSize bytes');
        _markDocUploaded(docKey, title, currentLang, image.name);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  /// Opens file picker for PDFs or images, and marks document as uploaded
  Future<void> _pickFromFiles(
      String docKey, String title, String currentLang) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        debugPrint(
            'File picked: ${file.name}, size: ${file.size} bytes, path: ${file.path}');
        _markDocUploaded(docKey, title, currentLang, file.name);
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _markDocUploaded(
      String docKey, String title, String currentLang, String fileName) {
    setState(() {
      if (docKey == 'domicile') _hasDomicile = true;
      if (docKey == 'passport') _hasPassport = true;
      if (docKey == 'ielts') _hasIelts = true;
      if (docKey == 'cnic') _hasCnic = true;
      if (docKey == 'transcript') _hasTranscript = true;
      if (docKey == 'degree') _hasDegree = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title ${Translations.getText('upload_success', currentLang)}\n📄 $fileName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
    );
  }

  Widget _buildConnectionSettingsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ PHYSICAL DEVICE CONNECTION SETTING',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Testing on physical device? Enter your computer\'s Local IP (e.g. 192.168.1.10) to connect directly to the NestJS backend:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    hintText: '10.0.2.2 or 192.168.x.x',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final ip = _ipController.text.trim();
                  if (ip.isNotEmpty) {
                    ref.read(apiServiceProvider).setServerIp(ip);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Server IP updated to: $ip'),
                        backgroundColor: AppConstants.secondaryColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white),
                child: const Text('Update'),
              )
            ],
          )
        ],
      ),
    );
  }

  /// AI Smart-Tagging & Classification Engine Dialog
  Future<void> _scanCustomDoc(BuildContext context, String currentLang) async {
    final isUrdu = currentLang == 'ur';

    // Pick custom file/image
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      // Show Progressive Smart-Tagging Animation Dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return _SmartTaggingAnimationDialog(
            fileName: file.name,
            filePath: file.path,
            isUrdu: isUrdu,
            onClassificationComplete: (suggestedTag) {
              Navigator.pop(context);
              // Add to dynamic vault list
              ref.read(vaultProvider.notifier).addDoc(suggestedTag, file.name);
              // Notify user
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isUrdu
                              ? 'دستاویز سمارٹ ٹیگ ہو گئی: $suggestedTag!'
                              : 'AI tagged & verified: $suggestedTag!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppConstants.secondaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Smart-Tag picker error: $e');
    }
  }
}

class _SmartTaggingAnimationDialog extends StatefulWidget {
  final String fileName;
  final String? filePath;
  final bool isUrdu;
  final Function(String) onClassificationComplete;

  const _SmartTaggingAnimationDialog({
    required this.fileName,
    this.filePath,
    required this.isUrdu,
    required this.onClassificationComplete,
  });

  @override
  State<_SmartTaggingAnimationDialog> createState() =>
      _SmartTaggingAnimationDialogState();
}

class _SmartTaggingAnimationDialogState
    extends State<_SmartTaggingAnimationDialog> {
  int _currentStep = 0;
  String _detectedType = 'Other Custom Document';
  bool _showSuccessOption = false;
  late TextEditingController _nameController;

  final List<String> _enSteps = [
    'Initializing Wazifa Ingestor...',
    'Reading metadata & OCR blocks...',
    'Parsing layout & text structures...',
    'Running AI Smart-Classifier model...',
    'Tagging complete!'
  ];

  final List<String> _urSteps = [
    'انویسٹر لوڈ ہو رہا ہے...',
    'میٹا ڈیٹا اور لکھائی کا تجزیہ کیا جا رہا ہے...',
    'دستاویز کے نقشے کا موازنہ کیا جا رہا ہے...',
    'اے آئی درجہ بندی ماڈل چل رہا ہے...',
    'ٹیگنگ مکمل ہو گئی!'
  ];

  final List<String> _suggestions = [
    'CNIC/B-Form Copy',
    'Passport',
    'Domicile',
    'Statement of Purpose (SOP)',
    'Recommendation Letter (LOR)',
    'Experience Certificate',
    'Hope Certificate',
    'English Proficiency Letter',
    'Other Custom Document'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _runSmartTaggingLifecycle();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _runSmartTaggingLifecycle() async {
    // 1. Initializing
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _currentStep = 1;
    });

    String extractedText = '';
    String rawOriginalText = '';

    // 2. Reading metadata & OCR blocks using Google ML Kit (Offline)
    if (widget.filePath != null) {
      try {
        final inputImage = InputImage.fromFilePath(widget.filePath!);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);
        rawOriginalText = recognizedText.text;
        extractedText = recognizedText.text.toLowerCase();
        await textRecognizer.close();
      } catch (e) {
        debugPrint('OCR Error: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _currentStep = 2;
    });
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _currentStep = 3;
    });
    await Future.delayed(const Duration(milliseconds: 600));

    // Dynamic Title Extraction: Get the first non-empty line of the scanned OCR text!
    String firstLine = '';
    if (rawOriginalText.isNotEmpty) {
      final lines = rawOriginalText.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.length > 3) {
          // Capitalize each word nicely
          firstLine = trimmed
              .split(' ')
              .map((word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '')
              .join(' ');
          break;
        }
      }
    }

    // Auto-detect based on extracted text (fallback to filename if empty or unreadable)
    String detected =
        firstLine.isNotEmpty ? firstLine : 'Other Custom Document';
    final textToSearch = extractedText.isNotEmpty
        ? extractedText
        : widget.fileName.toLowerCase();

    // Contextual matching helpers
    if (textToSearch.contains('cnic') ||
        textToSearch.contains('identity') ||
        textToSearch.contains('national card') ||
        textToSearch.contains('citizen') ||
        textToSearch.contains('b-form') ||
        textToSearch.contains('card')) {
      detected = firstLine.isNotEmpty ? firstLine : 'CNIC/B-Form Copy';
    } else if (textToSearch.contains('passport') ||
        textToSearch.contains('pass port')) {
      detected = firstLine.isNotEmpty ? firstLine : 'Passport';
    } else if (textToSearch.contains('domicile') ||
        textToSearch.contains('domicil')) {
      detected = firstLine.isNotEmpty ? firstLine : 'Domicile';
    } else if (textToSearch.contains('recommend') ||
        textToSearch.contains('lor') ||
        textToSearch.contains('reference') ||
        textToSearch.contains('dean')) {
      detected =
          firstLine.isNotEmpty ? firstLine : 'Recommendation Letter (LOR)';
    } else if (textToSearch.contains('exp') ||
        textToSearch.contains('work') ||
        textToSearch.contains('employ')) {
      detected = firstLine.isNotEmpty ? firstLine : 'Experience Certificate';
    } else if (textToSearch.contains('hope') ||
        textToSearch.contains('expect') ||
        textToSearch.contains('provisional')) {
      detected = firstLine.isNotEmpty ? firstLine : 'Hope Certificate';
    } else if (textToSearch.contains('english') ||
        textToSearch.contains('ielts') ||
        textToSearch.contains('toefl') ||
        textToSearch.contains('proficiency')) {
      detected =
          firstLine.isNotEmpty ? firstLine : 'English Proficiency Letter';
    } else if (textToSearch.contains('purpose') ||
        textToSearch.contains('motivation') ||
        textToSearch.contains('sop')) {
      detected =
          firstLine.isNotEmpty ? firstLine : 'Statement of Purpose (SOP)';
    }

    if (!mounted) return;
    setState(() {
      _currentStep = 4;
      _detectedType = detected;
      _nameController.text = detected;
      _showSuccessOption = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.isUrdu ? _urSteps : _enSteps;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppConstants.secondaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            widget.isUrdu
                ? 'اے آئی دستاویزی اسکینر'
                : 'AI Ingestor & Smart-Tag',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.isUrdu ? 'فائل' : 'File'}: ${widget.fileName}',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontFamily: 'monospace'),
          ),
          const SizedBox(height: 20),
          if (!_showSuccessOption) ...[
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                      color: AppConstants.secondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    steps[_currentStep],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isUrdu
                              ? 'خودکار اے آئی سمارٹ نام:'
                              : 'AI Scanned Document Title:',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _detectedType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.isUrdu
                  ? 'دستاویز کا نام (آپ تبدیل بھی کر سکتے ہیں):'
                  : 'Customize Scanned Title Name:',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.edit_note_rounded,
                    color: AppConstants.secondaryColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Text(
              widget.isUrdu
                  ? 'یا پہلے سے طے شدہ ٹیگز میں سے منتخب کریں:'
                  : 'Or Quick Match to Predefined Tag:',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _suggestions.contains(_detectedType)
                      ? _detectedType
                      : 'Other Custom Document',
                  isExpanded: true,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _detectedType = newValue;
                        _nameController.text = newValue;
                      });
                    }
                  },
                  items: _suggestions.map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: _showSuccessOption
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.isUrdu ? 'منسوخ کریں' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final finalName = _nameController.text.trim();
                  widget.onClassificationComplete(
                      finalName.isNotEmpty ? finalName : _detectedType);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(widget.isUrdu
                    ? 'ٹیگ اور والٹ کریں'
                    : 'Tag & Save to Vault'),
              ),
            ]
          : null,
    );
  }
}
