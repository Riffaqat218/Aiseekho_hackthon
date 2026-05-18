import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/translations.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import 'scholarships_screen.dart'; // To reuse _ActionSimulationSheet

class ScholarshipDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> scholarship;
  final Map<String, dynamic>? profile;

  const ScholarshipDetailsScreen({
    super.key,
    required this.scholarship,
    this.profile,
  });

  bool _isDocAvailable(String docName) {
    if (profile == null) return false;
    final d = docName.toLowerCase();
    if (d.contains('transcript') || d.contains('marksheet')) return profile!['cgpa'] != null;
    if (d.contains('domicile')) return profile!['has_domicile'] ?? false;
    if (d.contains('passport')) return profile!['has_passport'] ?? false;
    if (d.contains('ielts') || d.contains('toefl') || d.contains('english')) return profile!['has_ielts'] ?? false;
    if (d.contains('cnic') || d.contains('identity') || d.contains('card')) return profile!['has_cnic'] ?? false;
    if (d.contains('income') || d.contains('recommendation') || d.contains('finance')) return profile!['has_income'] ?? false;
    return false;
  }

  String _getAcquisitionTimeline(String docName) {
    final d = docName.toLowerCase();
    if (d.contains('domicile')) return '2 weeks';
    if (d.contains('passport')) return '4 weeks';
    if (d.contains('ielts') || d.contains('toefl')) return '3 weeks';
    if (d.contains('cnic')) return '1 week';
    if (d.contains('income')) return '2 weeks';
    return '1 week';
  }

  List<String> _getEligibleUniversities(String scholarshipName) {
    final name = scholarshipName.toLowerCase();
    if (name.contains('fulbright')) {
      return ['NUST Islamabad', 'FAST-NUCES', 'LUMS Lahore', 'Quaid-i-Azam University (QAU)', 'IBS Karachi'];
    } else if (name.contains('heinrich')) {
      return ['Punjab University (PU)', 'NUST Islamabad', 'FAST-NUCES', 'LUMS Lahore'];
    } else if (name.contains('commonwealth')) {
      return ['UET Lahore', 'NUST Islamabad', 'COMSATS Islamabad', 'NED Karachi', 'University of Karachi'];
    } else if (name.contains('chinese') || name.contains('government')) {
      return ['QAU Islamabad', 'Punjab University', 'NUST Islamabad', 'UET Lahore', 'FAST-NUCES'];
    } else if (name.contains('turkiye') || name.contains('burslari')) {
      return ['NUST Islamabad', 'FAST-NUCES', 'UET Peshawar', 'GCU Lahore', 'KU Karachi'];
    } else if (name.contains('indigenous')) {
      return ['All HEC Recognized Public Universities', 'NUST', 'FAST', 'QAU', 'PU', 'UET'];
    } else if (name.contains('peef')) {
      return ['GCU Lahore', 'Punjab University', 'UET Lahore', 'LCWU Lahore', 'KFUEIT Rahim Yar Khan'];
    } else if (name.contains('dawood')) {
      return ['Dawood UET Karachi', 'MUET Jamshoro', 'NED UET Karachi', 'QUEST Nawabshah'];
    }
    // Default universities list
    return ['NUST Islamabad', 'FAST-NUCES', 'Punjab University', 'Quaid-i-Azam University', 'UET Lahore'];
  }

  String _getScholarshipDescription(String scholarshipName) {
    final name = scholarshipName.toLowerCase();
    if (name.contains('fulbright')) {
      return 'The Fulbright Scholarship is a highly prestigious, fully-funded program for Master\'s and PhD studies in the USA. It covers full tuition, textbooks, airfare, a monthly living stipend, and comprehensive health insurance.';
    } else if (name.contains('heinrich')) {
      return 'The Heinrich Böll Foundation offers scholarship opportunities to international students of outstanding academic achievement to pursue undergraduate or postgraduate degrees in top universities across Germany.';
    } else if (name.contains('commonwealth')) {
      return 'Commonwealth Scholarships are funded by the UK Foreign, Commonwealth & Development Office (FCDO) to support talented individuals who have the potential to make a positive impact on the global stage.';
    } else if (name.contains('chinese') || name.contains('government')) {
      return 'The Chinese Government Scholarship (CSC) is a fully-funded initiative that welcomes international students to top-tier Chinese universities. It offers tuition waiver, free on-campus housing, and a monthly allowance.';
    } else if (name.contains('turkiye') || name.contains('burslari')) {
      return 'Turkiye Burslari is a comprehensive, government-funded higher education scholarship program designed for international students to pursue full-time Bachelor, Master, or PhD degrees in top Turkish universities.';
    }
    return 'A premier scholarship opportunity designed to enable outstanding students to pursue world-class education. Covers tuition waivers, academic resources, and living expenses for eligible high-performing applicants.';
  }

  void _simulateActions(BuildContext context, Map<String, dynamic> scholarship) async {
    // Open action simulator modal sheet from scholarships_screen
    Navigator.pop(context); // Close details screen first or just open on top
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ActionSimulationSheet(scholarship: scholarship);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == 'ur';
    final name = scholarship['name'] ?? 'Scholarship';
    final country = scholarship['country'] ?? 'Global';
    final minCgpa = scholarship['min_cgpa'] ?? '3.00';
    final reqDegree = scholarship['required_degree'] ?? 'Master';
    final deadline = scholarship['deadline'] ?? 'TBA';
    final docs = List<String>.from(scholarship['required_documents'] ?? []);
    final universities = _getEligibleUniversities(name);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'اسکالرشپ کی تفصیلات' : 'Scholarship Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Gradient Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          country,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        '${isUrdu ? 'آخری تاریخ' : 'Deadline'}: $deadline',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  Text(
                    isUrdu ? 'خلاصہ' : 'Overview & Benefits',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScholarshipDescription(name),
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Eligibility Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                isUrdu ? 'درکار سی جی پی اے' : 'Min CGPA Required',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$minCgpa / 4.00',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.school_rounded, color: AppConstants.primaryColor, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                isUrdu ? 'تعلیمی سطح' : 'Required Degree',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reqDegree,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Gap Radar / Required Documents Checklist
                  Text(
                    isUrdu ? 'دستاویزی چیک لسٹ (گیپ ریڈار)' : 'Doc Vault Readiness Checklist',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final d = docs[index];
                        final available = _isDocAvailable(d);
                        return Row(
                          children: [
                            Icon(
                              available ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              color: available ? Colors.green : Colors.orange,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    available
                                        ? (isUrdu ? 'تصدیق شدہ اور دستیاب ہے' : 'Available in Vault')
                                        : '${isUrdu ? 'غائب - حاصل کرنے کا وقت' : 'Missing - Acquisition timeline'}: ${_getAcquisitionTimeline(d)}',
                                    style: TextStyle(
                                      color: available ? Colors.green.shade700 : Colors.orange.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Eligible Universities Section
                  Text(
                    isUrdu ? 'شریک پاکستانی یونیورسٹیاں' : 'Participating Universities',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUrdu
                        ? 'وہ اعلیٰ یونیورسٹیاں جہاں طلباء اس اسکالرشپ کے تحت داخلہ حاصل کر سکتے ہیں:'
                        : 'Top institutions in Pakistan whose programs are recognized under this scholarship:',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: universities.map((u) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance_rounded, size: 14, color: AppConstants.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  u,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Apply Button
                  ElevatedButton.icon(
                    onPressed: () => _simulateActions(context, scholarship),
                    icon: const Icon(Icons.bolt, size: 20),
                    label: Text(
                      isUrdu
                          ? 'درخواست دیں اور کارروائی شروع کریں'
                          : 'Apply & Run AI Agent Action Chain',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
