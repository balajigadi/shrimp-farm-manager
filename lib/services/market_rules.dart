import 'package:cloud_firestore/cloud_firestore.dart';

/// Pure Market write/query rules used by [MarketService].
abstract final class MarketRules {
  static void ensureExpiresInFuture(DateTime expiresAt, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    if (!expiresAt.isAfter(reference)) {
      throw ArgumentError('expiresAt must be in the future');
    }
  }

  static bool isMissingIndexError(Object error) {
    if (error is FirebaseException) {
      return error.code == 'failed-precondition';
    }
    final message = error.toString().toLowerCase();
    return message.contains('requires an index') ||
        message.contains('index is currently building');
  }

  /// Interest count bump only when the interested doc is newly created.
  static int? nextInterestedCount({
    required bool wasNewInterest,
    required int currentCount,
  }) {
    if (!wasNewInterest) return null;
    return currentCount + 1;
  }

  static bool isValidPostQuantity(double quantity) => quantity > 0;

  static bool isValidCountRange({required int min, required int max}) =>
      min < max;
}
