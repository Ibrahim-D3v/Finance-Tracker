import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../dashboard/data/dashboard_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final filterTypeProvider = StateProvider<String>((ref) => 'All');

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(dashboardStreamProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final filterType = ref.watch(filterTypeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
          onPressed: () {},
        ),
        title: Text('FinTrack', style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 24, letterSpacing: -0.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: theme.colorScheme.primary),
            onPressed: () async {
              final transactions = ref.read(dashboardStreamProvider).value;
              if (transactions == null || transactions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export!')));
                return;
              }

              try {
                List<List<dynamic>> rows = [
                  ["Date", "Time", "Type", "Category ID", "Amount", "Note"]
                ];

                for (var tx in transactions) {
                  final dateObj = DateTime.parse(tx['created_at']);
                  rows.add([
                    DateFormat('yyyy-MM-dd').format(dateObj),
                    DateFormat('hh:mm a').format(dateObj),
                    tx['type'],
                    tx['category_id'] ?? 4,
                    tx['amount'],
                    tx['note'] ?? 'Uncategorized'
                  ]);
                }

                String csv = const ListToCsvConverter().convert(rows);

                final directory = await getTemporaryDirectory();
                final path = '${directory.path}/FinTrack_Export_${DateFormat('MMM_yyyy').format(DateTime.now())}.csv';
                final file = File(path);
                await file.writeAsString(csv);

                await Share.shareXFiles([XFile(path)], text: 'My FinTrack Ledger Export');
              } catch (e) {
                // SAFETY CHECK: Ensure the screen is still visible before showing the error
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                    child: TextField(
                      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(12),
                    icon: Icon(Icons.tune, color: theme.colorScheme.primary),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Advanced filters coming soon!'))),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                _buildFilterChip(context, ref, label: 'All', currentFilter: filterType),
                const SizedBox(width: 12),
                _buildFilterChip(context, ref, label: 'Expenses', currentFilter: filterType),
                const SizedBox(width: 12),
                _buildFilterChip(context, ref, label: 'Income', currentFilter: filterType),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (transactions) {
                final filteredList = transactions.where((tx) {
                  final matchesSearch = tx['note'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                  final type = tx['type'].toString();
                  final matchesFilter = filterType == 'All' ||
                      (filterType == 'Expenses' && type == 'expense') ||
                      (filterType == 'Income' && type == 'income');
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }

                final Map<String, List<dynamic>> groupedTransactions = {};
                for (var tx in filteredList) {
                  final date = DateTime.parse(tx['created_at']);
                  final dateHeader = _formatDateHeader(date);
                  if (!groupedTransactions.containsKey(dateHeader)) {
                    groupedTransactions[dateHeader] = [];
                  }
                  groupedTransactions[dateHeader]!.add(tx);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    final dateKey = groupedTransactions.keys.elementAt(index);
                    final dayTransactions = groupedTransactions[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0, bottom: 12.0, left: 4.0),
                          child: Text(
                            dateKey,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...dayTransactions.map((tx) => _buildTransactionCard(context, tx)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    if (dateToCheck == today) return 'TODAY';
    if (dateToCheck == yesterday) return 'YESTERDAY';
    return DateFormat('MMMM d').format(date).toUpperCase();
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, {required String label, required String currentFilter}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSelected = label == currentFilter;

    return GestureDetector(
      onTap: () => ref.read(filterTypeProvider.notifier).state = label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
          borderRadius: BorderRadius.circular(32.0),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> tx) {
    final theme = Theme.of(context);
    final isIncome = tx['type'] == 'income';
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;

    final catId = tx['category_id'] as int? ?? 4;
    Color catBgColor; IconData catIcon; String catName;

    if (isIncome) {
      catBgColor = theme.colorScheme.primaryContainer; catIcon = Icons.payments_outlined; catName = 'Income';
    } else {
      switch (catId) {
        case 1: catBgColor = theme.colorScheme.tertiary; catIcon = Icons.local_cafe_outlined; catName = 'Food & Dining'; break;
        case 2: catBgColor = theme.colorScheme.secondary; catIcon = Icons.directions_car_outlined; catName = 'Transportation'; break;
        case 3: catBgColor = theme.colorScheme.tertiary; catIcon = Icons.shopping_cart_outlined; catName = 'Groceries'; break;
        default: catBgColor = theme.colorScheme.secondary; catIcon = Icons.live_tv_outlined; catName = 'Entertainment';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: catBgColor.withValues(alpha: 0.2), child: Icon(catIcon, color: catBgColor, size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx['note'] ?? 'Uncategorized', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$catName • ${DateFormat('hh:mm a').format(DateTime.parse(tx['created_at']))}', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text('${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: isIncome ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}