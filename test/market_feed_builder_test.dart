import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/services/market_feed_builder.dart';
import 'package:prawn_farm_app/services/market_rules.dart';
import 'package:prawn_farm_app/features/market/requirement_model.dart';

BuyerRequirement _req({
  required String id,
  required List<String> region,
  required DateTime expiresAt,
  required DateTime createdAt,
  RequirementStatus status = RequirementStatus.open,
  String traderId = 't1',
  int interestedCount = 0,
}) {
  return BuyerRequirement(
    id: id,
    traderId: traderId,
    traderName: 'Trader',
    traderPhone: '+911234567890',
    countRange: const CountRange(min: 30, max: 40),
    quantityNeeded: 100,
    unit: 'kg',
    region: region,
    status: status,
    expiresAt: expiresAt,
    createdAt: createdAt,
    interestedCount: interestedCount,
  );
}

void main() {
  group('MarketFeedBuilder', () {
    test('filters by farmer region', () {
      final now = DateTime(2026, 7, 10);
      final feed = MarketFeedBuilder.build(
        requirements: [
          _req(
            id: '1',
            region: ['Bhimavaram'],
            expiresAt: now.add(const Duration(days: 3)),
            createdAt: now,
          ),
          _req(
            id: '2',
            region: ['Narsapur'],
            expiresAt: now.add(const Duration(days: 3)),
            createdAt: now,
          ),
        ],
        farmerRegion: 'Bhimavaram',
        now: now,
      );
      expect(feed.map((e) => e.requirement.id), ['1']);
    });

    test('excludes expired open requirements for farmers', () {
      final now = DateTime(2026, 7, 10);
      final feed = MarketFeedBuilder.build(
        requirements: [
          _req(
            id: 'live',
            region: ['Bhimavaram'],
            expiresAt: now.add(const Duration(days: 1)),
            createdAt: now,
          ),
          _req(
            id: 'old',
            region: ['Bhimavaram'],
            expiresAt: now.subtract(const Duration(days: 1)),
            createdAt: now,
          ),
        ],
        farmerRegion: 'Bhimavaram',
        now: now,
      );
      expect(feed.map((e) => e.requirement.id), ['live']);
    });

    test('keeps expired open requirements for trader view', () {
      final now = DateTime(2026, 7, 10);
      final feed = MarketFeedBuilder.build(
        requirements: [
          _req(
            id: '1',
            region: ['Bhimavaram'],
            expiresAt: now.subtract(const Duration(days: 1)),
            createdAt: now,
            interestedCount: 2,
          ),
        ],
        farmerRegion: null,
        now: now,
        traderView: true,
        traderId: 't1',
      );
      expect(feed, hasLength(1));
      expect(feed.first.isExpired, isTrue);
    });

    test('sorts newest createdAt first', () {
      final now = DateTime(2026, 7, 10);
      final feed = MarketFeedBuilder.build(
        requirements: [
          _req(
            id: 'older',
            region: ['Bhimavaram'],
            expiresAt: now.add(const Duration(days: 2)),
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          _req(
            id: 'newer',
            region: ['Bhimavaram'],
            expiresAt: now.add(const Duration(days: 2)),
            createdAt: now,
          ),
        ],
        farmerRegion: 'Bhimavaram',
        now: now,
      );
      expect(feed.map((e) => e.requirement.id), ['newer', 'older']);
    });

    test('empty farmer region yields empty feed', () {
      final now = DateTime(2026, 7, 10);
      final feed = MarketFeedBuilder.build(
        requirements: [
          _req(
            id: '1',
            region: ['Bhimavaram'],
            expiresAt: now.add(const Duration(days: 1)),
            createdAt: now,
          ),
        ],
        farmerRegion: '  ',
        now: now,
      );
      expect(feed, isEmpty);
    });
  });

  group('MarketRules', () {
    test('ensureExpiresInFuture rejects past/now', () {
      final now = DateTime(2026, 7, 10, 12);
      expect(
        () => MarketRules.ensureExpiresInFuture(now, now: now),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => MarketRules.ensureExpiresInFuture(
          now.add(const Duration(minutes: 1)),
          now: now,
        ),
        returnsNormally,
      );
    });

    test('detects missing index errors', () {
      expect(
        MarketRules.isMissingIndexError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'requires an index',
          ),
        ),
        isTrue,
      );
      expect(
        MarketRules.isMissingIndexError(
          Exception('The index is currently building'),
        ),
        isTrue,
      );
      expect(MarketRules.isMissingIndexError(Exception('permission')), isFalse);
    });

    test('interest count increments only for new interest', () {
      expect(
        MarketRules.nextInterestedCount(
          wasNewInterest: false,
          currentCount: 3,
        ),
        isNull,
      );
      expect(
        MarketRules.nextInterestedCount(
          wasNewInterest: true,
          currentCount: 3,
        ),
        4,
      );
    });

    test('post quantity and count range validation', () {
      expect(MarketRules.isValidPostQuantity(0), isFalse);
      expect(MarketRules.isValidPostQuantity(1), isTrue);
      expect(MarketRules.isValidCountRange(min: 40, max: 40), isFalse);
      expect(MarketRules.isValidCountRange(min: 30, max: 40), isTrue);
    });
  });

  group('BuyerRequirement.fromMap', () {
    test('parses firestore-shaped maps', () {
      final expires = DateTime(2026, 7, 20);
      final created = DateTime(2026, 7, 10);
      final req = BuyerRequirement.fromMap('abc', {
        'traderId': 't1',
        'traderName': 'Demo',
        'traderPhone': '999',
        'countRange': {'min': 40, 'max': 50},
        'quantityNeeded': 2.5,
        'unit': 'tons',
        'pricePerKg': 100,
        'region': ['Bhimavaram'],
        'status': 'fulfilled',
        'expiresAt': Timestamp.fromDate(expires),
        'createdAt': Timestamp.fromDate(created),
        'interestedCount': 7,
      });

      expect(req.id, 'abc');
      expect(req.countRange.min, 40);
      expect(req.countRange.max, 50);
      expect(req.quantityNeeded, 2.5);
      expect(req.status, RequirementStatus.fulfilled);
      expect(req.interestedCount, 7);
      expect(req.expiresAt, expires);
    });
  });
}
