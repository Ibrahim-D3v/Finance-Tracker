import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../dashboard/data/dashboard_provider.dart';

// State provider to make the Timeframe Chips fully interactive
final insightsTimeFilterProvider = StateProvider<String>((ref) => 'This Month');

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(dashboardStreamProvider);
    final timeFilter = ref.watch(insightsTimeFilterProvider);

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
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (transactions) {

          final now = DateTime.now();

          // DYNAMICALLY FILTER DATA BASED ON THE CHIP YOU CLICKED
          final expenses = transactions.where((tx) {
            if (tx['type'] != 'expense') return false;
            final date = DateTime.parse(tx['created_at']);

            if (timeFilter == 'This Week') {
              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
              return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
            } else if (timeFilter == 'This Month') {
              return date.year == now.year && date.month == now.month;
            } else if (timeFilter == '3 Months') {
              final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
              return date.isAfter(threeMonthsAgo);
            } else if (timeFilter == 'Year') {
              return date.year == now.year;
            }
            return true;
          }).toList();

          double totalExpenses = 0;
          Map<int, double> categoryTotals = {1: 0, 2: 0, 3: 0, 4: 0};

          for (var tx in expenses) {
            final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
            final catId = tx['category_id'] as int? ?? 4;

            totalExpenses += amount;
            categoryTotals[catId] = (categoryTotals[catId] ?? 0) + amount;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            children: [
              Text('Spending Insights', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 24),

              // Interactive Timeframe Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTimeChip(context, ref, 'This Week', timeFilter, isDarkMode),
                    const SizedBox(width: 8),
                    _buildTimeChip(context, ref, 'This Month', timeFilter, isDarkMode),
                    const SizedBox(width: 8),
                    _buildTimeChip(context, ref, '3 Months', timeFilter, isDarkMode),
                    const SizedBox(width: 8),
                    _buildTimeChip(context, ref, 'Year', timeFilter, isDarkMode),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildDonutChartCard(context, categoryTotals, totalExpenses),
              const SizedBox(height: 24),
              _buildLineChartCard(context, expenses, isDarkMode),
              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context, WidgetRef ref, String label, String currentFilter, bool isDarkMode) {
    final theme = Theme.of(context);
    final isActive = label == currentFilter;

    return GestureDetector(
      onTap: () => ref.read(insightsTimeFilterProvider.notifier).state = label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChartCard(BuildContext context, Map<int, double> categoryTotals, double total) {
    final theme = Theme.of(context);

    if (total == 0) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: const Text('No expenses recorded in this timeframe.'),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BREAKDOWN', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
                Text('-\$${total.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 75,
                      startDegreeOffset: -90,
                      sections: [
                        _buildPieSection(categoryTotals[2]!, total, theme.colorScheme.secondary),
                        _buildPieSection(categoryTotals[1]!, total, theme.colorScheme.primaryContainer),
                        _buildPieSection(categoryTotals[3]!, total, theme.colorScheme.tertiary),
                        _buildPieSection(categoryTotals[4]!, total, theme.colorScheme.surfaceContainerHighest),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text('\$${(total / 1000).toStringAsFixed(1)}k', style: theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildLegendItem(context, 'Housing', categoryTotals[2]!, total, theme.colorScheme.secondary)),
                Expanded(child: _buildLegendItem(context, 'Food', categoryTotals[1]!, total, theme.colorScheme.primaryContainer)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildLegendItem(context, 'Transport', categoryTotals[3]!, total, theme.colorScheme.tertiary)),
                Expanded(child: _buildLegendItem(context, 'Other', categoryTotals[4]!, total, theme.colorScheme.surfaceContainerHighest)),
              ],
            )
          ],
        ),
      ),
    );
  }

  PieChartSectionData _buildPieSection(double value, double total, Color color) {
    return PieChartSectionData(color: color, value: value, title: '', radius: 24);
  }

  Widget _buildLegendItem(BuildContext context, String title, double value, double total, Color color) {
    final theme = Theme.of(context);
    final percent = total > 0 ? ((value / total) * 100).toInt() : 0;
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text('$percent%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLineChartCard(BuildContext context, List<dynamic> expenses, bool isDarkMode) {
    final theme = Theme.of(context);
    final Map<int, double> dailyTotals = {};

    for (var tx in expenses) {
      final date = DateTime.parse(tx['created_at']);
      final day = date.day;
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + amount;
    }

    final List<FlSpot> realDataSpots = [];
    double maxSpendingInADay = 100.0;

    for (int i = 1; i <= 31; i++) {
      final dailyAmount = dailyTotals[i] ?? 0.0;
      if (dailyAmount > maxSpendingInADay) maxSpendingInADay = dailyAmount;
      realDataSpots.add(FlSpot(i.toDouble(), dailyAmount));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TREND OVER TIME', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value == 1 || value % 5 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(value.toInt().toString(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 1, maxX: 31, minY: 0, maxY: maxSpendingInADay * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: realDataSpots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: isDarkMode ? 0.3 : 0.2),
                            theme.colorScheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}