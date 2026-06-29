import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. SharedPreferences Instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialized in main.dart');
});

// 2. Dark Mode State
class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('darkMode') ?? false;
  }

  void toggle(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('darkMode', value);
  }
}
final darkModeProvider = NotifierProvider<DarkModeNotifier, bool>(() => DarkModeNotifier());

// 3. Notifications State
class NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('notifications') ?? true;
  }

  void toggle(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('notifications', value);
  }
}
final notificationsProvider = NotifierProvider<NotificationsNotifier, bool>(() => NotificationsNotifier());

// 4. Currency State
class CurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('currency') ?? 'USD (\$)';
  }

  void updateCurrency(String newCurrency) {
    state = newCurrency;
    ref.read(sharedPreferencesProvider).setString('currency', newCurrency);
  }
}
final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() => CurrencyNotifier());

// 5. Live Profile Stream
// 5. Live Profile Stream (Upgraded with Self-Healing)
final profileProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  final supabase = Supabase.instance.client;

  final authSub = supabase.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.tokenRefreshed || data.event == AuthChangeEvent.signedIn) {
      ref.invalidateSelf();
    }
  });

  ref.onDispose(() => authSub.cancel());

  final user = supabase.auth.currentUser;
  if (user == null) {
    yield {};
    return;
  }

  // Await token refresh if currently expired
  if (supabase.auth.currentSession != null && supabase.auth.currentSession!.isExpired) {
    try {
      await supabase.auth.refreshSession();
    } catch (_) {}
  }

  final stream = supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id);

  await for (final list in stream) {
    yield list.isNotEmpty ? list.first : {};
  }
});
// 6. Dynamic Daily Budget State
class BudgetNotifier extends Notifier<double> {
  @override
  double build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getDouble('daily_budget') ?? 200.0;
  }

  void updateBudget(double newBudget) {
    state = newBudget;
    ref.read(sharedPreferencesProvider).setDouble('daily_budget', newBudget);
  }
}
final budgetProvider = NotifierProvider<BudgetNotifier, double>(() => BudgetNotifier());