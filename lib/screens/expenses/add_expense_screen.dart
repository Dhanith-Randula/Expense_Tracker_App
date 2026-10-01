import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../services/expense_service.dart';
// import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({
    super.key,
    this.expense,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final ExpenseService _expenseService = ExpenseService();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
      _noteController.text = expense.note;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        final updatedExpense = Expense(
          id: widget.expense!.id,
          userId: user.uid,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          category: _selectedCategory!,
          date: _selectedDate,
          note: _noteController.text.trim(),
          createdAt: widget.expense!.createdAt,
        );

        await _expenseService.updateExpense(updatedExpense);
      } else {
        final newExpense = Expense(
          id: '',
          userId: user.uid,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          category: _selectedCategory!,
          date: _selectedDate,
          note: _noteController.text.trim(),
          createdAt: DateTime.now(),
        );

        await _expenseService.addExpense(newExpense);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Expense updated successfully!'
                : 'Expense saved successfully!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Failed to update expense: $e'
                : 'Failed to save expense: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing
                          ? 'Update your expense'
                          : 'Add a new expense',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _isEditing
                          ? 'Change the details of your expense below.'
                          : 'Enter the details of your expense below.',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Expense Title
                    Text(
                      'Expense Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Lunch',
                        prefixIcon: Icon(
                          Icons.receipt_long_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an expense title';
                        }

                        if (value.trim().length < 2) {
                          return 'Title must be at least 2 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Amount
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: 'Rs. ',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }

                        final amount = double.tryParse(value.trim());

                        if (amount == null) {
                          return 'Please enter a valid amount';
                        }

                        if (amount <= 0) {
                          return 'Amount must be greater than 0';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Category
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        hintText: 'Select category',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                        ),
                      ),
                      items: AppConstants.expenseCategories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Date
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                          ),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Note
                    Text(
                      'Note (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _noteController,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Add a note about this expense...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 55),
                          child: Icon(
                            Icons.notes_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Save / Update button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveExpense,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isEditing
                                    ? Icons.check_circle_outline
                                    : Icons.save_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? (_isEditing ? 'Updating...' : 'Saving...')
                              : (_isEditing
                                  ? 'Save Changes'
                                  : 'Save Expense'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}