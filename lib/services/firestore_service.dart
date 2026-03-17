import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/pond/pond_model.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  /// For the current MVP we assume a single farm.
  /// Later this can come from the authenticated user / farm selector.
  static const String defaultFarmId = 'farm-1';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pondsCol =>
      _db.collection('ponds');
  CollectionReference<Map<String, dynamic>> get _waterLogsCol =>
      _db.collection('waterLogs');
  CollectionReference<Map<String, dynamic>> get _feedLogsCol =>
      _db.collection('feedLogs');
  CollectionReference<Map<String, dynamic>> get _expensesCol =>
      _db.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _growthSamplesCol =>
      _db.collection('growthSamples');
  CollectionReference<Map<String, dynamic>> get _mortalityLogsCol =>
      _db.collection('mortalityLogs');

  // PONDS ---------------------------------------------------------------------

  Stream<List<Pond>> watchPonds() {
    return _pondsCol.orderBy('name').snapshots().map(
      (snapshot) {
        return snapshot.docs.map(_pondFromDoc).toList();
      },
    );
  }

  Future<void> upsertPond(Pond pond) async {
    final data = <String, dynamic>{
      'farmId': pond.farmId,
      'name': pond.name,
      'location': pond.location,
      'areaAcres': pond.areaAcres,
      'species': pond.species,
      'stockingDate': pond.stockingDate,
      'stockingCount': pond.stockingCount,
      'initialStockingDensity': pond.initialStockingDensity,
      'daysOfCulture': pond.daysOfCulture,
      'avgBodyWeightGrams': pond.avgBodyWeightGrams,
      'survivalPercent': pond.survivalPercent,
      'totalFeedTons': pond.totalFeedTons,
      'fcr': pond.fcr,
      'estimatedHarvestDate': pond.estimatedHarvestDate,
      'estimatedBiomassTons': pond.estimatedBiomassTons,
    };

    if (pond.id.isEmpty) {
      await _pondsCol.add(data);
    } else {
      await _pondsCol.doc(pond.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deletePond(String pondId) {
    return _pondsCol.doc(pondId).delete();
  }

  Pond _pondFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Pond(
      id: doc.id,
      farmId: data['farmId'] as String? ?? defaultFarmId,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      areaAcres: (data['areaAcres'] as num?)?.toDouble() ?? 0,
      species: data['species'] as String? ?? '',
      stockingDate: (data['stockingDate'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      stockingCount: (data['stockingCount'] as num?)?.toInt() ?? 0,
      initialStockingDensity:
          (data['initialStockingDensity'] as num?)?.toDouble() ?? 0,
      daysOfCulture: (data['daysOfCulture'] as num?)?.toInt() ?? 0,
      avgBodyWeightGrams:
          (data['avgBodyWeightGrams'] as num?)?.toDouble() ?? 0,
      survivalPercent: (data['survivalPercent'] as num?)?.toDouble() ?? 0,
      totalFeedTons: (data['totalFeedTons'] as num?)?.toDouble() ?? 0,
      fcr: (data['fcr'] as num?)?.toDouble() ?? 0,
      estimatedHarvestDate:
          (data['estimatedHarvestDate'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0),
      estimatedBiomassTons:
          (data['estimatedBiomassTons'] as num?)?.toDouble() ?? 0,
    );
  }

  // WATER LOGS ----------------------------------------------------------------

  Stream<List<PondLog>> watchWaterLogs(String pondId) {
    return _waterLogsCol
        .where('pondId', isEqualTo: pondId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(_waterLogFromDoc).toList();
      },
    );
  }

  Future<void> addWaterLog(PondLog log) {
    final data = <String, dynamic>{
      'farmId': log.farmId,
      'pondId': log.pondId,
      'date': log.date,
      'waterTempC': log.waterTempC,
      'dissolvedOxygen': log.dissolvedOxygen,
      'ph': log.ph,
      'salinityPpt': log.salinityPpt,
      'ammoniaPpm': log.ammoniaPpm,
      'feedKg': log.feedKg,
      'mortalityCount': log.mortalityCount,
    };

    return _waterLogsCol.add(data);
  }

  PondLog _waterLogFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PondLog(
      id: doc.id,
      farmId: data['farmId'] as String? ?? defaultFarmId,
      pondId: data['pondId'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      waterTempC: (data['waterTempC'] as num?)?.toDouble() ?? 0,
      dissolvedOxygen:
          (data['dissolvedOxygen'] as num?)?.toDouble() ?? 0,
      ph: (data['ph'] as num?)?.toDouble() ?? 0,
      salinityPpt: (data['salinityPpt'] as num?)?.toDouble() ?? 0,
      ammoniaPpm: (data['ammoniaPpm'] as num?)?.toDouble() ?? 0,
      feedKg: (data['feedKg'] as num?)?.toDouble() ?? 0,
      mortalityCount: (data['mortalityCount'] as num?)?.toInt() ?? 0,
    );
  }

  // FEED LOGS -----------------------------------------------------------------

  Stream<List<FeedLog>> watchFeedLogs(String pondId) {
    return _feedLogsCol
        .where('pondId', isEqualTo: pondId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(_feedLogFromDoc).toList();
      },
    );
  }

  /// All feed logs for the current farm, across ponds.
  Stream<List<FeedLog>> watchFeedLogsForFarm() {
    return _feedLogsCol
        .where('farmId', isEqualTo: defaultFarmId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(_feedLogFromDoc).toList();
      },
    );
  }

  Future<void> addFeedLog(FeedLog log) async {
    final data = <String, dynamic>{
      'farmId': log.farmId,
      'pondId': log.pondId,
      'dateTime': log.dateTime,
      'feedType': log.feedType,
      'quantityKg': log.quantityKg,
    };

    await _feedLogsCol.add(data);

    // Recalculate and persist total feed used for this pond (in tons).
    await _recalculateTotalFeedForPond(log.pondId);
  }

  FeedLog _feedLogFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeedLog(
      id: doc.id,
      farmId: data['farmId'] as String? ?? defaultFarmId,
      pondId: data['pondId'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      feedType: data['feedType'] as String? ?? '',
      quantityKg: (data['quantityKg'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Recalculate `totalFeedTons` on the pond document from all its feed logs.
  Future<void> _recalculateTotalFeedForPond(String pondId) async {
    final snapshot =
        await _feedLogsCol.where('pondId', isEqualTo: pondId).get();

    double totalKg = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final qty = (data['quantityKg'] as num?)?.toDouble() ?? 0;
      totalKg += qty;
    }

    final totalTons = totalKg / 1000.0;

    await _pondsCol.doc(pondId).set(
      {
        'totalFeedTons': totalTons,
      },
      SetOptions(merge: true),
    );

    await _recalculateFcrForPond(pondId);
  }

  // GROWTH SAMPLES ------------------------------------------------------------

  Stream<List<GrowthSample>> watchGrowthSamples(String pondId) {
    return _growthSamplesCol
        .where('pondId', isEqualTo: pondId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(_growthSampleFromDoc).toList();
      },
    );
  }

  Future<void> addGrowthSample(GrowthSample sample) async {
    final data = <String, dynamic>{
      'farmId': sample.farmId,
      'pondId': sample.pondId,
      'date': sample.date,
      'avgBodyWeightGrams': sample.avgBodyWeightGrams,
      'survivalPercent': sample.survivalPercent,
      'sampleSize': sample.sampleSize,
      'notes': sample.notes,
    };
    await _growthSamplesCol.add(data);

    // Update pond with latest growth metrics from this sample.
    await _pondsCol.doc(sample.pondId).set(
      {
        'avgBodyWeightGrams': sample.avgBodyWeightGrams,
        'survivalPercent': sample.survivalPercent,
      },
      SetOptions(merge: true),
    );
  }

  GrowthSample _growthSampleFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GrowthSample(
      id: doc.id,
      farmId: data['farmId'] as String? ?? defaultFarmId,
      pondId: data['pondId'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      avgBodyWeightGrams:
          (data['avgBodyWeightGrams'] as num?)?.toDouble() ?? 0,
      survivalPercent: (data['survivalPercent'] as num?)?.toDouble() ?? 0,
      sampleSize: (data['sampleSize'] as num?)?.toInt() ?? 0,
      notes: data['notes'] as String? ?? '',
    );
  }

  // MORTALITY LOGS ------------------------------------------------------------

  Stream<List<MortalityLog>> watchMortalityLogs(String pondId) {
    return _mortalityLogsCol
        .where('pondId', isEqualTo: pondId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(_mortalityLogFromDoc).toList();
      },
    );
  }

  Future<void> addMortalityLog(MortalityLog log) async {
    final data = <String, dynamic>{
      'farmId': log.farmId,
      'pondId': log.pondId,
      'dateTime': log.dateTime,
      'count': log.count,
      'reason': log.reason,
      'notes': log.notes,
    };
    await _mortalityLogsCol.add(data);

    await _recalculateMortalityForPond(log.pondId);
  }

  MortalityLog _mortalityLogFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MortalityLog(
      id: doc.id,
      farmId: data['farmId'] as String? ?? defaultFarmId,
      pondId: data['pondId'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      count: (data['count'] as num?)?.toInt() ?? 0,
      reason: data['reason'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
    );
  }

  /// Recalculate total mortality and survival/biomass for a pond from logs.
  Future<void> _recalculateMortalityForPond(String pondId) async {
    final pondSnap = await _pondsCol.doc(pondId).get();
    if (!pondSnap.exists) return;

    final pondData = pondSnap.data();
    if (pondData == null) return;

    final stockingCount =
        (pondData['stockingCount'] as num?)?.toInt() ?? 0;
    if (stockingCount <= 0) return;

    final avgBodyWeightGrams =
        (pondData['avgBodyWeightGrams'] as num?)?.toDouble() ?? 0.0;

    final logsSnap =
        await _mortalityLogsCol.where('pondId', isEqualTo: pondId).get();

    int totalDead = 0;
    for (final doc in logsSnap.docs) {
      final data = doc.data();
      totalDead += (data['count'] as num?)?.toInt() ?? 0;
    }

    if (totalDead < 0) totalDead = 0;
    if (totalDead > stockingCount) totalDead = stockingCount;

    final survivors = stockingCount - totalDead;
    final survivalPercent =
        stockingCount == 0 ? 0.0 : (survivors / stockingCount) * 100.0;

    // Biomass in tons, if average weight is available.
    final biomassTons =
        avgBodyWeightGrams <= 0 ? null : survivors * avgBodyWeightGrams / 1e6;

    final updateData = <String, dynamic>{
      'survivalPercent': survivalPercent,
    };
    if (biomassTons != null) {
      updateData['estimatedBiomassTons'] = biomassTons;
    }

    await _pondsCol.doc(pondId).set(updateData, SetOptions(merge: true));

    await _recalculateFcrForPond(pondId);
  }

  /// Recalculate FCR based on total feed and estimated biomass.
  Future<void> _recalculateFcrForPond(String pondId) async {
    final snap = await _pondsCol.doc(pondId).get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;

    final totalFeedTons = (data['totalFeedTons'] as num?)?.toDouble() ?? 0.0;
    final biomassTons =
        (data['estimatedBiomassTons'] as num?)?.toDouble() ?? 0.0;

    if (totalFeedTons <= 0 || biomassTons <= 0) {
      // If we don't have both values yet, don't overwrite FCR.
      return;
    }

    final fcr = totalFeedTons / biomassTons;

    await _pondsCol
        .doc(pondId)
        .set({'fcr': fcr}, SetOptions(merge: true));
  }

  // EXPENSES ------------------------------------------------------------------

  Stream<List<Expense>> watchExpenses() {
    return _expensesCol
        .where('farmId', isEqualTo: defaultFarmId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(_expenseFromDoc).toList();
      },
    );
  }

  Future<void> addExpense(Expense expense) {
    final data = <String, dynamic>{
      'farmId': expense.farmId,
      'date': expense.date,
      'amount': expense.amount,
      'currency': expense.currency,
      'description': expense.description,
      'category': expense.category,
      'pondIds': expense.pondIds,
    };
    return _expensesCol.add(data);
  }

  Expense _expenseFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final pondIdsRaw = data['pondIds'];
    final pondIds = pondIdsRaw is Iterable
        ? pondIdsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return Expense(
      id: doc.id,
      farmId: data['farmId'] as String? ?? defaultFarmId,
      date: (data['date'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'INR',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      pondIds: pondIds,
    );
  }
}

