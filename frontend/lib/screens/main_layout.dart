import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'scholarships/scholarships_screen.dart';
import '../core/constants.dart';
import '../widgets/common/language_switch.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProfileScreen(),
    const ScholarshipsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: AppConstants.primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0 
                  ? 'Wazifa AI' 
                  : _currentIndex == 1 
                      ? 'Wazifa Profile' 
                      : 'Wazifa Opportunities',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: LanguageSwitch(),
          )
        ],
        backgroundColor: Colors.white,
        elevation: 1,
        bottomOpacity: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed, // Ensure elegant stable look
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: 'Scholarships',
          ),
        ],
      ),
    );
  }
}

