/**
 * Pure helpers for market FCM notification targeting / copy.
 * Kept separate so Node unit tests do not need Firestore/Admin.
 */

export type RequirementNotifyInput = {
  traderName?: string;
  countRange?: { min?: number; max?: number };
  quantityNeeded?: number;
  unit?: string;
};

export type UserSettingsNotifyInput = {
  role?: string;
  farmerIntent?: string;
  fcmToken?: string;
};

/** Hard backstop: max trader posts per day that trigger farmer notifications. */
export const DAILY_NOTIFICATION_CAP = 5;

export function farmerWantsMarketNotifications(
  data: UserSettingsNotifyInput,
): boolean {
  if (data.role !== "farmer") {
    return false;
  }
  const intent = data.farmerIntent;
  return intent === "buyer_notifications" || intent === "both";
}

export function buildNotificationBody(req: RequirementNotifyInput): string {
  const traderName = req.traderName?.trim() || "A trader";
  const quantityNeeded = req.quantityNeeded ?? 0;
  const unit = req.unit ?? "kg";
  const min = req.countRange?.min ?? 0;
  const max = req.countRange?.max ?? 0;
  return `${traderName} needs ${quantityNeeded}${unit}, count ${min}-${max}`;
}

export function shouldSkipForDailyCap(postsToday: number): boolean {
  return postsToday > DAILY_NOTIFICATION_CAP;
}

export function shouldNotifyFarmerTarget(args: {
  uid: string;
  traderId: string;
  settings: UserSettingsNotifyInput;
}): boolean {
  if (args.uid === args.traderId) return false;
  if (!farmerWantsMarketNotifications(args.settings)) return false;
  const token = args.settings.fcmToken?.trim();
  return Boolean(token);
}
