/**
 * Notify farmers when a trader posts a new buyer requirement.
 *
 * Schema (from Flutter app — do not change without updating the client):
 * - requirements.region: string[] (array; client uses arrayContains per mandal)
 * - userSettings.region: string (single mandal)
 * - userSettings.fcmToken: string
 * - userSettings.role: 'farmer' | 'supervisor' | 'trader'
 * - userSettings.farmerIntent: 'buyer_notifications' | 'manage_farm' | 'both'
 *
 * Requires Firebase Blaze plan (pay-as-you-go). Cloud Functions do not run on Spark.
 */
import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { clearInvalidFcmTokens, type FcmTokenTarget } from "./cleanupInvalidTokens";
import {
  buildNotificationBody,
  DAILY_NOTIFICATION_CAP,
  farmerWantsMarketNotifications,
  shouldSkipForDailyCap,
  type RequirementNotifyInput,
  type UserSettingsNotifyInput,
} from "./notifyHelpers";

const db = admin.firestore();
const messaging = admin.messaging();

const FCM_MULTICAST_LIMIT = 500;

/** Matches NotificationService timezone in the Flutter app. */
const MARKET_TIMEZONE = "Asia/Kolkata";

type RequirementDoc = RequirementNotifyInput & {
  traderId?: string;
  region?: string[];
  status?: string;
  createdAt?: admin.firestore.Timestamp;
};

type UserSettingsDoc = UserSettingsNotifyInput & {
  uid?: string;
  region?: string;
};

function startOfTodayKolkata(): Date {
  const now = new Date();
  const dateStr = new Intl.DateTimeFormat("en-CA", {
    timeZone: MARKET_TIMEZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  return new Date(`${dateStr}T00:00:00+05:30`);
}

async function countTraderPostsToday(traderId: string): Promise<number> {
  const start = admin.firestore.Timestamp.fromDate(startOfTodayKolkata());
  const snap = await db
    .collection("requirements")
    .where("traderId", "==", traderId)
    .where("createdAt", ">=", start)
    .get();
  return snap.size;
}

/**
 * Find farmers to notify.
 *
 * Client-side MarketService queries requirements with:
 *   .where('region', arrayContains: farmerRegionString)
 *
 * Inverse: for each mandal on the requirement, query userSettings where
 * region == mandal (equality on string field).
 */
async function loadFarmerTargets(
  requirementRegions: string[],
  traderId: string,
): Promise<FcmTokenTarget[]> {
  const uniqueRegions = [...new Set(requirementRegions.map((r) => r.trim()).filter(Boolean))];
  if (uniqueRegions.length === 0) {
    return [];
  }

  // Firestore `in` supports up to 30 values; requirements usually have 1 mandal.
  const regionsForQuery = uniqueRegions.slice(0, 30);
  const snap = await db
    .collection("userSettings")
    .where("region", "in", regionsForQuery)
    .get();

  const targets: FcmTokenTarget[] = [];
  const seenUids = new Set<string>();

  for (const doc of snap.docs) {
    const data = doc.data() as UserSettingsDoc;
    const uid = doc.id;

    if (uid === traderId || seenUids.has(uid)) {
      continue;
    }
    if (!farmerWantsMarketNotifications(data)) {
      continue;
    }

    const token = data.fcmToken?.trim();
    if (!token) {
      continue;
    }

    seenUids.add(uid);
    targets.push({ uid, token });
  }

  return targets;
}

async function markNotificationsSkipped(
  requirementRef: admin.firestore.DocumentReference,
  reason: string,
): Promise<void> {
  await requirementRef.set(
    {
      notificationsSkipped: true,
      skipReason: reason,
      notificationsSkippedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function sendFarmerNotifications(
  requirementId: string,
  req: RequirementDoc,
  targets: FcmTokenTarget[],
): Promise<void> {
  const body = buildNotificationBody(req);
  let successCount = 0;
  let failureCount = 0;
  let clearedTokens = 0;

  for (let i = 0; i < targets.length; i += FCM_MULTICAST_LIMIT) {
    const chunk = targets.slice(i, i + FCM_MULTICAST_LIMIT);
    const tokens = chunk.map((t) => t.token);

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: "New buyer requirement near you",
        body,
      },
      data: {
        type: "market_requirement",
        requirementId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "market_requirements",
        },
      },
    });

    successCount += response.successCount;
    failureCount += response.failureCount;

    clearedTokens += await clearInvalidFcmTokens(db, response, chunk);
  }

  console.info("FCM multicast complete", {
    requirementId,
    recipients: targets.length,
    successCount,
    failureCount,
    clearedTokens,
  });
}

export const onRequirementCreated = onDocumentCreated(
  {
    document: "requirements/{requirementId}",
    region: "asia-south1",
  },
  async (event) => {
    const requirementId = event.params.requirementId;
    const snap = event.data;
    if (!snap) {
      console.warn("onRequirementCreated: missing snapshot", { requirementId });
      return;
    }

    const req = snap.data() as RequirementDoc;

    if (req.status !== "open") {
      console.info("Skipping notification: requirement not open", {
        requirementId,
        status: req.status,
      });
      return;
    }

    const traderId = req.traderId?.trim();
    if (!traderId) {
      console.warn("Skipping notification: missing traderId", { requirementId });
      return;
    }

    const regions = Array.isArray(req.region) ? req.region : [];
    if (regions.length === 0) {
      console.warn("Skipping notification: empty region array", { requirementId });
      return;
    }

    const postsToday = await countTraderPostsToday(traderId);
    if (shouldSkipForDailyCap(postsToday)) {
      console.info("Daily cap exceeded; skipping farmer notifications", {
        requirementId,
        traderId,
        postsToday,
        cap: DAILY_NOTIFICATION_CAP,
      });
      await markNotificationsSkipped(snap.ref, "daily_cap_exceeded");
      return;
    }

    const targets = await loadFarmerTargets(regions, traderId);
    if (targets.length === 0) {
      console.info("No farmer FCM targets for requirement", {
        requirementId,
        regions,
      });
      return;
    }

    await sendFarmerNotifications(requirementId, req, targets);
  },
);
