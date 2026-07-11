/* eslint-disable no-console */
const admin = require('firebase-admin');

// Requires: tools/serviceAccountKey.json
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const COLLECTIONS = [
  'ponds',
  'feedLogs',
  'waterLogs',
  'growthSamples',
  'mortalityLogs',
  'expenses',
];

async function countByFarmId(uid) {
  console.log(`\nData counts for UID: ${uid}\n`);

  let grandTotal = 0;
  for (const col of COLLECTIONS) {
    const snap = await db.collection(col).where('farmId', '==', uid).count().get();
    const count = snap.data().count || 0;
    grandTotal += count;
    console.log(`${col.padEnd(14)} : ${count}`);
  }

  console.log('\n-----------------------------');
  console.log(`TOTAL          : ${grandTotal}\n`);
}

async function main() {
  const uid = process.argv[2];
  if (!uid) {
    console.error('Usage: node .\\count_user_data.js <UID>');
    process.exit(1);
  }

  await countByFarmId(uid);
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

