import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/market/requirement_model.dart';
import 'market_feed_builder.dart';
/// Firestore-backed market feed; uses [MarketFeedBuilder] for filtering/sorting.
class MarketService {
  MarketService._();

  static final MarketService instance = MarketService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requirementsCol =>
      _db.collection('requirements');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Farmer view: open, non-expired requirements for region.
  ///
  /// Prefers server-side `expiresAt` filter (needs composite index in
  /// firestore.indexes.json). While that index is building, falls back to the
  /// legacy query and filters expiry in [MarketFeedBuilder].
  Stream<List<MarketFeedItem>> watchFeedForFarmer(String? region) {
    if (region == null || region.isEmpty) {
      return Stream<List<MarketFeedItem>>.value([]);
    }

    StreamSubscription<List<MarketFeedItem>>? subscription;
    final controller = StreamController<List<MarketFeedItem>>();
    var usingFallback = false;

    void listenFallback() {
      if (controller.isClosed || usingFallback) return;
      usingFallback = true;
      subscription?.cancel();
      subscription = _farmerFeedQuery(
        region: region,
        filterExpiryOnServer: false,
      ).listen(
        controller.add,
        onError: (error, stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
      );
    }

    controller.onListen = () {
      subscription = _farmerFeedQuery(
        region: region,
        filterExpiryOnServer: true,
      ).listen(
        controller.add,
        onError: (Object error, StackTrace stackTrace) {
          if (!usingFallback && _isMissingIndexError(error)) {
            listenFallback();
            return;
          }
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        },
        onDone: () {
          if (!usingFallback && !controller.isClosed) controller.close();
        },
        cancelOnError: false,
      );
    };

    controller.onCancel = () => subscription?.cancel();
    return controller.stream;
  }

  Stream<List<MarketFeedItem>> _farmerFeedQuery({
    required String region,
    required bool filterExpiryOnServer,
  }) {
    Query<Map<String, dynamic>> query = _requirementsCol
        .where('region', arrayContains: region)
        .where('status', isEqualTo: 'open');

    if (filterExpiryOnServer) {
      query = query
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.limit(50).snapshots().map(
          (snap) => _buildFarmerFeed(snap, region),
        );
  }

  List<MarketFeedItem> _buildFarmerFeed(
    QuerySnapshot<Map<String, dynamic>> snap,
    String region,
  ) {
    final raw = snap.docs.map(BuyerRequirement.fromDoc).toList();
    return MarketFeedBuilder.build(
      requirements: raw,
      farmerRegion: region,
      now: DateTime.now(),
    );
  }

  bool _isMissingIndexError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'failed-precondition';
    }
    final message = error.toString().toLowerCase();
    return message.contains('requires an index') ||
        message.contains('index is currently building');
  }

  /// Trader view: own requirements (all statuses).
  Stream<List<MarketFeedItem>> watchFeedForTrader() {
    final uid = _uid;
    if (uid == null) return Stream<List<MarketFeedItem>>.value([]);

    return _requirementsCol
        .where('traderId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      final raw = snap.docs.map(BuyerRequirement.fromDoc).toList();
      return MarketFeedBuilder.build(
        requirements: raw,
        farmerRegion: null,
        now: DateTime.now(),
        traderView: true,
        traderId: uid,
      );
    });
  }

  /// One-shot fallback using the legacy index (region + status + createdAt).
  Future<List<MarketFeedItem>> fetchFeedForFarmerFallback(String? region) async {
    if (region == null || region.isEmpty) return [];

    final snap = await _requirementsCol
        .where('region', arrayContains: region)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    return _buildFarmerFeed(snap, region);
  }

  Future<void> createRequirement({
    required String traderName,
    required String traderPhone,
    required CountRange countRange,
    required double quantityNeeded,
    required String unit,
    double? pricePerKg,
    required List<String> region,
    required DateTime expiresAt,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    if (!expiresAt.isAfter(DateTime.now())) {
      throw ArgumentError('expiresAt must be in the future');
    }

    final req = BuyerRequirement(
      id: '',
      traderId: uid,
      traderName: traderName,
      traderPhone: traderPhone,
      countRange: countRange,
      quantityNeeded: quantityNeeded,
      unit: unit,
      pricePerKg: pricePerKg,
      region: region,
      status: RequirementStatus.open,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
      interestedCount: 0,
    );

    await _requirementsCol.add(req.toFirestore());
  }

  /// Records farmer interest idempotently (one doc per farmer in subcollection).
  Future<void> recordInterest(String requirementId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }

    final reqRef = _requirementsCol.doc(requirementId);
    final interestRef = reqRef.collection('interested').doc(uid);

    try {
      await _db.runTransaction<void>((tx) async {
        // Firestore transactions: all reads before any writes.
        final interestSnap = await tx.get(interestRef);
        final wasNew = !interestSnap.exists;

        DocumentSnapshot<Map<String, dynamic>>? reqSnap;
        if (wasNew) {
          reqSnap = await tx.get(reqRef);
          if (!reqSnap.exists) {
            return;
          }
        }

        tx.set(interestRef, {
          'farmerUid': uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (wasNew && reqSnap != null) {
          final current =
              (reqSnap.data()?['interestedCount'] as num?)?.toInt() ?? 0;
          tx.update(reqRef, {'interestedCount': current + 1});
        }
      });
    } on FirebaseException catch (e) {
      throw StateError('Failed to record interest: ${e.message ?? e.code}');
    }
  }

  Future<void> updateRequirementStatus(
    String requirementId,
    RequirementStatus status,
  ) async {
    await _requirementsCol.doc(requirementId).set(
      {
        'status': status.storageValue,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
