import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  static final _supabase = Supabase.instance.client;

  /// Inserts a new transaction record directly into your PostgreSQL database.
  static Future<void> saveTransaction({
    required double amount,
    required String type, // 'expense' or 'income'
    required int categoryId,
    required String note,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User is not logged in!');
    }

    await _supabase.from('transactions').insert({
      'user_id': userId, // Explicitly pass the ID to satisfy RLS
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'note': note.trim().isEmpty ? 'Uncategorized' : note,
    });
  }
}