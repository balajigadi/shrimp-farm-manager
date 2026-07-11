import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/market/requirement_model.dart';
import 'package:prawn_farm_app/services/market_feed_builder.dart';

void main() {
  test('MarketFeedBuilder filters by farmer region', () {
    final now = DateTime(2026, 7, 10);
    final requirements = [
      BuyerRequirement(
        id: '1',
        traderId: 't1',
        traderName: 'Trader A',
        traderPhone: '+911234567890',
        countRange: const CountRange(min: 40, max: 50),
        quantityNeeded: 500,
        unit: 'kg',
        region: ['Bhimavaram'],
        status: RequirementStatus.open,
        expiresAt: now.add(const Duration(days: 3)),
        createdAt: now,
      ),
      BuyerRequirement(
        id: '2',
        traderId: 't2',
        traderName: 'Trader B',
        traderPhone: '+911234567891',
        countRange: const CountRange(min: 30, max: 40),
        quantityNeeded: 300,
        unit: 'kg',
        region: ['Narsapur'],
        status: RequirementStatus.open,
        expiresAt: now.add(const Duration(days: 3)),
        createdAt: now,
      ),
    ];

    final feed = MarketFeedBuilder.build(
      requirements: requirements,
      farmerRegion: 'Bhimavaram',
      now: now,
    );

    expect(feed.length, 1);
    expect(feed.first.requirement.id, '1');
  });

  test('MarketFeedBuilder excludes expired open requirements for farmers', () {
    final now = DateTime(2026, 7, 10);
    final requirements = [
      BuyerRequirement(
        id: '1',
        traderId: 't1',
        traderName: 'Trader A',
        traderPhone: '+911234567890',
        countRange: const CountRange(min: 40, max: 50),
        quantityNeeded: 500,
        unit: 'kg',
        region: ['Bhimavaram'],
        status: RequirementStatus.open,
        expiresAt: now.add(const Duration(days: 3)),
        createdAt: now,
      ),
      BuyerRequirement(
        id: '2',
        traderId: 't2',
        traderName: 'Trader B',
        traderPhone: '+911234567891',
        countRange: const CountRange(min: 30, max: 40),
        quantityNeeded: 300,
        unit: 'kg',
        region: ['Bhimavaram'],
        status: RequirementStatus.open,
        expiresAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
      ),
    ];

    final feed = MarketFeedBuilder.build(
      requirements: requirements,
      farmerRegion: 'Bhimavaram',
      now: now,
    );

    expect(feed.length, 1);
    expect(feed.first.requirement.id, '1');
  });

  test('MarketFeedBuilder keeps expired open requirements for trader view', () {
    final now = DateTime(2026, 7, 10);
    final requirements = [
      BuyerRequirement(
        id: '1',
        traderId: 't1',
        traderName: 'Trader A',
        traderPhone: '+911234567890',
        countRange: const CountRange(min: 40, max: 50),
        quantityNeeded: 500,
        unit: 'kg',
        region: ['Bhimavaram'],
        status: RequirementStatus.open,
        expiresAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
        interestedCount: 2,
      ),
    ];

    final feed = MarketFeedBuilder.build(
      requirements: requirements,
      farmerRegion: null,
      now: now,
      traderView: true,
      traderId: 't1',
    );

    expect(feed.length, 1);
    expect(feed.first.isExpired, isTrue);
  });
}
