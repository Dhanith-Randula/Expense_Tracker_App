import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import 'add_expense_screen.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() =>
      _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState
    extends State<ExpenseHistoryScreen> {
  final ExpenseService _expenseService = ExpenseService();

  final TextEditingController _searchController =
      TextEditingController();

  final ValueNotifier<String> _searchQueryNotifier =
      ValueNotifier<String>('');

  String _selectedCategory = 'All Categories';
  String _selectedDateFilter = 'All Dates';

  DateTime? _customDate;

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // DELETE EXPENSE
  // ------------------------------------------------------------------

  Future<void> _deleteExpense(
    BuildContext context,
    Expense expense,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text(
            'Are you sure you want to delete "${expense.title}"?',
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
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _expenseService.deleteExpense(expense.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete expense: $e',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------------
  // ADD EXPENSE
  // ------------------------------------------------------------------

  void _openAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
  }

  // ------------------------------------------------------------------
  // CUSTOM DATE
  // ------------------------------------------------------------------

  Future<void> _selectCustomDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _customDate = pickedDate;
      _selectedDateFilter = 'Custom Date';
    });
  }

  // ------------------------------------------------------------------
  // DATE FILTER HELPERS
  // ------------------------------------------------------------------

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isThisWeek(
    DateTime date,
    DateTime now,
  ) {
    final startOfWeek = now.subtract(
      Duration(days: now.weekday - 1),
    );

    final startOfDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    final endOfWeek = startOfDay.add(
      const Duration(days: 7),
    );

    return !date.isBefore(startOfDay) &&
        date.isBefore(endOfWeek);
  }

  bool _matchesDateFilter(Expense expense) {
    final now = DateTime.now();

    switch (_selectedDateFilter) {
      case 'Today':
        return _isSameDay(
          expense.date,
          now,
        );

      case 'This Week':
        return _isThisWeek(
          expense.date,
          now,
        );

      case 'This Month':
        return expense.date.year == now.year &&
            expense.date.month == now.month;

      case 'Custom Date':
        if (_customDate == null) {
          return true;
        }

        return _isSameDay(
          expense.date,
          _customDate!,
        );

      case 'All Dates':
      default:
        return true;
    }
  }

  // ------------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------------

  bool _matchesSearch(
    Expense expense,
    String query,
  ) {
    if (query.isEmpty) {
      return true;
    }

    return expense.title
            .toLowerCase()
            .contains(query) ||
        expense.category
            .toLowerCase()
            .contains(query) ||
        expense.note
            .toLowerCase()
            .contains(query);
  }

  // ------------------------------------------------------------------
  // FILTER HELPERS
  // ------------------------------------------------------------------

  bool get _hasActiveFilters {
    return _selectedCategory != 'All Categories' ||
        _selectedDateFilter != 'All Dates' ||
        _searchQueryNotifier.value.isNotEmpty;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedCategory = 'All Categories';
      _selectedDateFilter = 'All Dates';
      _customDate = null;
    });

    _searchQueryNotifier.value = '';
  }

  String _getDateFilterLabel() {
    if (_selectedDateFilter == 'Custom Date' &&
        _customDate != null) {
      return 'Custom: ${_formatDate(_customDate!)}';
    }

    return _selectedDateFilter;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ValueListenableBuilder<String>(
        valueListenable: _searchQueryNotifier,
        builder: (
          context,
          searchQuery,
          child,
        ) {
          return StreamBuilder<List<Expense>>(
            stream: _expenseService.getExpenses(),
            builder: (
              context,
              snapshot,
            ) {
              // ------------------------------------------------------
              // LOADING
              // ------------------------------------------------------

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return _HistoryLoadingState(
                  colorScheme: colorScheme,
                );
              }

              // ------------------------------------------------------
              // ERROR
              // ------------------------------------------------------

              if (snapshot.hasError) {
                return _HistoryErrorState(
                  colorScheme: colorScheme,
                );
              }

              final expenses =
                  snapshot.data ?? [];

              // ------------------------------------------------------
              // SEARCH FILTER
              // ------------------------------------------------------

              final searchFilteredExpenses =
                  expenses.where((expense) {
                return _matchesSearch(
                  expense,
                  _searchQueryNotifier.value,
                );
              }).toList();

              // ------------------------------------------------------
              // CATEGORY FILTER
              // ------------------------------------------------------

              final categoryFilteredExpenses =
                  _selectedCategory ==
                          'All Categories'
                      ? searchFilteredExpenses
                      : searchFilteredExpenses
                          .where((expense) {
                          return expense.category ==
                              _selectedCategory;
                        }).toList();

              // ------------------------------------------------------
              // DATE FILTER
              // ------------------------------------------------------

              final filteredExpenses =
                  categoryFilteredExpenses
                      .where((expense) {
                return _matchesDateFilter(
                  expense,
                );
              }).toList();

              // ------------------------------------------------------
              // COMPLETELY EMPTY DATABASE
              // ------------------------------------------------------

              if (expenses.isEmpty) {
                return _EmptyHistoryState(
                  colorScheme: colorScheme,
                  onAddExpense: () {
                    _openAddExpense(context);
                  },
                );
              }

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
                      constraints:
                          const BoxConstraints(
                        maxWidth: 900,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          // ------------------------------------------------
                          // PAGE HEADER
                          // ------------------------------------------------

                          Text(
                            'All Expenses',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '${filteredExpenses.length} transaction${filteredExpenses.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ------------------------------------------------
                          // FILTER CARD
                          // ------------------------------------------------

                          Card(
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration:
                                            BoxDecoration(
                                          color: AppColors
                                              .primary
                                              .withOpacity(
                                            0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .tune_outlined,
                                          size: 20,
                                          color: AppColors
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Search & Filters',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color:
                                                colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                      ),
                                      if (_hasActiveFilters)
                                        TextButton(
                                          onPressed:
                                              _clearFilters,
                                          child:
                                              const Text(
                                            'Clear',
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 16,
                                  ),

                                  // ------------------------------------------------
                                  // SEARCH
                                  // ------------------------------------------------

                                  TextField(
                                    controller:
                                        _searchController,
                                    onChanged:
                                        (value) {
                                      _searchQueryNotifier
                                              .value =
                                          value
                                              .trim()
                                              .toLowerCase();
                                    },
                                    textInputAction:
                                        TextInputAction
                                            .search,
                                    decoration:
                                        InputDecoration(
                                      hintText:
                                          'Search expenses...',
                                      prefixIcon:
                                          const Icon(
                                        Icons.search,
                                      ),
                                      suffixIcon:
                                          searchQuery
                                                  .isNotEmpty
                                              ? IconButton(
                                                  onPressed:
                                                      () {
                                                    _searchController
                                                        .clear();
                                                    _searchQueryNotifier
                                                        .value = '';
                                                  },
                                                  icon:
                                                      const Icon(
                                                    Icons
                                                        .clear,
                                                  ),
                                                  tooltip:
                                                      'Clear search',
                                                )
                                              : null,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 16,
                                  ),

                                  // ------------------------------------------------
                                  // CATEGORY + DATE FILTERS
                                  // ------------------------------------------------

                                  LayoutBuilder(
                                    builder:
                                        (
                                      context,
                                      constraints,
                                    ) {
                                      final isWide =
                                          constraints
                                                  .maxWidth >=
                                              600;

                                      final categoryField =
                                          DropdownButtonFormField<
                                              String>(
                                        value:
                                            _selectedCategory,
                                        decoration:
                                            const InputDecoration(
                                          labelText:
                                              'Category',
                                          prefixIcon:
                                              Icon(
                                            Icons
                                                .filter_list_outlined,
                                          ),
                                        ),
                                        items: [
                                          const DropdownMenuItem<
                                              String>(
                                            value:
                                                'All Categories',
                                            child: Text(
                                              'All Categories',
                                            ),
                                          ),
                                          ...AppConstants
                                              .expenseCategories
                                              .map(
                                            (
                                              category,
                                            ) =>
                                                DropdownMenuItem<
                                                    String>(
                                              value:
                                                  category,
                                              child:
                                                  Text(
                                                category,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged:
                                            (value) {
                                          if (value ==
                                              null) {
                                            return;
                                          }

                                          setState(() {
                                            _selectedCategory =
                                                value;
                                          });
                                        },
                                      );

                                      final dateField =
                                          DropdownButtonFormField<
                                              String>(
                                        value:
                                            _selectedDateFilter,
                                        decoration:
                                            InputDecoration(
                                          labelText:
                                              'Date',
                                          prefixIcon:
                                              const Icon(
                                            Icons
                                                .calendar_month_outlined,
                                          ),
                                          suffixIcon:
                                              _selectedDateFilter ==
                                                      'Custom Date'
                                                  ? IconButton(
                                                      onPressed:
                                                          () {
                                                        setState(
                                                          () {
                                                            _selectedDateFilter =
                                                                'All Dates';
                                                            _customDate =
                                                                null;
                                                          },
                                                        );
                                                      },
                                                      icon:
                                                          const Icon(
                                                        Icons
                                                            .clear,
                                                      ),
                                                      tooltip:
                                                          'Clear date filter',
                                                    )
                                                  : null,
                                        ),
                                        items:
                                            const [
                                          DropdownMenuItem<
                                              String>(
                                            value:
                                                'All Dates',
                                            child: Text(
                                              'All Dates',
                                            ),
                                          ),
                                          DropdownMenuItem<
                                              String>(
                                            value:
                                                'Today',
                                            child: Text(
                                              'Today',
                                            ),
                                          ),
                                          DropdownMenuItem<
                                              String>(
                                            value:
                                                'This Week',
                                            child: Text(
                                              'This Week',
                                            ),
                                          ),
                                          DropdownMenuItem<
                                              String>(
                                            value:
                                                'This Month',
                                            child: Text(
                                              'This Month',
                                            ),
                                          ),
                                          DropdownMenuItem<
                                              String>(
                                            value:
                                                'Custom Date',
                                            child: Text(
                                              'Custom Date',
                                            ),
                                          ),
                                        ],
                                        selectedItemBuilder:
                                            (context) {
                                          return [
                                            const Text(
                                              'All Dates',
                                            ),
                                            const Text(
                                              'Today',
                                            ),
                                            const Text(
                                              'This Week',
                                            ),
                                            const Text(
                                              'This Month',
                                            ),
                                            Text(
                                              _getDateFilterLabel(),
                                            ),
                                          ];
                                        },
                                        onChanged:
                                            (value) {
                                          if (value ==
                                              null) {
                                            return;
                                          }

                                          if (value ==
                                              'Custom Date') {
                                            _selectCustomDate();
                                            return;
                                          }

                                          setState(() {
                                            _selectedDateFilter =
                                                value;
                                            _customDate =
                                                null;
                                          });
                                        },
                                      );

                                      if (isWide) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  categoryField,
                                            ),
                                            const SizedBox(
                                              width: 12,
                                            ),
                                            Expanded(
                                              child:
                                                  dateField,
                                            ),
                                          ],
                                        );
                                      }

                                      return Column(
                                        children: [
                                          categoryField,
                                          const SizedBox(
                                            height: 16,
                                          ),
                                          dateField,
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ------------------------------------------------
                          // FILTERED EXPENSES
                          // ------------------------------------------------

                          if (filteredExpenses.isEmpty)
                            _NoResultsState(
                              colorScheme:
                                  colorScheme,
                              hasActiveFilters:
                                  _hasActiveFilters,
                              onClearFilters:
                                  _clearFilters,
                              onAddExpense: () {
                                _openAddExpense(
                                  context,
                                );
                              },
                            )
                          else
                            Card(
                              child:
                                  ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount:
                                    filteredExpenses
                                        .length,
                                separatorBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  return const Divider(
                                    height: 1,
                                  );
                                },
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  final expense =
                                      filteredExpenses[
                                          index];

                                  return _ExpenseHistoryItem(
                                    expense:
                                        expense,
                                    onDelete: () {
                                      _deleteExpense(
                                        context,
                                        expense,
                                      );
                                    },
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
          );
        },
      ),
    );
  }
}

// =====================================================================
// LOADING STATE
// =====================================================================

class _HistoryLoadingState
    extends StatelessWidget {
  final ColorScheme colorScheme;

  const _HistoryLoadingState({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading expense history',
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
                color:
                    colorScheme.onSurfaceVariant,
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

class _HistoryErrorState
    extends StatelessWidget {
  final ColorScheme colorScheme;

  const _HistoryErrorState({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 420,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error
                      .withOpacity(0.1),
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
                'We could not load your expense history. '
                'Please check your internet connection '
                'and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {},
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
// EMPTY DATABASE STATE
// =====================================================================

class _EmptyHistoryState
    extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback onAddExpense;

  const _EmptyHistoryState({
    required this.colorScheme,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 420,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No expenses yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved expenses will appear here. '
                'Add your first expense to start tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add First Expense',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// NO FILTER RESULTS
// =====================================================================

class _NoResultsState
    extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onAddExpense;

  const _NoResultsState({
    required this.colorScheme,
    required this.hasActiveFilters,
    required this.onClearFilters,
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_outlined,
                size: 32,
                color:
                    colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilters
                  ? 'Try changing your search or filters.'
                  : 'There are no expenses to display.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (hasActiveFilters)
                  OutlinedButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text(
                      'Clear Filters',
                    ),
                  ),
                FilledButton.icon(
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Expense',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// EXPENSE HISTORY ITEM
// =====================================================================

class _ExpenseHistoryItem
    extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const _ExpenseHistoryItem({
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),

      leading: CircleAvatar(
        radius: 24,
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

      subtitle: Padding(
        padding:
            const EdgeInsets.only(top: 4),
        child: Text(
          '${expense.category} • ${_formatDate(expense.date)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                colorScheme.onSurfaceVariant,
          ),
        ),
      ),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 105,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  Alignment.centerRight,
              child: Text(
                'Rs. ${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      colorScheme.onSurface,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          PopupMenuButton<String>(
            tooltip: 'Expense actions',
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddExpenseScreen(
                      expense: expense,
                    ),
                  ),
                );
              }

              if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) =>
                const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                    ),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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