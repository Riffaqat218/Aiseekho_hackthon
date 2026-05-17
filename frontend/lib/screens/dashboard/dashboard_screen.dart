import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

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
    
    final profile = await api.getProfile();
    final matchedGroups = await api.getMatchedScholarships();
    final traces = await api.getTraces();

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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Readiness Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboardData,
          )
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
                                  _profile == null ? 'Complete Profile' : 'Ready for HEC',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade500,
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
                    'Agent Impact Metrics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'Before Agent',
                          value: '0',
                          subtitle: 'Matched Scholarships',
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          title: 'After Agent',
                          value: _matchedCount.toString(),
                          subtitle: 'Matched Scholarships',
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
                          title: 'Actions Simulated',
                          value: _actionsTaken.toString(),
                          subtitle: 'Fills, Emails, Calendars',
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  // Antigravity Live Trace Panel for Judges
                  _buildLiveTracePanel(context),
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

  Widget _buildLiveTracePanel(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade950,
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
                const Text(
                  'Antigravity Live Agent Trace',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
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
                ? const Center(
                    child: Text(
                      'No agent cycles recorded yet.\nComplete your profile and run an Action Chain to view Antigravity execution steps.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
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
}
