import 'package:flutter/foundation.dart';

/// Core domain model for a pond.
@immutable
class Pond {
  final String id;
  final String farmId;
  final String name;
  final String location;
  final double areaAcres;
  final String species;
  final DateTime stockingDate;
  final int stockingCount;

  /// Initial stocking density (PLs/m²).
  final double initialStockingDensity;

  /// Days of culture (DOC).
  final int daysOfCulture;

  /// Average body weight in grams.
  final double avgBodyWeightGrams;

  /// Survival rate in percent (0–100).
  final double survivalPercent;

  /// Total feed used so far, in metric tons.
  final double totalFeedTons;

  /// Feed conversion ratio.
  final double fcr;

  final DateTime estimatedHarvestDate;

  /// Estimated harvest biomass in metric tons.
  final double estimatedBiomassTons;

  const Pond({
    required this.id,
    required this.farmId,
    required this.name,
    required this.location,
    required this.areaAcres,
    required this.species,
    required this.stockingDate,
    required this.stockingCount,
    required this.initialStockingDensity,
    required this.daysOfCulture,
    required this.avgBodyWeightGrams,
    required this.survivalPercent,
    required this.totalFeedTons,
    required this.fcr,
    required this.estimatedHarvestDate,
    required this.estimatedBiomassTons,
  });
}

/// Simple data model for a daily pond log entry.
@immutable
class PondLog {
  final String id;
  final String farmId;
  final String pondId;
  final DateTime date;

  /// Water temperature in °C.
  final double waterTempC;

  /// Dissolved oxygen (mg/L).
  final double dissolvedOxygen;

  /// pH value.
  final double ph;

  /// Salinity in parts per thousand.
  final double salinityPpt;

  /// Ammonia in ppm.
  final double ammoniaPpm;

  /// Feed used today in kg.
  final double feedKg;

  /// Mortalities today (pieces).
  final int mortalityCount;

  const PondLog({
    required this.id,
    required this.farmId,
    required this.pondId,
    required this.date,
    required this.waterTempC,
    required this.dissolvedOxygen,
    required this.ph,
    required this.salinityPpt,
    required this.ammoniaPpm,
    required this.feedKg,
    required this.mortalityCount,
  });
}

/// Temporary in‑memory sample data.
///
/// Later we can replace this with persistence (SQLite, Hive, Supabase, etc.).
final List<Pond> samplePonds = [
  Pond(
    id: 'pond-1',
    farmId: 'farm-1',
    name: 'Pond 1',
    location: 'North Field, Section 1',
    areaAcres: 1.5,
    species: 'L. vannamei',
    stockingDate: DateTime(2025, 12, 1),
    stockingCount: 350_000,
    initialStockingDensity: 25,
    daysOfCulture: 75,
    avgBodyWeightGrams: 18.5,
    survivalPercent: 92,
    totalFeedTons: 1.2,
    fcr: 1.4,
    estimatedHarvestDate: DateTime(2026, 3, 15),
    estimatedBiomassTons: 2.5,
  ),
  Pond(
    id: 'pond-2',
    farmId: 'farm-1',
    name: 'Pond 2',
    location: 'North Field, Section 2',
    areaAcres: 2.0,
    species: 'L. vannamei',
    stockingDate: DateTime(2025, 12, 10),
    stockingCount: 420_000,
    initialStockingDensity: 25,
    daysOfCulture: 68,
    avgBodyWeightGrams: 16.2,
    survivalPercent: 89,
    totalFeedTons: 1.4,
    fcr: 1.5,
    estimatedHarvestDate: DateTime(2026, 3, 25),
    estimatedBiomassTons: 2.9,
  ),
  Pond(
    id: 'pond-3',
    farmId: 'farm-1',
    name: 'Pond 3',
    location: 'South Field',
    areaAcres: 1.2,
    species: 'M. rosenbergii',
    stockingDate: DateTime(2025, 11, 20),
    stockingCount: 260_000,
    initialStockingDensity: 18,
    daysOfCulture: 82,
    avgBodyWeightGrams: 20.1,
    survivalPercent: 90,
    totalFeedTons: 1.1,
    fcr: 1.35,
    estimatedHarvestDate: DateTime(2026, 3, 10),
    estimatedBiomassTons: 2.1,
  ),
];

/// In‑memory store for water quality logs.
///
/// For now this is kept in memory only; later it can be backed
/// by a database or cloud sync.
final List<PondLog> waterLogs = [];

@immutable
class FeedLog {
  final String id;
  final String farmId;
  final String pondId;
  final DateTime dateTime;
  final String feedType;
  final double quantityKg;

  const FeedLog({
    required this.id,
    required this.farmId,
    required this.pondId,
    required this.dateTime,
    required this.feedType,
    required this.quantityKg,
  });
}

/// In‑memory store for feed inputs.
final List<FeedLog> feedLogs = [];

/// A growth sampling record: average body weight and survival from a sample.
@immutable
class GrowthSample {
  final String id;
  final String farmId;
  final String pondId;
  final DateTime date;

  /// Average body weight in grams from this sample.
  final double avgBodyWeightGrams;

  /// Survival rate in percent (0–100) from this sample.
  final double survivalPercent;

  /// Number of prawns sampled (optional).
  final int sampleSize;

  final String notes;

  const GrowthSample({
    required this.id,
    required this.farmId,
    required this.pondId,
    required this.date,
    required this.avgBodyWeightGrams,
    required this.survivalPercent,
    this.sampleSize = 0,
    this.notes = '',
  });
}

@immutable
class Expense {
  final String id;
  final String farmId;
  final DateTime date;
  final double amount;
  final String currency;
  final String description;
  final String category; // e.g. Feed, Labor, Electricity, Maintenance, Other
  final List<String> pondIds;

  const Expense({
    required this.id,
    required this.farmId,
    required this.date,
    required this.amount,
    required this.currency,
    required this.description,
    required this.category,
    required this.pondIds,
  });
}


@immutable
class MortalityLog {
  final String id;
  final String farmId;
  final String pondId;
  final DateTime dateTime;
  final int count;
  final String reason;
  final String notes;

  const MortalityLog({
    required this.id,
    required this.farmId,
    required this.pondId,
    required this.dateTime,
    required this.count,
    this.reason = '',
    this.notes = '',
  });
}


