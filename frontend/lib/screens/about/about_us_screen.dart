import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/translations.dart';
import '../../providers/language_provider.dart';

class AboutUsScreen extends ConsumerWidget {
  const AboutUsScreen({super.key});

  // Native OpenAI vision pipeline compilation trigger
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == 'ur';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          isUrdu ? 'ہمارے بارے میں' : 'About Wazifa AI',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner Card with HSL gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    isUrdu ? 'وظیفہ اے آئی' : 'Wazifa AI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUrdu
                        ? 'پاکستان کا پہلا ایجنٹک اسکالرشپ انٹیلیجنس سسٹم'
                        : 'Pakistan\'s First Agentic Scholarship Intelligence System',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // One-Line Pitch Section
            _buildSectionCard(
              context,
              title: isUrdu ? 'ہمارا مقصد' : 'Our Mission',
              icon: Icons.lightbulb_outline_rounded,
              child: Text(
                isUrdu
                    ? '"دوسرے تمام ٹولز پاکستانی طلباء کو صرف یہ بتاتے ہیں کہ کون سی اسکالرشپس دستیاب ہیں۔ وظیفہ کے ایجنٹس آپ کے دستاویزات کو اسکین کرتے ہیں، آپ کی کمیوں کو تلاش کرتے ہیں، آپ کے ای میلز ڈرافٹ کرتے ہیں، آپ کے فارم خودکار بھرتے ہیں، اور ڈیڈ لائن سے پہلے یاد دلاتے ہیں — اردو میں، پاکستان کے لیے، خود بخود۔"'
                    : '"Every other tool tells Pakistani students what scholarships exist. Wazifa\'s agents scan your documents, find your gaps, draft your emails, fill your forms, and remind you before deadlines close — in Urdu, for Pakistan, automatically."',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // How it works Section
            _buildSectionCard(
              context,
              title: isUrdu ? 'یہ کیسے کام کرتا ہے؟' : 'How It Works',
              icon: Icons.settings_suggest_rounded,
              child: Column(
                children: [
                  _buildStepRow(
                    stepNum: '1',
                    title: isUrdu ? 'دستاویز اسکینر (Ingestor)' : 'Document Ingestor',
                    description: isUrdu
                        ? 'آپ کے مارک شیٹ، ٹرانسکریپٹ، آئی ای ایل ٹی ایس کے نتائج کو اسکین کرکے ڈیٹا محفوظ کرتا ہے۔'
                        : 'Extracts your CGPA, degree details, and key metrics directly from photos using Gemini Vision API.',
                  ),
                  const Divider(height: 24),
                  _buildStepRow(
                    stepNum: '2',
                    title: isUrdu ? 'اسکالرشپ میچر (Matcher)' : 'Scholarship Matcher',
                    description: isUrdu
                        ? 'آپ کے پروفائل کو 50 سے زائد پاکستانی اور بین الاقوامی اسکالرشپس سے میچ کرتا ہے۔'
                        : 'Compares your academic history against our pre-seeded database of global opportunities tailored for Pakistan.',
                  ),
                  const Divider(height: 24),
                  _buildStepRow(
                    stepNum: '3',
                    title: isUrdu ? 'گیپ ڈیٹیکٹر (Gap Detector)' : 'Gap Detector',
                    description: isUrdu
                        ? 'ہر اسکالرشپ کے لیے درکار غائب دستاویزات اور ان کے حصول کے وقت کی نشاندہی کرتا ہے۔'
                        : 'Identifies missing documents (like domicile or police NOC) and calculates acquisition times.',
                  ),
                  const Divider(height: 24),
                  _buildStepRow(
                    stepNum: '4',
                    title: isUrdu ? 'ایکشن ایگزیکیوٹر (Actor)' : 'Action Execution Agent',
                    description: isUrdu
                        ? 'سفارشی خط کی ای میلز ڈرافٹ کرتا ہے، فارم خودکار بھرتا ہے، اور ایس او پی لکھتا ہے۔'
                        : 'Drafts emails to professors, generates Statement of Purpose (SOP) openings, and pre-fills mock forms.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hackathon / Team Section
            _buildSectionCard(
              context,
              title: isUrdu ? 'ہمارا وژن' : 'Why We Built This',
              icon: Icons.favorite_border_rounded,
              child: Text(
                isUrdu
                    ? 'ہر سال ہزاروں باصلاحیت پاکستانی طلباء اسکالرشپ کے مواقع گنوا دیتے ہیں کیونکہ معلومات بکھری ہوئی ہیں اور درخواست کے عمل پیچیدہ ہیں۔ وظیفہ اے آئی گوگل کے جدید ترین ایجنٹ سسٹمز (Google Antigravity) اور جیمنائی ماڈلز کی طاقت کا استعمال کرتے ہوئے اس فرق کو پُر کرتا ہے۔'
                    : 'Every year, thousands of talented Pakistani students miss life-changing scholarship opportunities because information is scattered and application processes are confusing. Wazifa AI bridges this gap using state-of-the-art agent orchestration and Google Antigravity reasoning layers.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildStepRow({required String stepNum, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppConstants.secondaryColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
