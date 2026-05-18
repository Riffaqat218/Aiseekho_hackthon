import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/translations.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/language_switch.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  int _matchedCount = 0;
  int _actionsTaken = 0;
  double _readiness = 0.0;
  List<dynamic> _traces = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final api = ref.read(apiServiceProvider);
    
    final results = await Future.wait([
      api.getProfile(),
      api.getMatchedScholarships(),
      api.getTraces(),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final matchedGroups = (results[1] ?? {}) as Map<String, dynamic>;
    final traces = (results[2] ?? []) as List<dynamic>;

    int matchedCount = 0;
    matchedGroups.forEach((country, list) {
      matchedCount += (list as List).length;
    });

    double readiness = 0.0;
    int actionsTaken = 0;

    if (profile != null) {
      readiness += 0.50; // 50% for creating a profile
      
      // Check if scanned document (Ingestor traces exist)
      final hasIngestor = traces.any((t) => t['step'].toString().toLowerCase().contains('ingestor'));
      if (hasIngestor) readiness += 0.25;

      // Check if action chain run (Actor traces exist)
      final hasActor = traces.any((t) => t['step'].toString().toLowerCase().contains('actor'));
      if (hasActor) {
        readiness += 0.25;
        actionsTaken = 3; // 3 actions simulated in the action chain
      }
    }

    setState(() {
      _profile = profile;
      _matchedCount = matchedCount;
      _actionsTaken = actionsTaken;
      _readiness = readiness;
      _traces = traces;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: AppConstants.primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              Translations.getText('dashboard_title', currentLang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Readiness Score Ring
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _readiness,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade100,
                            color: _readiness >= 1.0 
                                ? Colors.green 
                                : _readiness >= 0.5 
                                    ? AppConstants.secondaryColor 
                                    : Colors.orange,
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(_readiness * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        color: AppConstants.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  _profile == null 
                                      ? Translations.getText('complete_profile_prompt', currentLang) 
                                      : Translations.getText('ready_for_hec', currentLang),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Before vs After Section
                  Text(
                    Translations.getText('agent_impact', currentLang),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: Translations.getText('before_agent', currentLang),
                          value: '0',
                          subtitle: Translations.getText('matched_scholarships', currentLang),
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: Translations.getText('after_agent', currentLang),
                          value: _matchedCount.toString(),
                          subtitle: Translations.getText('matched_scholarships', currentLang),
                          color: AppConstants.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: Translations.getText('actions_simulated', currentLang),
                          value: _actionsTaken.toString(),
                          subtitle: Translations.getText('actions_sub', currentLang),
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  // Educational AI Section
                  Text(
                    currentLang == 'ur' ? 'مصنوعی ذہانت (AI) کے چار ایجنٹس' : '🤖 Wazifa AI Cognitive Suite',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentLang == 'ur' 
                        ? 'جانیں کہ ہماری مصنوعی ذہانت آپ کے اسکالرشپ کے سفر کو کس طرح خودکار بناتی ہے:'
                        : 'Wazifa AI deploys 4 specialized AI Agents to automate and optimize your global scholarship hunt:',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  
                  // Agent 1: Ingestor
                  _buildAgentSuiteCard(
                    context,
                    title: currentLang == 'ur' ? '۱. اے آئی پروفائل اسکینر (Ingestor)' : '1. AI Profile Ingestor (Gemini Vision)',
                    description: currentLang == 'ur' 
                        ? 'اپنے تعلیمی ٹرانسکرپٹ یا رزلٹ کارڈ کی تصویر اپ لوڈ کریں اور ہمارا اے آئی خودکار طور پر آپ کا نام، یونیورسٹی، اور سی جی پی اے نکال لے گا۔'
                        : 'Upload an image of your transcript; our Vision OCR extracts your CGPA, Major, and Institution instantly to auto-fill your profile.',
                    icon: Icons.document_scanner_rounded,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 12),
                  
                  // Agent 2: Matcher
                  _buildAgentSuiteCard(
                    context,
                    title: currentLang == 'ur' ? '۲. سمارٹ اسکالرشپ میچر (Matcher)' : '2. Smart Matcher Agent',
                    description: currentLang == 'ur' 
                        ? 'آپ کی تعلیمی اہلیت کو دنیا بھر کی ہزاروں اسکالرشپس کی ضروریات کے ساتھ سیکنڈوں میں ملا دیتا ہے۔'
                        : 'Aligns your exact academic records against thousands of global scholarship requirements to give you a personalized matched list.',
                    icon: Icons.fact_check_rounded,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 12),
                  
                  // Agent 3: Gap Detector
                  _buildAgentSuiteCard(
                    context,
                    title: currentLang == 'ur' ? '۳. دستاویزی خلا کا پتہ لگانے والا (Gap Radar)' : '3. Gap Detector & Timeline Radar',
                    description: currentLang == 'ur' 
                        ? 'اسکالرشپ کے لیے درکار لاپتہ دستاویزات کی نشاندہی کرتا ہے اور انہیں حاصل کرنے کا درست وقت اور ترجیحات دکھاتا ہے۔'
                        : 'Scans scholarship checklists against your Doc Vault, highlights missing documents, and schedules timelines to obtain them.',
                    icon: Icons.track_changes_rounded,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 12),
                  
                  // Agent 4: Automator
                  _buildAgentSuiteCard(
                    context,
                    title: currentLang == 'ur' ? '۴. اے آئی ایکشن انجن (Actor)' : '4. AI Action & Application Engine',
                    description: currentLang == 'ur' 
                        ? 'خودکار طریقے سے فارم بھرتا ہے، پروفیسرز کے لیے ای میلز تیار کرتا ہے، اور اہم تاریخیں آپ کے کیلنڈر پر درج کرتا ہے۔'
                        : 'Simulates direct actions: auto-fills complex applications, drafts professional recommendation emails to professors, and schedules calendar events.',
                    icon: Icons.bolt_rounded,
                    color: Colors.purple.shade600,
                  ),
                  
                  const SizedBox(height: 32),
                  // Antigravity Live Trace Panel for Judges
                  _buildLiveTracePanel(context, currentLang),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTracePanel(BuildContext context, String currentLang) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusMedium),
                topRight: Radius.circular(AppConstants.borderRadiusMedium),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: AppConstants.secondaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  Translations.getText('live_trace', currentLang),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('RUNNING', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                )
              ],
            ),
          ),
          
          Container(
            height: 250,
            padding: const EdgeInsets.all(12),
            child: _traces.isEmpty
                ? Center(
                    child: Text(
                      Translations.getText('no_traces', currentLang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  )
                : ListView.builder(
                    itemCount: _traces.length,
                    itemBuilder: (context, index) {
                      final t = _traces[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '>> [${t['step']}] tool [${t['tool_called'] ?? 'Agent'}]',
                              style: const TextStyle(color: AppConstants.secondaryColor, fontFamily: 'monospace', fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '   REASONING: ${t['reasoning']}',
                              style: TextStyle(color: Colors.blue.shade200, fontFamily: 'monospace', fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '   RESULT: ${t['result']}',
                              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11),
                            ),
                            const Divider(color: Colors.white10),
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
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
