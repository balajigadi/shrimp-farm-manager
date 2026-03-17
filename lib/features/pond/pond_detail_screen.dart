import 'package:flutter/material.dart';
import 'pond_model.dart';

class PondDetailScreen extends StatelessWidget {
  final Pond pond;

  const PondDetailScreen({super.key, required this.pond});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(pond.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 16),
          _todayLogPlaceholder(),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final stockingDateStr =
        '${pond.stockingDate.day}/${pond.stockingDate.month}/${pond.stockingDate.year}';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pond information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow('Species', pond.species),
            _infoRow('Area', '${pond.areaAcres.toStringAsFixed(1)} acres'),
            _infoRow(
              'Initial stocking density',
              '${pond.initialStockingDensity.toStringAsFixed(1)} PLs/m²',
            ),
            _infoRow('Stocking date', stockingDateStr),
            _infoRow('Stocking count', '${pond.stockingCount} pcs'),
            _infoRow('DOC', '${pond.daysOfCulture} days'),
            _infoRow(
              'Average body weight',
              '${pond.avgBodyWeightGrams.toStringAsFixed(1)} g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
		children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _todayLogPlaceholder() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Today's log",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Here you will record water quality (°C, pH, DO), feed (kg) and mortality.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              'Logging UI and charts will be added in the next step.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

