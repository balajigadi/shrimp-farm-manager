import 'package:cloud_firestore/cloud_firestore.dart';

enum RequirementStatus { open, fulfilled, expired }

extension RequirementStatusX on RequirementStatus {
  String get storageValue => name;

  static RequirementStatus fromString(String? raw) {
    switch (raw) {
      case 'fulfilled':
        return RequirementStatus.fulfilled;
      case 'expired':
        return RequirementStatus.expired;
      default:
        return RequirementStatus.open;
    }
  }
}

class CountRange {
  final int min;
  final int max;

  const CountRange({required this.min, required this.max});

  Map<String, dynamic> toMap() => {'min': min, 'max': max};

  factory CountRange.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const CountRange(min: 0, max: 0);
    return CountRange(
      min: (data['min'] as num?)?.toInt() ?? 0,
      max: (data['max'] as num?)?.toInt() ?? 0,
    );
  }

  String get label => '$min–$max count/kg';
}

class BuyerRequirement {
  final String id;
  final String traderId;
  final String traderName;
  final String traderPhone;
  final CountRange countRange;
  final double quantityNeeded;
  final String unit;
  final double? pricePerKg;
  final List<String> region;
  final RequirementStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int interestedCount;

  const BuyerRequirement({
    required this.id,
    required this.traderId,
    required this.traderName,
    required this.traderPhone,
    required this.countRange,
    required this.quantityNeeded,
    required this.unit,
    this.pricePerKg,
    required this.region,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.interestedCount = 0,
  });

  bool get isActive =>
      status == RequirementStatus.open && expiresAt.isAfter(DateTime.now());

  factory BuyerRequirement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BuyerRequirement(
      id: doc.id,
      traderId: data['traderId'] as String? ?? '',
      traderName: data['traderName'] as String? ?? '',
      traderPhone: data['traderPhone'] as String? ?? '',
      countRange: CountRange.fromMap(
        data['countRange'] as Map<String, dynamic>?,
      ),
      quantityNeeded: (data['quantityNeeded'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? 'kg',
      pricePerKg: (data['pricePerKg'] as num?)?.toDouble(),
      region: (data['region'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: RequirementStatusX.fromString(data['status'] as String?),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      interestedCount: (data['interestedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'traderId': traderId,
      'traderName': traderName,
      'traderPhone': traderPhone,
      'countRange': countRange.toMap(),
      'quantityNeeded': quantityNeeded,
      'unit': unit,
      if (pricePerKg != null) 'pricePerKg': pricePerKg,
      'region': region,
      'status': status.storageValue,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'interestedCount': interestedCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Card-ready row for the Market list (builder output).
class MarketFeedItem {
  final BuyerRequirement requirement;
  final bool matchesRegion;
  final bool isExpired;

  const MarketFeedItem({
    required this.requirement,
    required this.matchesRegion,
    required this.isExpired,
  });
}
