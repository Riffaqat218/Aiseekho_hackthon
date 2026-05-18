import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/translations.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import 'scholarship_details_screen.dart';

class ScholarshipsScreen extends ConsumerStatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  ConsumerState<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends ConsumerState<ScholarshipsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Map<String, dynamic> _matchedGroups = {};
  bool _isLoading = false;

  // Explore All Scholarships State
  List<dynamic> _allScholarships = [];
  List<dynamic> _filteredAllScholarships = [];
  String _selectedCountryFilter = 'All';
  List<String> _allCountries = ['All'];
  int _selectedMainTab = 0; // 0 for Matched, 1 for Explore All

  // Profile Documents State for dynamic Gap Radar
  Map<String, dynamic>? _profile;
  bool _hasCnic = false;
  bool _hasDomicile = false;
  bool _hasPassport = false;
  bool _hasIelts = false;
  bool _hasIncome = false;
  bool _hasTranscript = false;

  @override
  void initState() {
    super.initState();
    _loadScholarships();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadScholarships() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    final api = ref.read(apiServiceProvider);

    List<dynamic> allList = [];
    Map<String, dynamic>? profile;
    Map<String, dynamic> groups = {};

    // 1. Load all scholarships directly from Supabase (public read RLS)
    try {
      final data = await supabase
          .from('scholarships')
          .select()
          .order('country', ascending: true);
      allList = data as List<dynamic>;
    } catch (e) {
      debugPrint('Direct Supabase scholarships read error: $e');
      // Fallback to NestJS API
      try {
        allList = await api.getAllScholarships();
      } catch (_) {}
    }

    // 2. Load profile directly from Supabase
    if (userId != null) {
      try {
        profile = await supabase
            .from('student_profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      } catch (e) {
        debugPrint('Direct Supabase profile read error: $e');
        profile = await api.getProfile();
      }
    }

    // 3. Build matched groups from allList + profile
    if (profile != null && allList.isNotEmpty) {
      final userCgpa = double.tryParse(profile['cgpa']?.toString() ?? '0') ?? 0;
      final matched = allList.where((s) {
        final minCgpa = double.tryParse(s['min_cgpa']?.toString() ?? '99') ?? 99;
        return userCgpa >= minCgpa;
      }).toList();

      for (final s in matched) {
        final country = s['country']?.toString() ?? 'Other';
        groups[country] ??= [];
        (groups[country] as List).add(s);
      }
    } else {
      // Try backend API fallback for matched
      try {
        groups = await api.getMatchedScholarships();
      } catch (_) {}
    }

    setState(() {
      _matchedGroups = groups;
      _profile = profile;
      _allScholarships = allList;
      _filteredAllScholarships = allList;

      // Extract unique countries
      final countriesSet = allList.map((s) => s['country'].toString()).toSet();
      _allCountries = ['All', ...countriesSet];
      _selectedCountryFilter = 'All';

      if (profile != null) {
        _hasCnic = profile['has_cnic'] ?? false;
        _hasDomicile = profile['has_domicile'] ?? false;
        _hasPassport = profile['has_passport'] ?? false;
        _hasIelts = profile['has_ielts'] ?? false;
        _hasIncome = profile['has_income'] ?? false;
        _hasTranscript = profile['cgpa'] != null;
      }
      final countries = _matchedGroups.keys.toList();
      _tabController = TabController(
        length: countries.isEmpty ? 1 : countries.length,
        vsync: this,
      );
      _isLoading = false;
    });
  }

  void _applyCountryFilter(String country) {
    setState(() {
      _selectedCountryFilter = country;
      if (country == 'All') {
        _filteredAllScholarships = _allScholarships;
      } else {
        _filteredAllScholarships = _allScholarships.where((s) => s['country'] == country).toList();
      }
    });
  }

  // Perform Simulated Actions modal
  void _simulateActions(Map<String, dynamic> scholarship) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ActionSimulationSheet(scholarship: scholarship);
      },
    );
  }

  bool _isDocAvailable(String docName) {
    final d = docName.toLowerCase();
    if (d.contains('transcript') || d.contains('marksheet')) return _hasTranscript;
    if (d.contains('domicile')) return _hasDomicile;
    if (d.contains('passport')) return _hasPassport;
    if (d.contains('ielts') || d.contains('toefl') || d.contains('english')) return _hasIelts;
    if (d.contains('cnic') || d.contains('identity') || d.contains('card')) return _hasCnic;
    if (d.contains('income') || d.contains('recommendation') || d.contains('finance')) return _hasIncome;
    return false;
  }

  String _getAcquisitionTimeline(String docName) {
    final d = docName.toLowerCase();
    if (d.contains('domicile')) return '2 wks';
    if (d.contains('passport')) return '4 wks';
    if (d.contains('ielts') || d.contains('toefl')) return '3 wks';
    if (d.contains('cnic')) return '1 wk';
    if (d.contains('income')) return '2 wks';
    return '1 wk';
  }

  Widget _buildMainTabSelector(String currentLang) {
    final isUrdu = currentLang == 'ur';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMainTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 0 ? AppConstants.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  Translations.getText('matched_scholarships', currentLang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedMainTab == 0 ? Colors.white : Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMainTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 1 ? AppConstants.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isUrdu ? 'تمام اسکالرشپس' : 'Explore All',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedMainTab == 1 ? Colors.white : Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedTabContent(String currentLang) {
    final countries = _matchedGroups.keys.toList();
    if (countries.isEmpty) {
      return _buildEmptyState(currentLang);
    }
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppConstants.primaryColor,
          tabs: countries.map((c) => Tab(text: c)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: countries.map((country) {
              final list = _matchedGroups[country] as List<dynamic>;
              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final s = list[index];
                  return _buildScholarshipCard(s, currentLang);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreAllTabContent(String currentLang) {
    final isUrdu = currentLang == 'ur';
    if (_allScholarships.isEmpty) {
      return _buildEmptyState(currentLang);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge, vertical: 8),
          child: Row(
            children: _allCountries.map((c) {
              final isSelected = _selectedCountryFilter == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(c == 'All' ? (isUrdu ? 'تمام' : 'All') : c),
                  selected: isSelected,
                  onSelected: (_) => _applyCountryFilter(c),
                  selectedColor: AppConstants.primaryColor.withOpacity(0.15),
                  checkmarkColor: AppConstants.primaryColor,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppConstants.primaryColor : Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _filteredAllScholarships.isEmpty
              ? Center(
                  child: Text(
                    isUrdu ? 'کوئی اسکالرشپ نہیں ملی' : 'No scholarships found for this filter',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  itemCount: _filteredAllScholarships.length,
                  itemBuilder: (context, index) {
                    final s = _filteredAllScholarships[index];
                    return _buildScholarshipCard(s, currentLang);
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(Translations.getText('scholarship_title', currentLang)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScholarships,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : Column(
              children: [
                _buildMainTabSelector(currentLang),
                Expanded(
                  child: _selectedMainTab == 0
                      ? _buildMatchedTabContent(currentLang)
                      : _buildExploreAllTabContent(currentLang),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(String currentLang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              Translations.getText('empty_scholarships', currentLang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholarshipCard(Map<String, dynamic> s, String currentLang) {
    final docs = List<String>.from(s['required_documents']);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScholarshipDetailsScreen(
              scholarship: s,
              profile: _profile,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primaryColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppConstants.secondaryColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    s['country'],
                    style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                const Icon(Icons.grade_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${Translations.getText('min_cgpa', currentLang)}: ${s['min_cgpa']}', 
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12)
                ),
                const Spacer(),
                const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${Translations.getText('deadline', currentLang)}: ${s['deadline']}', 
                  style: const TextStyle(color: AppConstants.errorColor, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const Divider(height: 24),
            
            Text(
              Translations.getText('gap_radar', currentLang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.primaryColor),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: docs.map((d) {
                final available = _isDocAvailable(d);
                return Chip(
                  avatar: Icon(
                    available ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    size: 14,
                    color: available ? Colors.green : Colors.orange,
                  ),
                  label: Text(
                    available ? '$d (Available)' : '$d (Missing - Timeline: ${_getAcquisitionTimeline(d)})', 
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)
                  ),
                  backgroundColor: available ? Colors.green.shade50 : Colors.orange.shade50,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _simulateActions(s),
              icon: const Icon(Icons.bolt, size: 18),
              label: Text(Translations.getText('apply_button', currentLang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sub-component Sheet for Live Action Simulation
class ActionSimulationSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> scholarship;

  const ActionSimulationSheet({required this.scholarship, super.key});

  @override
  ConsumerState<ActionSimulationSheet> createState() => ActionSimulationSheetState();
}

class ActionSimulationSheetState extends ConsumerState<ActionSimulationSheet> {
  bool _isRunning = true;
  String _currentStep = 'Initializing Orchestrator...';
  List<dynamic> _logs = [];
  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _executeSimulation();
  }

  Future<void> _executeSimulation() async {
    // 1. Trigger Simulation
    final res = await ref.read(apiServiceProvider).runActionEngine(widget.scholarship['id']);
    
    // Simulate beautiful progressive typing delays in UI for high trace fidelity
    if (res != null && res['success'] == true) {
      final backendTraces = res['traces'] as List<dynamic>;
      for (final trace in backendTraces) {
        setState(() {
          _currentStep = trace['step'];
          _logs.add(trace);
        });
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      
      setState(() {
        _results = res;
        _isRunning = false;
      });
    } else {
      setState(() {
        _currentStep = 'Failed to execute agent workflows.';
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined, color: AppConstants.primaryColor, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Antigravity Action Engine',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simulating 3-5 multi-step application actions for ${widget.scholarship['name']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Divider(height: 32),

                  // Simulation Log View
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.secondaryColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AGENT STATE: $_currentStep',
                              style: const TextStyle(color: AppConstants.secondaryColor, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        ..._logs.map((log) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '[${log['step']}] calling tool [${log['tool_called'] ?? 'AgentLogic'}]',
                                style: const TextStyle(color: Colors.blueAccent, fontFamily: 'monospace', fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${log['result']}',
                                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isRunning && _results != null) ...[
                    // Output Action 1: Mock Form
                    _buildOutcomeCard(
                      title: 'Action 1: Auto-filled Application Form',
                      icon: Icons.assignment_turned_in_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Scholarship', _results!['simulatedForm']['scholarshipName']),
                          _buildDetailRow('Applicant Name', _results!['simulatedForm']['applicantName']),
                          _buildDetailRow('University', _results!['simulatedForm']['previousInstitution']),
                          _buildDetailRow('CGPA', _results!['simulatedForm']['cgpa'].toString()),
                          _buildDetailRow('Major', _results!['simulatedForm']['major']),
                          _buildDetailRow('Completeness', _results!['simulatedForm']['completeness']),
                          _buildDetailRow('Status', _results!['simulatedForm']['applicationStatus']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Output Action 2: Professor Email
                    _buildOutcomeCard(
                      title: 'Action 2: Letter of Recommendation Request Email',
                      icon: Icons.email_rounded,
                      content: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          _results!['draftedEmail'],
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey.shade800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Output Action 3: Calendar
                    _buildOutcomeCard(
                      title: 'Action 3: Deadline Calendar Scheduled',
                      icon: Icons.calendar_today_rounded,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Event Title', _results!['calendarEvent']['title']),
                          _buildDetailRow('Deadline Date', _results!['calendarEvent']['deadline']),
                          _buildDetailRow('Description', _results!['calendarEvent']['description']),
                          _buildDetailRow('Alert Priority', 'Scheduled (7 days before)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Output Action 4: Simulated AI Statement of Purpose (SOP) Paragraph
                    _buildOutcomeCard(
                      title: 'Action 4: Simulated AI SOP Intro Generator',
                      icon: Icons.article_rounded,
                      content: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "As a dedicated graduate in ${_results!['simulatedForm']['major'] ?? 'Software Engineering'} from ${_results!['simulatedForm']['previousInstitution'] ?? 'NUST Islamabad'} with a CGPA of ${_results!['simulatedForm']['cgpa']?.toString() ?? '3.85'}, my academic excellence and research drive inspire my aspiration to pursue advanced studies in this field. Securing the prestigious ${widget.scholarship['name'] ?? 'Fulbright Scholarship'} represents the ideal catalyst to align my background with impactful global solutions, contributing directly to technological progress in Pakistan.",
                          style: const TextStyle(fontFamily: 'serif', fontSize: 12, height: 1.45, fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Simulated actions complete! Check Tab 1: Dashboard for updated scores.'),
                              backgroundColor: AppConstants.secondaryColor,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.secondaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium)),
                        ),
                        child: const Text('Back to matched list', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeCard({required String title, required IconData icon, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
