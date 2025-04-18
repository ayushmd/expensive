import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../utils/category_icons.dart';
import '../utils/income_icons.dart';
import '../services/currency_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  TransactionType _selectedType = TransactionType.expense;

  final Map<TransactionType, List<String>> _categories = {
    TransactionType.expense: [
      'Food',
      'Groceries',
      'Transportation',
      'Entertainment',
      'Shopping',
      'Utilities',
      'Health',
      'Education',
      'Travel',
      'Others',
    ],
    TransactionType.income: IncomeIcons.categories,
  };

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        date: _selectedDate,
        type: _selectedType,
      );

      DatabaseService.addExpense(expense);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _selectedType == TransactionType.expense;
    final selectedCurrency = ref.watch(currencyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isExpense ? 'Add Expense' : 'Add Income'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transaction Type Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<TransactionType>(
                          segments: const [
                            ButtonSegment(
                              value: TransactionType.expense,
                              icon: Icon(Icons.remove_circle_outline),
                              label: Text('Expense'),
                            ),
                            ButtonSegment(
                              value: TransactionType.income,
                              icon: Icon(Icons.add_circle_outline),
                              label: Text('Income'),
                            ),
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (Set<TransactionType> selected) {
                            setState(() {
                              _selectedType = selected.first;
                              _selectedCategory = _categories[_selectedType]!.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Category Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories[_selectedType]!.map((category) {
                            final isSelected = category == _selectedCategory;
                            final categoryColor = isExpense 
                                ? Colors.primaries[category.hashCode % Colors.primaries.length]
                                : Colors.green;
                            return FilterChip(
                              selected: isSelected,
                              showCheckmark: false,
                              avatar: Icon(
                                isExpense 
                                    ? CategoryIcons.getIcon(category)
                                    : IncomeIcons.getIcon(category),
                                color: isSelected ? Colors.white : categoryColor,
                                size: 18,
                              ),
                              label: Text(category),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                              backgroundColor: categoryColor.withOpacity(0.1),
                              selectedColor: categoryColor,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategory = category);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Amount and Date
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Field
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Text(
                              '  ${selectedCurrency.symbol}',
                              style: TextStyle(
                                fontSize: 20,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        // Quick Amount Buttons
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [10, 20, 50, 100, 500, 1000].map((amount) {
                            return ActionChip(
                              avatar: Text(
                                selectedCurrency.symbol,
                                style: TextStyle(
                                  color: isExpense ? Colors.red : Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                              label: Text(amount.toString()),
                              onPressed: () {
                                final currentAmount = double.tryParse(_amountController.text) ?? 0;
                                setState(() {
                                  _amountController.text = (currentAmount + amount).toStringAsFixed(2);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat.yMMMd().format(_selectedDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Add a note...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Submit Button
                FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}