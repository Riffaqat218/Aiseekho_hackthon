import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

class ScholarshipsScreen extends ConsumerStatefulWidget {
  const ScholarshipsScreen({super.key});

  @override
  ConsumerState<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends ConsumerState<ScholarshipsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Map<String, dynamic> _matchedGroups = {};
  bool _isLoading = false;

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
    final groups = await ref.read(apiServiceProvider).getMatchedScholarships();
    
    // Sort and save countries
    setState(() {
      _matchedGroups = groups;
      final countries = _matchedGroups.keys.toList();
      _tabController = TabController(
        length: countries.isEmpty ? 1 : countries.length,
        vsync: this,
      );
      _isLoading = false;
    });
  }

  // Perform Simulated Actions modal
  void _simulateActions(Map<String, dynamic> scholarship) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ActionSimulationSheet(scholarship: scholarship);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final countries = _matchedGroups.keys.toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Matched Scholarships'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScholarships,
          )
        ],
        bottom: countries.isEmpty || _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppConstants.primaryColor,
                tabs: countries.map((c) => Tab(text: c)).toList(),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : countries.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: countries.map((country) {
                    final list = _matchedGroups[country] as List<dynamic>;
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final s = list[index];
                        return _buildScholarshipCard(s);
                      },
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Matched Scholarships Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please complete your student profile first (inside Tab 2: Profile) to scan your marksheet and run the Matching Agent!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholarshipCard(Map<String, dynamic> s) {
    final docs = List<String>.from(s['required_documents']);
    
    return Container(
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
              Text('Min. CGPA Required: ${s['min_cgpa']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Deadline: ${s['deadline']}', style: const TextStyle(color: AppConstants.errorColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          
          Text(
            'Required Checklist:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: docs.map((d) {
              final isTranscript = d.toLowerCase().contains('transcript');
              return Chip(
                avatar: Icon(
                  isTranscript ? Icons.check_circle_rounded : Icons.pending_rounded,
                  size: 14,
                  color: isTranscript ? Colors.green : Colors.orange,
                ),
                label: Text(d, style: const TextStyle(fontSize: 11)),
                backgroundColor: isTranscript ? Colors.green.shade50 : Colors.orange.shade50,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _simulateActions(s),
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text('Apply & Run AI Agent Action Chain'),
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
    );
  }
}

// Sub-component Sheet for Live Action Simulation
class _ActionSimulationSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> scholarship;

  const _ActionSimulationSheet({required this.scholarship});

  @override
  ConsumerState<_ActionSimulationSheet> createState() => _ActionSimulationSheetState();
}

class _ActionSimulationSheetState extends ConsumerState<_ActionSimulationSheet> {
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
