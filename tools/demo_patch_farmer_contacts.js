/* eslint-disable no-console */
/**
 * Patches demo farmer userSettings with displayName / phoneNumber / region
 * so the trader "Interested farmers" sheet populates without a full reseed.
 *
 * Usage (from repo root, with tools/serviceAccountKey.json present):
 *   node tools/demo_patch_farmer_contacts.js
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const PATCHES = [
  {
    email: 'demo1@prawnfarm.com',
    displayName: 'Ravi Kumar',
    phoneNumber: '9849012345',
    region: 'Bhimavaram',
  },
  {
    email: 'demo4@prawnfarm.com',
    displayName: 'Suresh Reddy',
    phoneNumber: '9876543210',
    region: 'Bhimavaram',
  },
];

async function patchByEmail(patch) {
  const user = await admin.auth().getUserByEmail(patch.email);
  const ref = db.collection('userSettings').doc(user.uid);
  await ref.set(
    {
      uid: user.uid,
      email: patch.email,
      displayName: patch.displayName,
      phoneNumber: patch.phoneNumber,
      region: patch.region,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  console.log(
    `Patched userSettings/${user.uid} (${patch.email}): ` +
      `${patch.displayName}, ${patch.region}, ${patch.phoneNumber}`,
  );

  // Also refresh denormalized fields on any existing interested docs.
  const reqSnap = await db.collection('requirements').get();
  let updatedInterest = 0;
  for (const req of reqSnap.docs) {
    const interestRef = req.ref.collection('interested').doc(user.uid);
    const interestSnap = await interestRef.get();
    if (!interestSnap.exists) continue;
    await interestRef.set(
      {
        farmerUid: user.uid,
        displayName: patch.displayName,
        email: patch.email,
        region: patch.region,
        phoneNumber: patch.phoneNumber,
      },
      { merge: true },
    );
    updatedInterest += 1;
  }
  if (updatedInterest > 0) {
    console.log(
      `  updated ${updatedInterest} interested doc(s) for ${patch.email}`,
    );
  }
}

async function run() {
  for (const patch of PATCHES) {
    try {
      await patchByEmail(patch);
    } catch (e) {
      console.error(`Failed for ${patch.email}:`, e.message || e);
    }
  }
  console.log('\nDone. Re-open Interested farmers in the trader demo.');
  process.exit(0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
