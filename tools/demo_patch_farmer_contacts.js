/* eslint-disable no-console */
/**
 * Patches demo contacts on userSettings + interested docs + trader requirements.
 *
 * Usage:
 *   node --use-system-ca tools/demo_patch_farmer_contacts.js
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

const PATCHES = [
  {
    email: 'demo1@prawnfarm.com',
    role: 'farmer',
    displayName: 'Ravi Kumar',
    phoneNumber: '9059122848',
    region: 'Bhimavaram',
  },
  {
    email: 'demo4@prawnfarm.com',
    role: 'farmer',
    displayName: 'Suresh Reddy',
    phoneNumber: '9505288889',
    region: 'Bhimavaram',
  },
  {
    email: 'demo3@prawnfarm.com',
    role: 'trader',
    displayName: 'Demo Trader Co',
    phoneNumber: '9886134848',
    region: 'Bhimavaram',
  },
];

function normalizePhone(phone) {
  let digits = String(phone || '').replace(/\D/g, '');
  if (digits.startsWith('0')) digits = digits.slice(1);
  if (digits.startsWith('91') && digits.length === 12) {
    digits = digits.slice(2);
  }
  return digits;
}

async function patchByEmail(patch) {
  const user = await admin.auth().getUserByEmail(patch.email);
  const phoneNumber = normalizePhone(patch.phoneNumber);
  const ref = db.collection('userSettings').doc(user.uid);
  await ref.set(
    {
      uid: user.uid,
      email: patch.email,
      displayName: patch.displayName,
      phoneNumber,
      region: patch.region,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  console.log(
    `Patched userSettings/${user.uid} (${patch.email}): ` +
      `${patch.displayName}, ${patch.region}, ${phoneNumber}`,
  );
  if (phoneNumber.length !== 10) {
    console.warn(
      `  WARNING: ${patch.email} phone has ${phoneNumber.length} digits (expected 10).`,
    );
  }

  if (patch.role === 'farmer') {
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
          phoneNumber,
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

  if (patch.role === 'trader') {
    const reqSnap = await db
      .collection('requirements')
      .where('traderId', '==', user.uid)
      .get();
    await Promise.all(
      reqSnap.docs.map((doc) =>
        doc.ref.set(
          {
            traderPhone: phoneNumber,
            traderName: patch.displayName,
          },
          { merge: true },
        ),
      ),
    );
    console.log(
      `  updated traderPhone on ${reqSnap.size} requirement(s) for ${patch.email}`,
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
  console.log('\nDone. Re-open Interested farmers as demo3.');
  process.exit(0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
