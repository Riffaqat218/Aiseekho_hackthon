import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (Replace with your actual Supabase URL and Anon Key)
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'YOUR_SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: WazifaApp()));
}

class WazifaApp extends StatelessWidget {
  const WazifaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wazifa AI',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
