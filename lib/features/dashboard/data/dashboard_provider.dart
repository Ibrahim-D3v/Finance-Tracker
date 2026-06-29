import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final supabase = Supabase.instance.client;

  // 1. AUTO-HEAL: If Supabase refreshes the token in the background, automatically reboot this stream
  final authSub = supabase.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.tokenRefreshed || data.event == AuthChangeEvent.signedIn) {
      ref.invalidateSelf();
    }
  });

  // Clean up the listener when the provider dies
  ref.onDispose(() => authSub.cancel());

  // 2. COLD BOOT FIX: If the app opens and the token is already expired, force a refresh BEFORE connecting
  if (supabase.auth.currentSession != null && supabase.auth.currentSession!.isExpired) {
    try {
      await supabase.auth.refreshSession();
    } catch (_) {
      // Ignore network errors here; the auth listener will gracefully kick them out if the token is completely dead
    }
  }

  // 3. Connect to the Live Database Stream safely
  final stream = supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  // 4. Yield the incoming data continuously to the UI
  await for (final data in stream) {
    yield data;
  }
});