import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/ai/trace_panel.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Doc Vault'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera Scan Placeholder Area
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Mock Camera Viewfinder Overlay
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppConstants.secondaryColor, width: 2),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                  ),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white54, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Align Document within Frame',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 20,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.document_scanner),
                      label: const Text('Scan & Ingest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Ingested Documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: [
                  _buildDocCard(
                    context,
                    title: 'University Transcript',
                    status: 'Extracted: CGPA 3.8',
                    icon: Icons.school_rounded,
                  ),
                  _buildDocCard(
                    context,
                    title: 'Passport Copy',
                    status: 'Extracted: Name, DOB',
                    icon: Icons.flight_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: const TracePanel(),
    );
  }

  Widget _buildDocCard(BuildContext context, {required String title, required String status, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppConstants.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: AppConstants.secondaryColor),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
