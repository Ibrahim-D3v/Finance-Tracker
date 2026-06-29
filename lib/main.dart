import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/supabase_config.dart';
import 'core/theme/theme.dart';
import 'features/settings/data/settings_provider.dart';
import 'core/navigation/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    ProviderScope(
      // Pass the loaded preferences into our Riverpod tree
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PennyWiseApp(),
    ),
  );
}

// Changed to ConsumerWidget so it can listen to the Dark Mode state
class PennyWiseApp extends ConsumerWidget {
  const PennyWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the persistent dark mode state
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp(
      title: 'PennyWise',
      debugShowCheckedModeBanner: false,
      theme: PennyWiseTheme.lightTheme,
      darkTheme: PennyWiseTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}