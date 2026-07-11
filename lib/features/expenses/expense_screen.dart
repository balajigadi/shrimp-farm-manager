import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _receiptImageFile;
  bool _saving = false;
  int _touchedExpenseSliceIndex = -1;
  final ImagePicker _imagePicker = ImagePicker();

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
                const SizedBox(height: 16),
                _buildReceiptAttachmentBox(),
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
                    onPressed: _saving ? null : _saveExpense,
                    child: Text(
                      _saving ? 'Saving...' : AppLocalizations.of(context)!.save,
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
              selectedColor: const Color(0xFF00C853).withValues(alpha: 0.15),
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
                      const Color(0xFF00C853).withValues(alpha: 0.15),
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

  Widget _buildReceiptAttachmentBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receipt Attachment',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(AppLocalizations.of(context)!.expenseTakePhoto),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(AppLocalizations.of(context)!.expenseUploadFromGallery),
                  ),
                  if (_receiptImageFile != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _receiptImageFile = null),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: Text(
                        AppLocalizations.of(context)!.expenseRemoveReceipt,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              if (_receiptImageFile != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _receiptImageFile!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      _receiptImageFile = File(picked.path);
    });
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      _receiptImageFile = File(picked.path);
    });
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
                  farmId: FirestoreService.instance.currentFarmId,
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
                  if (expenses.isNotEmpty) ...[
                    _buildExpenseDistributionCard(
                      byCategory: byCategory,
                      total: total,
                    ),
                    const SizedBox(height: 16),
                  ],
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
                            leading: e.imageUrl.isEmpty
                                ? const Icon(Icons.receipt_long)
                                : const Icon(Icons.image_outlined),
                            title: Text(e.description.isEmpty
                                ? e.category
                                : e.description),
                            subtitle: Text(
                              '$dateText • ${e.category}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${e.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (e.imageUrl.isNotEmpty)
                                  const Text(
                                    'Receipt',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: e.imageUrl.isEmpty
                                ? null
                                : () => _openReceiptPreview(e.imageUrl),
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

  void _openReceiptPreview(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.expenseReceiptPreviewTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (_, __, ___) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(AppLocalizations.of(context)!.expenseReceiptLoadFailed),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

  Widget _buildExpenseDistributionCard({
    required Map<String, double> byCategory,
    required double total,
  }) {
    final entries = byCategory.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasTouched =
        _touchedExpenseSliceIndex >= 0 &&
        _touchedExpenseSliceIndex < entries.length;
    final touchedEntry = hasTouched ? entries[_touchedExpenseSliceIndex] : null;

    final sections = entries.asMap().entries.map((entryWithIndex) {
      final i = entryWithIndex.key;
      final entry = entryWithIndex.value;
      final value = entry.value;
      final isTouched = i == _touchedExpenseSliceIndex;
      return PieChartSectionData(
        value: value,
        color: _categoryColor(entry.key),
        radius: isTouched ? 26 : 20,
        showTitle: false,
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 62,
                      sectionsSpace: 0,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            if (_touchedExpenseSliceIndex != -1) {
                              setState(() => _touchedExpenseSliceIndex = -1);
                            }
                            return;
                          }
                          setState(() {
                            _touchedExpenseSliceIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        touchedEntry?.key ?? 'Total',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        touchedEntry == null
                            ? '₹${(total / 100000).toStringAsFixed(1)}L'
                            : '₹${touchedEntry.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (touchedEntry != null)
                        Text(
                          '${((touchedEntry.value / total) * 100).toStringAsFixed(0)}% of total',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('feed') || c.contains('మేత')) return const Color(0xFF34A853);
    if (c.contains('labor') || c.contains('కూలి')) return const Color(0xFF4285F4);
    if (c.contains('electricity') || c.contains('విద్యుత్')) {
      return const Color(0xFFFBBC05);
    }
    if (c.contains('maintenance') || c.contains('పరిరక్షణ')) {
      return const Color(0xFFEA4335);
    }
    if (c.contains('seed') || c.contains('విత్తనం')) return const Color(0xFFAB47BC);
    return const Color(0xFF9E9E9E);
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());

    setState(() {
      _saving = true;
    });

    try {
      var imageUrl = '';
      if (_receiptImageFile != null) {
        imageUrl = await FirestoreService.instance.uploadExpenseReceipt(
          farmId: FirestoreService.instance.currentFarmId,
          file: _receiptImageFile!,
        );
      }

      final expense = Expense(
        id: '',
        farmId: FirestoreService.instance.currentFarmId,
        date: _selectedDate,
        amount: amount,
        currency: 'INR',
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        pondIds: _selectedPondIds.toList(),
        imageUrl: imageUrl,
      );

      final expenseId = await FirestoreService.instance.addExpense(expense);

      if (!mounted) return;
      setState(() {
        _amountController.clear();
        _descriptionController.clear();
        _selectedCategory = 'Feed';
        _selectedPondIds.clear();
        _selectedDate = DateTime.now();
        _receiptImageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.expenseSaved} (ID: $expenseId)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.expenseSaveFailed}: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
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

