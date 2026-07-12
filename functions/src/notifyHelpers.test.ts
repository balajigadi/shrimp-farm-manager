import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  buildNotificationBody,
  farmerWantsMarketNotifications,
  shouldNotifyFarmerTarget,
  shouldSkipForDailyCap,
} from "./notifyHelpers";

describe("notifyHelpers", () => {
  it("notifies only farmers with buyer intents", () => {
    assert.equal(
      farmerWantsMarketNotifications({
        role: "farmer",
        farmerIntent: "buyer_notifications",
      }),
      true,
    );
    assert.equal(
      farmerWantsMarketNotifications({
        role: "farmer",
        farmerIntent: "both",
      }),
      true,
    );
    assert.equal(
      farmerWantsMarketNotifications({
        role: "farmer",
        farmerIntent: "manage_farm",
      }),
      false,
    );
    assert.equal(
      farmerWantsMarketNotifications({
        role: "trader",
        farmerIntent: "both",
      }),
      false,
    );
  });

  it("builds notification body from requirement fields", () => {
    assert.equal(
      buildNotificationBody({
        traderName: " Demo Trader ",
        quantityNeeded: 3,
        unit: "tons",
        countRange: { min: 30, max: 40 },
      }),
      "Demo Trader needs 3tons, count 30-40",
    );
  });

  it("skips notifications after daily cap", () => {
    assert.equal(shouldSkipForDailyCap(5), false);
    assert.equal(shouldSkipForDailyCap(6), true);
  });

  it("filters farmer targets by trader self and token", () => {
    assert.equal(
      shouldNotifyFarmerTarget({
        uid: "t1",
        traderId: "t1",
        settings: {
          role: "farmer",
          farmerIntent: "both",
          fcmToken: "token",
        },
      }),
      false,
    );
    assert.equal(
      shouldNotifyFarmerTarget({
        uid: "f1",
        traderId: "t1",
        settings: {
          role: "farmer",
          farmerIntent: "both",
          fcmToken: "abc",
        },
      }),
      true,
    );
  });
});
