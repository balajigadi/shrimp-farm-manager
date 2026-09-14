import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/services/pond_resolver.dart';
import '../helpers/test_ponds.dart';

void main() {
  const resolver = PondResolver();
  final ponds = demoPonds();

  test('pond 1 / pond one / one', () {
    expect(resolver.resolve('pond 1', ponds).pond?.id, 'p1');
    expect(resolver.resolve('Pond 1', ponds).pond?.id, 'p1');
    expect(resolver.resolve('pond one', ponds).pond?.id, 'p1');
    expect(resolver.resolve('one', ponds).status, PondResolveStatus.resolved);
    expect(resolver.resolve('one', ponds).pond?.id, 'p1');
  });

  test('south pond by name', () {
    final result = resolver.resolve('south pond', ponds);
    expect(result.status, PondResolveStatus.resolved);
    expect(result.pond?.id, 'ps');
  });

  test('unknown reference', () {
    final result = resolver.resolve('west pond', ponds);
    expect(result.status, PondResolveStatus.unknown);
    expect(result.pond, isNull);
  });

  test('empty reference is unknown', () {
    expect(resolver.resolve(null, ponds).status, PondResolveStatus.unknown);
    expect(resolver.resolve('  ', ponds).status, PondResolveStatus.unknown);
  });

  test('ambiguous names are not chosen silently', () {
    final local = [
      testPond(id: 'a', name: 'Pond 2'),
      testPond(id: 'b', name: 'Pond Two'),
    ];
    final result = resolver.resolve('pond 2', local);
    expect(result.status, PondResolveStatus.ambiguous);
    expect(result.pond, isNull);
    expect(result.candidates, hasLength(2));
  });

  test('rendo maps to pond 2', () {
    expect(resolver.resolve('rendo pond', ponds).pond?.id, 'p2');
  });

  test('Telugu script south pond matches South Pond', () {
    final result = resolver.resolve('సౌత్ పాండ్', ponds);
    expect(result.status, PondResolveStatus.resolved);
    expect(result.pond?.id, 'ps');
  });

  test('Telugu script rendo pond matches Pond 2', () {
    expect(resolver.resolve('రెండో పాండ్', ponds).pond?.id, 'p2');
  });

  test('South Point fuzzy-matches unique South Pond', () {
    final local = [
      testPond(id: 'n', name: 'North Pond'),
      testPond(id: 's', name: 'South Pond'),
    ];
    final result = resolver.resolve('South Point', local);
    expect(result.status, PondResolveStatus.resolved);
    expect(result.pond?.id, 's');
    expect(result.matchKind, PondMatchKind.fuzzy);
  });

  test(
    'South Point is ambiguous when South Pond and South Point Farm exist',
    () {
      final local = [
        testPond(id: 's', name: 'South Pond'),
        testPond(id: 'f', name: 'South Point Farm'),
      ];
      final result = resolver.resolve('South Point', local);
      expect(result.status, PondResolveStatus.ambiguous);
      expect(result.pond, isNull);
      expect(result.candidates.map((p) => p.id), containsAll(['s', 'f']));
    },
  );

  test('Nursery still resolves by name among compass ponds', () {
    final local = [
      testPond(id: 'n', name: 'North Pond'),
      testPond(id: 's', name: 'South Pond'),
      testPond(id: 'u', name: 'Nursery'),
    ];
    final result = resolver.resolve('Nursery', local);
    expect(result.status, PondResolveStatus.resolved);
    expect(result.pond?.id, 'u');
    expect(result.matchKind, PondMatchKind.exact);
  });

  test('unrelated point does not match South Pond', () {
    final result = resolver.resolve('point', [
      testPond(id: 's', name: 'South Pond'),
    ]);
    expect(result.status, PondResolveStatus.unknown);
    expect(result.pond, isNull);
  });
}
