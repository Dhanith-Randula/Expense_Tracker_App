import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../statistics/statistics_screen.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  DashboardScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  final ExpenseService _expenseService = ExpenseService();

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _showLogoutDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: Text(
            'Are you sure you want to log out of Spendly?',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();
  }

  void _openAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseHistoryScreen(),
      ),
    );
  }

  void _openStatistics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spendly',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Switch(
            value: isDarkMode,
            onChanged: onThemeChanged,
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'logout') {
                await _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) {
              final email =
                  _currentUser?.email ?? 'No email available';

              return [
                PopupMenuItem<String>(
                  enabled: false,
                  value: 'account',
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signed in as',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.getExpenses(),
        builder: (context, snapshot) {
          // ----------------------------------------------------------
          // LOADING STATE
          // ----------------------------------------------------------
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return _LoadingState(
              colorScheme: colorScheme,
            );
          }

          // ----------------------------------------------------------
          // ERROR STATE
          // ----------------------------------------------------------
          if (snapshot.hasError) {
            return _ErrorState(
              colorScheme: colorScheme,
            );
          }

          final expenses = snapshot.data ?? [];

          // ----------------------------------------------------------
          // CURRENT MONTH
          // ----------------------------------------------------------
          final now = DateTime.now();

          final currentMonthExpenses =
              expenses.where((expense) {
            return expense.date.year == now.year &&
                expense.date.month == now.month;
          }).toList();

          // ----------------------------------------------------------
          // CURRENT MONTH TOTAL
          // ----------------------------------------------------------
          final monthlyTotal =
              currentMonthExpenses.fold<double>(
            0,
            (total, expense) => total + expense.amount,
          );

          // ----------------------------------------------------------
          // TRANSACTION COUNT
          // ----------------------------------------------------------
          final transactionCount =
              currentMonthExpenses.length;

          // ----------------------------------------------------------
          // RECENT EXPENSES
          // ----------------------------------------------------------
          final recentExpenses =
              expenses.take(5).toList();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                100,
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
                      // ------------------------------------------------
                      // GREETING
                      // ------------------------------------------------
                      Text(
                        'Good morning 👋',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _currentUser?.email ??
                            'Welcome to Spendly',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Here is your spending overview.',
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------
                      // ACCOUNT CARD
                      // ------------------------------------------------
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentUser?.email ??
                                          'No email available',
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w600,
                                        color:
                                            colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------
                      // MONTHLY TOTAL
                      // ------------------------------------------------
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getMonthName(now.month),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Total Expenses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 4),

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rs. ${monthlyTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------
                      // MONTH SUMMARY
                      // ------------------------------------------------
                      Text(
                        'This Month',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 12),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide =
                              constraints.maxWidth >= 600;

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _SummaryCard(
                                    icon: Icons
                                        .receipt_long_outlined,
                                    title: 'Expenses',
                                    value:
                                        'Rs. ${monthlyTotal.toStringAsFixed(2)}',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SummaryCard(
                                    icon:
                                        Icons.swap_horiz_rounded,
                                    title: 'Transactions',
                                    value:
                                        '$transactionCount',
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              _SummaryCard(
                                icon:
                                    Icons.receipt_long_outlined,
                                title: 'Expenses',
                                value:
                                    'Rs. ${monthlyTotal.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 12),
                              _SummaryCard(
                                icon:
                                    Icons.swap_horiz_rounded,
                                title: 'Transactions',
                                value:
                                    '$transactionCount',
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // ------------------------------------------------
                      // RECENT EXPENSES HEADER
                      // ------------------------------------------------
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Recent Expenses',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    colorScheme.onSurface,
                              ),
                            ),
                          ),

                          if (recentExpenses.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _openHistory(context);
                              },
                              child: const Text('View All'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // EMPTY / RECENT EXPENSES
                      // ------------------------------------------------
                      if (recentExpenses.isEmpty)
                        _EmptyExpensesState(
                          colorScheme: colorScheme,
                          onAddExpense: () {
                            _openAddExpense(context);
                          },
                        )
                      else
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: recentExpenses.length,
                            separatorBuilder:
                                (context, index) {
                              return const Divider(
                                height: 1,
                              );
                            },
                            itemBuilder:
                                (context, index) {
                              final expense =
                                  recentExpenses[index];

                              return _ExpenseListItem(
                                expense: expense,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // --------------------------------------------------------------
      // ADD EXPENSE BUTTON
      // --------------------------------------------------------------
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _openAddExpense(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),

      // --------------------------------------------------------------
      // BOTTOM NAVIGATION
      // --------------------------------------------------------------
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _openHistory(context);
          }

          if (index == 2) {
            _openStatistics(context);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
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

    return '${months[month - 1]} ${DateTime.now().year}';
  }
}

// =====================================================================
// LOADING STATE
// =====================================================================

class _LoadingState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _LoadingState({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Loading your expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Please wait a moment...',
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

// =====================================================================
// ERROR STATE
// =====================================================================

class _ErrorState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ErrorState({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 34,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'We could not load your expenses right now. '
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {
                  // Firestore streams normally reconnect automatically.
                  // This button gives the user a clear action point.
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// EMPTY EXPENSE STATE
// =====================================================================

class _EmptyExpensesState extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onAddExpense;

  const _EmptyExpensesState({
    required this.colorScheme,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Start tracking your spending by adding '
              'your first expense.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Add First Expense'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// SUMMARY CARD
// =====================================================================

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
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

// =====================================================================
// EXPENSE LIST ITEM
// =====================================================================

class _ExpenseListItem extends StatelessWidget {
  final Expense expense;

  const _ExpenseListItem({
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      leading: CircleAvatar(
        backgroundColor:
            AppColors.primary.withOpacity(0.1),
        child: Icon(
          _getCategoryIcon(expense.category),
          color: AppColors.primary,
        ),
      ),

      title: Text(
        expense.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      subtitle: Text(
        '${expense.category} • ${_formatDate(expense.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      trailing: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 115,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            'Rs. ${expense.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;

      case 'Transport':
        return Icons.directions_car_outlined;

      case 'Groceries':
        return Icons.shopping_cart_outlined;

      case 'Bills':
        return Icons.receipt_outlined;

      case 'Health':
        return Icons.favorite_outline;

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}