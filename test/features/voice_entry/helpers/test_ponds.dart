import 'package:prawn_farm_app/features/pond/pond_model.dart';

Pond testPond({
  String id = 'p1',
  String name = 'Pond 1',
  DateTime? stockingDate,
}) {
  return Pond(
    id: id,
    farmId: 'farm-1',
    name: name,
    location: 'test',
    areaAcres: 1,
    species: 'L. vannamei',
    stockingDate: stockingDate ?? DateTime(2026, 6, 1),
    stockingCount: 100000,
    initialStockingDensity: 20,
    daysOfCulture: 50,
    avgBodyWeightGrams: 12,
    survivalPercent: 90,
    totalFeedTons: 1,
    fcr: 1.2,
    estimatedHarvestDate: DateTime(2026, 9, 1),
    estimatedBiomassTons: 1,
  );
}

List<Pond> demoPonds() => [
  testPond(id: 'p1', name: 'Pond 1'),
  testPond(id: 'p2', name: 'Pond 2'),
  testPond(id: 'p3', name: 'Pond 3'),
  testPond(id: 'pn', name: 'Nursery'),
  testPond(id: 'ps', name: 'South Pond'),
];
