import 'package:flutter/material.dart';
import '../../core/constants.dart';

class MilestonesScreen extends StatelessWidget {
  final Map<String, dynamic> calendarEvent;

  const MilestonesScreen({super.key, required this.calendarEvent});

  @override
  Widget build(BuildContext context) {
    final title = calendarEvent['title'] ?? 'Scholarship Deadline Roadmap';
    final deadlineDate = calendarEvent['deadline'] ?? 'November 15, 2026';
    final description = calendarEvent['description'] ?? '';

    // Generate dynamic milestones based on description or default list
    final List<Map<String, String>> milestones = [
      {
        'title': 'Scan & Verify Documents',
        'date': 'Completed',
        'desc': 'All academic profiles and credentials successfully scanned and extracted.',
        'status': 'done',
      },
      {
        'title': 'Obtain Missing Domicile Certificate',
        'date': '2 weeks before deadline',
        'desc': 'Apply at local district office. Urgent priority gap identified by Wazifa AI.',
        'status': 'pending',
      },
      {
        'title': 'Secure 2 Letters of Recommendation',
        'date': '1 week before deadline',
        'desc': 'Draft recommendation request emails to professors (pre-filled email sent).',
        'status': 'pending',
      },
      {
        'title': 'Submit SOP & Final Application',
        'date': deadlineDate,
        'desc': 'Submit the auto-filled application form on HEC/USEFP online portal.',
        'status': 'final',
      },
    ];

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Milestone Roadmap',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            // Calendar header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, Color(0xFF1E3C72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.date_range_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Final Deadline: $deadlineDate',
                    style: const TextStyle(
                      color: AppConstants.secondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Timeline title
            const Text(
              'APPLICATION SEQUENCE STEPS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Timeline ListView
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: milestones.length,
                itemBuilder: (context, index) {
                  final m = milestones[index];
                  final isDone = m['status'] == 'done';
                  final isFinal = m['status'] == 'final';

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line & Dot indicator
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDone 
                                  ? Colors.green.shade100 
                                  : isFinal 
                                      ? AppConstants.primaryColor.withOpacity(0.1) 
                                      : Colors.amber.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDone 
                                    ? Colors.green 
                                    : isFinal 
                                        ? AppConstants.primaryColor 
                                        : Colors.amber,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isDone 
                                  ? Icons.check 
                                  : isFinal 
                                      ? Icons.flag_rounded 
                                      : Icons.alarm_rounded,
                              size: 14,
                              color: isDone 
                                  ? Colors.green.shade800 
                                  : isFinal 
                                      ? AppConstants.primaryColor 
                                      : Colors.amber.shade800,
                            ),
                          ),
                          if (index < milestones.length - 1)
                            Container(
                              width: 2,
                              height: 60,
                              color: Colors.grey.shade300,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Step details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['title']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['desc']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDone 
                                      ? Colors.green.shade50 
                                      : isFinal 
                                          ? AppConstants.primaryColor.withOpacity(0.05) 
                                          : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m['date']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isDone 
                                        ? Colors.green.shade700 
                                        : isFinal 
                                            ? AppConstants.primaryColor 
                                            : Colors.amber.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
