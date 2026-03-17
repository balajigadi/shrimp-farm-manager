import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'pond_model.dart';
import 'pond_form_screen.dart';

class PondListScreen extends StatelessWidget {
  final List<Pond> ponds;
  final void Function(Pond pond) onCreate;
  final void Function(Pond pond) onUpdate;
  final void Function(Pond pond)? onDelete;

  const PondListScreen({
    super.key,
    required this.ponds,
    required this.onCreate,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.titlePonds),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00C853),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PondFormScreen(
                mode: PondFormMode.create,
                onSave: (pond) => onCreate(pond),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ponds.isEmpty
          ? const Center(
              child: Text(
                'No ponds added yet.\nTap + to add your first pond.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ponds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final pond = ponds[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      pond.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${pond.species} • ${pond.areaAcres.toStringAsFixed(1)} acres',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PondFormScreen(
                            mode: PondFormMode.edit,
                            existing: pond,
                            onSave: (updated) => onUpdate(updated),
                            onDelete: onDelete,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

