import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ExpenseService _expenseService = ExpenseService();

  DateTime _startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _startOfNextMonth(DateTime date) {
    if (date.month == 12) {
      return DateTime(date.year + 1, 1, 1);
    }

    return DateTime(date.year, date.month + 1, 1);
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatAmount(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  List<Expense> _getCurrentMonthExpenses(
    List<Expense> expenses,
  ) {
    final now = DateTime.now();
    final start = _startOfMonth(now);
    final end = _startOfNextMonth(now);

    return expenses.where((expense) {
      return !expense.date.isBefore(start) &&
          expense.date.isBefore(end);
    }).toList();
  }

  double _calculateTotal(List<Expense> expenses) {
    return expenses.fold(
      0,
      (total, expense) => total + expense.amount,
    );
  }

  Map<String, double> _calculateCategoryTotals(
    List<Expense> expenses,
  ) {
    final Map<String, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) +
              expense.amount;
    }

    return categoryTotals;
  }

  Map<String, double> _calculateMonthlyTotals(
    List<Expense> expenses,
  ) {
    final Map<String, double> monthlyTotals = {};

    for (final expense in expenses) {
      final key =
          '${expense.date.year}-${expense.date.month}';

      monthlyTotals[key] =
          (monthlyTotals[key] ?? 0) + expense.amount;
    }

    return monthlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: _expenseService.getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const _StatisticsLoadingState();
            }

            if (snapshot.hasError) {
              return _StatisticsErrorState(
                error: snapshot.error,
              );
            }

            final expenses = snapshot.data ?? [];

            if (expenses.isEmpty) {
              return const _EmptyStatisticsState();
            }

            final currentMonthExpenses =
                _getCurrentMonthExpenses(expenses);

            final currentMonthTotal =
                _calculateTotal(currentMonthExpenses);

            final currentMonthTransactionCount =
                currentMonthExpenses.length;

            final categoryTotals =
                _calculateCategoryTotals(
              currentMonthExpenses,
            );

            final monthlyTotals =
                _calculateMonthlyTotals(expenses);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _StatisticsHeader(
                        month:
                            '${_monthName(now.month)} ${now.year}',
                      ),

                      const SizedBox(height: 22),

                      LayoutBuilder(
                        builder: (
                          context,
                          constraints,
                        ) {
                          final isWide =
                              constraints.maxWidth >= 600;

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Total Spending',
                                    value: _formatAmount(
                                      currentMonthTotal,
                                    ),
                                    subtitle: 'This month',
                                    icon: Icons
                                        .account_balance_wallet_outlined,
                                    iconColor:
                                        AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _SummaryCard(
                                    title: 'Transactions',
                                    value:
                                        '$currentMonthTransactionCount',
                                    subtitle: 'This month',
                                    icon: Icons
                                        .receipt_long_outlined,
                                    iconColor:
                                        AppColors.success,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              _SummaryCard(
                                title: 'Total Spending',
                                value: _formatAmount(
                                  currentMonthTotal,
                                ),
                                subtitle: 'This month',
                                icon: Icons
                                    .account_balance_wallet_outlined,
                                iconColor:
                                    AppColors.primary,
                              ),
                              const SizedBox(height: 14),
                              _SummaryCard(
                                title: 'Transactions',
                                value:
                                    '$currentMonthTransactionCount',
                                subtitle: 'This month',
                                icon: Icons
                                    .receipt_long_outlined,
                                iconColor:
                                    AppColors.success,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      const _SectionHeader(
                        title: 'Category Spending',
                        subtitle:
                            'See where your money goes this month.',
                      ),

                      const SizedBox(height: 12),

                      _CategorySpendingChart(
                        categoryTotals: categoryTotals,
                      ),

                      const SizedBox(height: 30),

                      const _SectionHeader(
                        title: 'Category Summary',
                        subtitle:
                            'A breakdown of your monthly spending.',
                      ),

                      const SizedBox(height: 12),

                      if (categoryTotals.isEmpty)
                        const _NoCurrentMonthData()
                      else
                        ...categoryTotals.entries.map(
                          (entry) {
                            final double percentage =
                                currentMonthTotal == 0
                                    ? 0.0
                                    : (entry.value /
                                            currentMonthTotal) *
                                        100.0;

                            return _CategorySummaryItem(
                              category: entry.key,
                              amount: entry.value,
                              percentage: percentage,
                            );
                          },
                        ),

                      const SizedBox(height: 30),

                      const _SectionHeader(
                        title: 'Monthly Spending',
                        subtitle:
                            'Track how your spending changes over time.',
                      ),

                      const SizedBox(height: 12),

                      _MonthlySpendingChart(
                        monthlyTotals: monthlyTotals,
                      ),

                      const SizedBox(height: 30),

                      const _SectionHeader(
                        title: 'Monthly Summary',
                        subtitle:
                            'Your total spending for each month.',
                      ),

                      const SizedBox(height: 12),

                      ...monthlyTotals.entries.map(
                        (entry) {
                          final parts =
                              entry.key.split('-');

                          final year =
                              int.parse(parts[0]);

                          final month =
                              int.parse(parts[1]);

                          return _MonthlySummaryItem(
                            month:
                                '${_monthName(month)} $year',
                            amount: entry.value,
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatisticsHeader extends StatelessWidget {
  final String month;

  const _StatisticsHeader({
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  month,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySpendingChart
    extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const _CategorySpendingChart({
    required this.categoryTotals,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }

    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final entries = categoryTotals.entries.toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    if (entries.isEmpty) {
      return const _NoCurrentMonthData();
    }

    double maxAmount = 0;

    for (final entry in entries) {
      if (entry.value > maxAmount) {
        maxAmount = entry.value;
      }
    }

    final double chartMaxY =
        maxAmount == 0 ? 1000 : maxAmount * 1.2;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          10,
          18,
          10,
          12,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Spending by category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 330,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  minY: 0,
                  alignment:
                      BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        chartMaxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme
                            .onSurface
                            .withOpacity(0.08),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval:
                            chartMaxY / 4,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          return Text(
                            _formatAmount(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme
                                  .onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          final index =
                              value.toInt();

                          if (index < 0 ||
                              index >=
                                  entries.length) {
                            return const SizedBox
                                .shrink();
                          }

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              top: 8,
                            ),
                            child: SizedBox(
                              width: 65,
                              child: Text(
                                entries[index].key,
                                textAlign:
                                    TextAlign.center,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    entries.length,
                    (index) {
                      final amount =
                          entries[index].value;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: amount,
                            width: 22,
                            borderRadius:
                                const BorderRadius.only(
                              topLeft:
                                  Radius.circular(6),
                              topRight:
                                  Radius.circular(6),
                            ),
                            color:
                                AppColors.primary,
                          ),
                        ],
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData:
                        BarTouchTooltipData(
                      getTooltipItem: (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                      ) {
                        final entry =
                            entries[groupIndex];

                        return BarTooltipItem(
                          '${entry.key}\n'
                          'Rs. ${entry.value.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySummaryItem
    extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;

  const _CategorySummaryItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  IconData _getCategoryIcon(
    String category,
  ) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Groceries':
        return Icons.shopping_cart_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      case 'Health':
        return Icons.health_and_safety_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Education':
        return Icons.school_outlined;
      case 'Travel':
        return Icons.flight_outlined;
      case 'Work':
        return Icons.work_outline;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${percentage.toStringAsFixed(1)}% of monthly spending',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Rs. ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (percentage / 100)
                    .clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor:
                    colorScheme
                        .surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySpendingChart
    extends StatelessWidget {
  final Map<String, double> monthlyTotals;

  const _MonthlySpendingChart({
    required this.monthlyTotals,
  });

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }

    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final entries = monthlyTotals.entries.toList();

    entries.sort((a, b) {
      final aParts = a.key.split('-');
      final bParts = b.key.split('-');

      final aDate = DateTime(
        int.parse(aParts[0]),
        int.parse(aParts[1]),
      );

      final bDate = DateTime(
        int.parse(bParts[0]),
        int.parse(bParts[1]),
      );

      return aDate.compareTo(bDate);
    });

    final chartEntries = entries.length > 6
        ? entries.sublist(entries.length - 6)
        : entries;

    if (chartEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxAmount = 0;

    for (final entry in chartEntries) {
      if (entry.value > maxAmount) {
        maxAmount = entry.value;
      }
    }

    final double chartMaxY =
        maxAmount == 0 ? 1000 : maxAmount * 1.2;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          10,
          18,
          10,
          12,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.show_chart_rounded,
                    size: 19,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last 6 months',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 290,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  minY: 0,
                  alignment:
                      BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        chartMaxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme
                            .onSurface
                            .withOpacity(0.08),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval:
                            chartMaxY / 4,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          return Text(
                            _formatAmount(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme
                                  .onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          final index =
                              value.toInt();

                          if (index < 0 ||
                              index >=
                                  chartEntries.length) {
                            return const SizedBox
                                .shrink();
                          }

                          final parts =
                              chartEntries[index]
                                  .key
                                  .split('-');

                          final month =
                              int.parse(parts[1]);

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              top: 8,
                            ),
                            child: Text(
                              _monthName(month),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    chartEntries.length,
                    (index) {
                      final amount =
                          chartEntries[index].value;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: amount,
                            width: 24,
                            borderRadius:
                                const BorderRadius.only(
                              topLeft:
                                  Radius.circular(6),
                              topRight:
                                  Radius.circular(6),
                            ),
                            color:
                                AppColors.primary,
                          ),
                        ],
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData:
                        BarTouchTooltipData(
                      getTooltipItem: (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                      ) {
                        final entry =
                            chartEntries[groupIndex];

                        final parts =
                            entry.key.split('-');

                        final year =
                            int.parse(parts[0]);

                        final month =
                            int.parse(parts[1]);

                        return BarTooltipItem(
                          '${_monthName(month)} $year\n'
                          'Rs. ${entry.value.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummaryItem
    extends StatelessWidget {
  final String month;
  final double amount;

  const _MonthlySummaryItem({
    required this.month,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.success
                .withOpacity(0.1),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.success,
          ),
        ),
        title: Text(
          month,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Monthly spending',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticsLoadingState
    extends StatelessWidget {
  const _StatisticsLoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Loading statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Preparing your spending insights...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsErrorState
    extends StatelessWidget {
  final Object? error;

  const _StatisticsErrorState({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.error
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 38,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load statistics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We could not load your spending data. '
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStatisticsState
    extends StatelessWidget {
  const _EmptyStatisticsState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No statistics yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see your '
              'spending statistics and insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCurrentMonthData
    extends StatelessWidget {
  const _NoCurrentMonthData();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colorScheme
                    .onSurface
                    .withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 27,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses this month',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Your category breakdown will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}