import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../pond/pond_model.dart';
import '../../services/firestore_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Feed';
  final Set<String> _selectedPondIds = {};
  String? _reportPondId; // null = all ponds

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.titleExpenses),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.addExpense),
              Tab(text: AppLocalizations.of(context)!.expenseReport),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddExpenseTab(),
            _buildReportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpenseTab() {
    final dateText =
        '${_selectedDate.day} ${_monthName(_selectedDate.month)}, ${_selectedDate.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDatePicker(dateText),
                const SizedBox(height: 12),
                _buildAmountField(),
                const SizedBox(height: 12),
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildCategoryChips(),
                const SizedBox(height: 16),
                _buildPondAssignment(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveExpense,
                    child: Text(
                      AppLocalizations.of(context)!.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String dateText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(now.year - 2),
              lastDate: DateTime(now.year + 2),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(dateText),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.amountInr,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _amountController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C853)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context)!.amountRequired;
            }
            if (double.tryParse(value.trim()) == null) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g., 50kg of feed',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C853)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      AppLocalizations.of(context)!.feedExpense,
      AppLocalizations.of(context)!.seed,
      AppLocalizations.of(context)!.labor,
      AppLocalizations.of(context)!.electricity,
      AppLocalizations.of(context)!.maintenance,
      AppLocalizations.of(context)!.other,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.category,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final selected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              selectedColor: const Color(0xFF00C853).withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? const Color(0xFF00C853) : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPondAssignment() {
    return StreamBuilder<List<Pond>>(
      stream: FirestoreService.instance.watchPonds(),
      builder: (context, snapshot) {
        final ponds = snapshot.data ?? [];
        if (ponds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.assignToPonds,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ponds.map((pond) {
                final selected = _selectedPondIds.contains(pond.id);
                return FilterChip(
                  label: Text(pond.name),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedPondIds.remove(pond.id);
                      } else {
                        _selectedPondIds.add(pond.id);
                      }
                    });
                  },
                  selectedColor:
                      const Color(0xFF00C853).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF00C853)
                        : Colors.black87,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportTab() {
    return StreamBuilder<List<Pond>>(
      stream: FirestoreService.instance.watchPonds(),
      builder: (context, pondSnapshot) {
        final ponds = pondSnapshot.data ?? [];

        return StreamBuilder<List<Expense>>(
          stream: FirestoreService.instance.watchExpenses(),
          builder: (context, snapshot) {
            final allExpenses = snapshot.data ?? [];

            // Filter by pond if one is selected.
            final expenses = _reportPondId == null
                ? allExpenses
                : allExpenses
                    .where((e) => e.pondIds.contains(_reportPondId))
                    .toList();

            final total = expenses.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );

            final byCategory = <String, double>{};
            for (final e in expenses) {
              byCategory[e.category] =
                  (byCategory[e.category] ?? 0) + e.amount;
            }

            String pondLabel;
            if (_reportPondId == null) {
              pondLabel = AppLocalizations.of(context)!.allPonds;
            } else {
              final pond = ponds.firstWhere(
                (p) => p.id == _reportPondId,
                orElse: () => Pond(
                  id: '',
                  farmId: FirestoreService.defaultFarmId,
                  name: 'Unknown pond',
                  location: '',
                  areaAcres: 0,
                  species: '',
                  stockingDate: DateTime.now(),
                  stockingCount: 0,
                  initialStockingDensity: 0,
                  daysOfCulture: 0,
                  avgBodyWeightGrams: 0,
                  survivalPercent: 0,
                  totalFeedTons: 0,
                  fcr: 0,
                  estimatedHarvestDate: DateTime.now(),
                  estimatedBiomassTons: 0,
                ),
              );
              pondLabel = pond.name;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pond filter row.
                  if (ponds.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (_) {
                            return ListView(
                              children: [
                                ListTile(
                                  title: Text(AppLocalizations.of(context)!.allPonds),
                                  onTap: () {
                                    setState(() {
                                      _reportPondId = null;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                                ...ponds.map((pond) {
                                  return ListTile(
                                    title: Text(pond.name),
                                    onTap: () {
                                      setState(() {
                                        _reportPondId = pond.id;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pond filter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pondLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          title: 'Total Expenses',
                          value: '₹${total.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Expense Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Text(
                        'No expenses recorded yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Column(
                      children: byCategory.entries.map((entry) {
                        final percent = total == 0
                            ? 0
                            : (entry.value / total * 100);
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.circle, size: 12),
                            title: Text(entry.key),
                            subtitle: Text(
                              '${percent.toStringAsFixed(0)}% of total',
                            ),
                            trailing: Text(
                              '₹${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Expenses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Text(
                        'No expenses to show.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final e = expenses[index];
                        final d = e.date;
                        final dateText =
                            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long),
                            title: Text(e.description.isEmpty
                                ? e.category
                                : e.description),
                            subtitle: Text(
                              '$dateText • ${e.category}',
                            ),
                            trailing: Text(
                              '₹${e.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryCard({required String title, required String value}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());

    final expense = Expense(
      id: '',
      farmId: FirestoreService.defaultFarmId,
      date: _selectedDate,
      amount: amount,
      currency: 'INR',
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      pondIds: _selectedPondIds.toList(),
    );

    FirestoreService.instance.addExpense(expense);

    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _selectedCategory = 'Feed';
      _selectedPondIds.clear();
      _selectedDate = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.expenseSaved)),
    );
  }

  String _monthName(int month) {
    const names = [
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
    return names[month - 1];
  }
}

