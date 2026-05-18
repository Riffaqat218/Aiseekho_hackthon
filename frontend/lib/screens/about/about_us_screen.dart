import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';

class AboutUsScreen extends ConsumerWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == 'ur';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'ہمارے بارے میں' : 'About Wazifa AI'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Educational AI Section moved from dashboard
            Text(
              isUrdu ? 'مصنوعی ذہانت (AI) کے چار ایجنٹس' : '🤖 Wazifa AI Cognitive Suite',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isUrdu 
                  ? 'جانیں کہ ہماری مصنوعی ذہانت آپ کے اسکالرشپ کے سفر کو کس طرح خودکار بناتی ہے:'
                  : 'Wazifa AI deploys 4 specialized AI Agents to automate and optimize your global scholarship hunt:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            // Agent 1: Ingestor
            _buildAgentSuiteCard(
              context,
              title: isUrdu ? '۱. اے آئی پروفائل اسکینر (Ingestor)' : '1. AI Profile Ingestor (Gemini Vision)',
              description: isUrdu 
                  ? 'اپنے تعلیمی ٹرانسکرپٹ یا رزلٹ کارڈ کی تصویر اپ لوڈ کریں اور ہمارا اے آئی خودکار طور پر آپ کا نام، یونیورسٹی، اور سی جی پی اے نکال لے گا۔'
                  : 'Upload an image of your transcript; our Vision OCR extracts your CGPA, Major, and Institution instantly to auto-fill your profile.',
              icon: Icons.document_scanner_rounded,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 12),
            
            // Agent 2: Matcher
            _buildAgentSuiteCard(
              context,
              title: isUrdu ? '۲. سمارٹ اسکالرشپ میچر (Matcher)' : '2. Smart Matcher Agent',
              description: isUrdu 
                  ? 'آپ کی تعلیمی اہلیت کو دنیا بھر کی ہزاروں اسکالرشپس کی ضروریات کے ساتھ سیکنڈوں میں ملا دیتا ہے۔'
                  : 'Aligns your exact academic records against thousands of global scholarship requirements to give you a personalized matched list.',
              icon: Icons.fact_check_rounded,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            
            // Agent 3: Gap Detector
            _buildAgentSuiteCard(
              context,
              title: isUrdu ? '۳. دستاویزی خلا کا پتہ لگانے والا (Gap Radar)' : '3. Gap Detector & Timeline Radar',
              description: isUrdu 
                  ? 'اسکالرشپ کے لیے درکار لاپتہ دستاویزات کی نشاندہی کرتا ہے اور انہیں حاصل کرنے کا درست وقت اور ترجیحات دکھاتا ہے۔'
                  : 'Scans scholarship checklists against your Doc Vault, highlights missing documents, and schedules timelines to obtain them.',
              icon: Icons.track_changes_rounded,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 12),
            
            // Agent 4: Automator
            _buildAgentSuiteCard(
              context,
              title: isUrdu ? '۴. اے آئی ایکشن انجن (Actor)' : '4. AI Action & Application Engine',
              description: isUrdu 
                  ? 'خودکار طریقے سے فارم بھرتا ہے، پروفیسرز کے لیے ای میلز تیار کرتا ہے، اور اہم تاریخیں آپ کے کیلنڈر پر درج کرتا ہے۔'
                  : 'Simulates direct actions: auto-fills complex applications, drafts professional recommendation emails to professors, and schedules calendar events.',
              icon: Icons.bolt_rounded,
              color: Colors.purple.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentSuiteCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border(
          left: BorderSide(color: color, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
