import 'package:prawn_farm_app/features/market/requirement_model.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';

/// Relative expiry label for buyer requirements (e.g. "expires in 3 days").
String formatRequirementExpiry(
  DateTime expiresAt,
  DateTime now,
  AppLocalizations l10n,
) {
  if (!expiresAt.isAfter(now)) {
    return l10n.requirementExpired;
  }

  final diff = expiresAt.difference(now);
  if (diff.inHours < 24) {
    return l10n.requirementExpiresToday;
  }

  final days = diff.inDays;
  if (days == 1) {
    return l10n.requirementExpiresInOneDay;
  }
  return l10n.requirementExpiresInDays(days);
}

bool requirementIsPastExpiry(DateTime expiresAt, DateTime now) =>
    !expiresAt.isAfter(now);

bool requirementShowsExpiredBadge({
  required RequirementStatus status,
  required DateTime expiresAt,
  required DateTime now,
}) {
  return status == RequirementStatus.open && requirementIsPastExpiry(expiresAt, now);
}
