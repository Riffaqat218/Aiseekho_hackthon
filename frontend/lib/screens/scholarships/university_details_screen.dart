import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';

class UniversityDetailsScreen extends ConsumerWidget {
  final String universityName;

  const UniversityDetailsScreen({super.key, required this.universityName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == 'ur';

    // Mock data for demonstration
    final location = universityName.contains('(') 
        ? universityName.split('(')[1].replaceAll(')', '') 
        : 'Global';
    
    final ranking = (universityName.length % 100) + 10; // fake deterministic ranking
    final isFullyFunded = true; // Typically fully funded through these partner scholarships

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(isUrdu ? 'یونیورسٹی کی تفصیلات' : 'University Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.account_balance_rounded, size: 40, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    universityName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          location,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Cards
            Text(
              isUrdu ? 'اہم معلومات' : 'Key Information',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.monetization_on_rounded,
                    title: isUrdu ? 'فنڈنگ کی قسم' : 'Funding Type',
                    value: isFullyFunded ? (isUrdu ? 'مکمل فنڈڈ' : 'Fully Funded') : (isUrdu ? 'جزوی فنڈڈ' : 'Partially Funded'),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.public_rounded,
                    title: isUrdu ? 'عالمی درجہ بندی' : 'Global Ranking',
                    value: 'Top $ranking',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.menu_book_rounded,
              title: isUrdu ? 'پروگرامز' : 'Programs Offered',
              value: isUrdu ? 'بیچلر، ماسٹر، پی ایچ ڈی' : 'Bachelor, Master, PhD',
              color: Colors.orange,
            ),
            const SizedBox(height: 24),

            // About Section
            Text(
              isUrdu ? 'یونیورسٹی کے بارے میں' : 'About the University',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                isUrdu
                    ? 'یہ ایک عالمی معیار کی یونیورسٹی ہے جو جدید تحقیق اور اعلیٰ تعلیم کے مواقع فراہم کرتی ہے۔ یہ بین الاقوامی طلباء کے لیے ایک بہترین انتخاب ہے۔'
                    : 'This is a world-class institution known for cutting-edge research and outstanding academic opportunities. It remains a top choice for international scholars seeking excellence.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),

            // Visit Website Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isUrdu ? 'ویب سائٹ جلد آرہی ہے' : 'Website redirection coming soon'),
                      backgroundColor: AppConstants.secondaryColor,
                    ),
                  );
                },
                icon: const Icon(Icons.language_rounded),
                label: Text(
                  isUrdu ? 'یونیورسٹی کی ویب سائٹ دیکھیں' : 'Visit Official Website',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppConstants.primaryColor,
                  elevation: 0,
                  side: const BorderSide(color: AppConstants.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
