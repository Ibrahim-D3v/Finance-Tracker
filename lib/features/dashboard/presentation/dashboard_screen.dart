import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/navigation/main_shell.dart';
import '../../quick_add/presentation/sheets/quick_add_transaction_sheet.dart';
import '../../settings/data/settings_provider.dart';
import '../data/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(dashboardStreamProvider);
    final dailyBudgetLimit = ref.watch(budgetProvider);

    // Fetch Real User Data
    final user = Supabase.instance.client.auth.currentUser;
    final emailPrefix = user?.email?.split('@').first ?? 'User';
    final displayName = emailPrefix.isNotEmpty ? emailPrefix[0].toUpperCase() + emailPrefix.substring(1) : 'User';

    return Scaffold(
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Database Error: $err\nCheck your backend RLS policies.')),
          data: (transactions) {
            double todayExpense = 0.0;
            double foodExpense = 0.0;
            double transitExpense = 0.0;
            double otherExpense = 0.0;

            final now = DateTime.now();

            for (var tx in transactions) {
              if (tx['type'] == 'expense') {
                final txDate = DateTime.parse(tx['created_at']);
                final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;

                if (txDate.year == now.year && txDate.month == now.month && txDate.day == now.day) {
                  todayExpense += amount;
                  final catId = tx['category_id'] as int? ?? 4;
                  if (catId == 1) {
                    foodExpense += amount;
                  } else if (catId == 2) {
                    transitExpense += amount;
                  } else {
                    otherExpense += amount;
                  }
                }
              }
            }

            final safeToSpendToday = (dailyBudgetLimit - todayExpense).clamp(0.0, dailyBudgetLimit);
            final budgetPercent = (todayExpense / dailyBudgetLimit).clamp(0.0, 1.0);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hello, $displayName', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_none_outlined, color: theme.colorScheme.primary),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: isDarkMode
                            ? LinearGradient(colors: [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surfaceContainerHighest])
                            : const LinearGradient(
                          colors: [Color(0xFFC9F0D8), Color(0xFFE4F9EC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SAFE TO SPEND TODAY', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: isDarkMode ? theme.colorScheme.onSurfaceVariant : const Color(0xFF3D4A3E))),
                          const SizedBox(height: 8),
                          Text(
                            '\$${safeToSpendToday.toStringAsFixed(2)}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: isDarkMode ? theme.colorScheme.onSurface : const Color(0xFF191C1D),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: LinearProgressIndicator(
                              value: budgetPercent,
                              minHeight: 8,
                              backgroundColor: isDarkMode ? theme.colorScheme.surface.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${(budgetPercent * 100).toInt()}% of daily budget', style: theme.textTheme.labelSmall?.copyWith(color: isDarkMode ? theme.colorScheme.onSurfaceVariant : const Color(0xFF3D4A3E))),
                              Text('\$${todayExpense.toStringAsFixed(2)} spent', style: theme.textTheme.labelSmall?.copyWith(color: isDarkMode ? theme.colorScheme.onSurfaceVariant : const Color(0xFF3D4A3E))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(child: _buildCategoryBox(context, Icons.restaurant, 'Food', foodExpense, theme.colorScheme.secondaryContainer)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCategoryBox(context, Icons.directions_car, 'Transit', transitExpense, theme.colorScheme.tertiaryContainer)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCategoryBox(context, Icons.more_horiz, 'Other', otherExpense, theme.colorScheme.surfaceContainerHighest)),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Activity', style: theme.textTheme.titleLarge),
                        TextButton(
                          onPressed: () {
                            ref.read(bottomNavIndexProvider.notifier).state = 2;
                          },
                          child: Text('See all', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: transactions.isEmpty
                      ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: Text('No transactions yet. Click Add to begin!')),
                    ),
                  )
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final tx = transactions[index];
                        final isIncome = tx['type'] == 'income';
                        final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                isIncome ? Icons.account_balance_wallet : Icons.shopping_bag_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            title: Text(tx['note'] ?? 'Uncategorized', style: theme.textTheme.titleMedium),
                            subtitle: Text(DateFormat('h:mm a').format(DateTime.parse(tx['created_at'])), style: theme.textTheme.labelSmall),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isIncome ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: transactions.length > 5 ? 5 : transactions.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildCategoryBox(BuildContext context, IconData icon, String title, double amount, Color iconBg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: iconBg.withValues(alpha: 0.3),
            radius: 24,
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('\$${amount.toInt()}', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}