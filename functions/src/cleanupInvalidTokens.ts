/**
 * Clears stale FCM tokens on userSettings after multicast send failures.
 *
 * Keep [targets] in the same order as the tokens array passed to
 * sendEachForMulticast so response indices map back to the correct uid.
 */
import * as admin from "firebase-admin";
import type { BatchResponse } from "firebase-admin/messaging";

export type FcmTokenTarget = {
  uid: string;
  token: string;
};

/** FCM error codes that mean the token should be removed from Firestore. */
const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

export async function clearInvalidFcmTokens(
  db: admin.firestore.Firestore,
  batchResponse: BatchResponse,
  targets: FcmTokenTarget[],
): Promise<number> {
  const batch = db.batch();
  let cleared = 0;

  batchResponse.responses.forEach((resp, index) => {
    if (resp.success) {
      return;
    }

    const errorCode = resp.error?.code ?? "unknown";
    const target = targets[index];

    if (!target) {
      console.warn("FCM failure with no matching target index", { index, errorCode });
      return;
    }

    if (!INVALID_TOKEN_CODES.has(errorCode)) {
      console.warn("FCM send failed (token kept)", {
        uid: target.uid,
        errorCode,
        message: resp.error?.message,
      });
      return;
    }

    console.info("Clearing invalid FCM token", {
      uid: target.uid,
      errorCode,
    });

    const ref = db.collection("userSettings").doc(target.uid);
    batch.set(
      ref,
      {
        fcmToken: admin.firestore.FieldValue.delete(),
        fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
      },
      { merge: true },
    );
    cleared += 1;
  });

  if (cleared > 0) {
    await batch.commit();
  }

  return cleared;
}
