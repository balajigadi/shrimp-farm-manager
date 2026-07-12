/* eslint-disable no-console */
const admin = require('firebase-admin');

// Place your service account key here:
// tools/serviceAccountKey.json
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Create these users in Firebase Auth first, then paste UIDs (or let the script create them):
//   demo1@prawnfarm.com  — Farmer "both": Pond A1–A4 + Market
//   demo2@prawnfarm.com  — Supervisor: Pond B1–B4 (farm tabs only)
//   demo3@prawnfarm.com  — Trader: buyer requirements (Market only)
//   demo4@prawnfarm.com  — Farmer "buyer_notifications": Market only (no ponds)
// Password for all: Demo@123
const USER_FARMER_BOTH_UID = 'n4gVfQBF2YR9D2zKkCki20PPBt53';
const USER_SUPERVISOR_UID = '1Ts3Iglr3cWQr0OlcncdaLrgJpK2';
const USER_TRADER_UID = 'TOFAiGt3JnZQSVLUVdosDsKkrB53';
const USER_BUYER_FARMER_UID = 'Jtl6sTdKHwWpGYYrMDQO1Jc8DYB3';

const WIPE_EXISTING = true;

const DEMO_REGION = 'Bhimavaram';

const DEMO_USERS = [
  {
    key: 'farmerBoth',
    uid: USER_FARMER_BOTH_UID,
    email: 'demo1@prawnfarm.com',
    profile: {
      role: 'farmer',
      farmerIntent: 'both',
      region: DEMO_REGION,
      onboardingComplete: true,
      phoneVerified: false,
      displayName: 'Ravi Kumar',
      phoneNumber: '9059122848',
    },
    ponds: ['Pond A1', 'Pond A2', 'Pond A3', 'Pond A4'],
  },
  {
    key: 'supervisor',
    uid: USER_SUPERVISOR_UID,
    email: 'demo2@prawnfarm.com',
    profile: {
      role: 'supervisor',
      region: DEMO_REGION,
      onboardingComplete: true,
      phoneVerified: false,
    },
    ponds: ['Pond B1', 'Pond B2', 'Pond B3', 'Pond B4'],
  },
  {
    key: 'trader',
    uid: USER_TRADER_UID,
    email: 'demo3@prawnfarm.com',
    profile: {
      role: 'trader',
      region: DEMO_REGION,
      displayName: 'Demo Trader Co',
      phoneNumber: '9886134848',
      phoneVerified: true,
      onboardingComplete: true,
    },
    ponds: [],
    requirements: [
      {
        traderName: 'Demo Trader Co',
        traderPhone: '9886134848',
        countMin: 40,
        countMax: 50,
        quantityNeeded: 800,
        unit: 'kg',
        pricePerKg: 320,
        regions: [DEMO_REGION],
      },
      {
        traderName: 'Demo Trader Co',
        traderPhone: '9886134848',
        countMin: 30,
        countMax: 40,
        quantityNeeded: 500,
        unit: 'kg',
        pricePerKg: null,
        regions: [DEMO_REGION],
      },
      {
        traderName: 'Demo Trader Co',
        traderPhone: '9886134848',
        countMin: 35,
        countMax: 45,
        quantityNeeded: 600,
        unit: 'kg',
        pricePerKg: 305,
        regions: ['Amalapuram'],
      },
    ],
  },
  {
    key: 'buyerFarmer',
    uid: USER_BUYER_FARMER_UID,
    email: 'demo4@prawnfarm.com',
    profile: {
      role: 'farmer',
      farmerIntent: 'buyer_notifications',
      region: DEMO_REGION,
      onboardingComplete: true,
      phoneVerified: false,
      displayName: 'Suresh Reddy',
      phoneNumber: '950528889',
    },
    ponds: [],
  },
];

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

function daysFromNow(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d;
}

function at(date, hour, minute) {
  const d = new Date(date);
  d.setHours(hour, minute, 0, 0);
  return d;
}

async function upsertUserSettings(uid, email, profile) {
  await db.collection('userSettings').doc(uid).set(
    {
      uid,
      email,
      ...profile,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function createPond({ farmId, name, pondIndex }) {
  const stockingDate = daysAgo(75 - pondIndex * 6);

  const pondRef = await db.collection('ponds').add({
    farmId,
    name,
    location: pondIndex % 2 === 0 ? 'North Field' : 'South Field',
    areaAcres: 1.2 + pondIndex * 0.5,
    species: 'L. vannamei',
    stockingDate,
    stockingCount: 280000 + pondIndex * 60000,
    initialStockingDensity: 22 + pondIndex,
    daysOfCulture: Math.max(
      0,
      Math.floor((Date.now() - stockingDate.getTime()) / 86400000),
    ),
    avgBodyWeightGrams: 14 + pondIndex * 1.8,
    survivalPercent: 88 - pondIndex * 1.8,
    totalFeedTons: 0,
    fcr: 0,
    estimatedHarvestDate: daysAgo(-35 + pondIndex * 10),
    estimatedBiomassTons: 2.3 + pondIndex * 0.4,
  });

  return pondRef.id;
}

async function seedWaterAndFeed({ farmId, pondId, pondIndex }) {
  for (let days = 14; days >= 1; days--) {
    const dt = at(daysAgo(days), 11, 30);
    const ph = 7.4 + Math.sin(days / 2) * 0.25 + pondIndex * 0.05;
    const doVal = 5.6 + Math.cos(days / 3) * 0.45 - pondIndex * 0.08;
    const ammo = 0.18 + (days % 5) * 0.05 + pondIndex * 0.02;
    const temp = 28.0 + Math.sin(days / 5) * 0.9 + pondIndex * 0.15;
    const sal = 14.5 + pondIndex + Math.cos(days / 4) * 0.9;
    const hardness = 165 + pondIndex * 10 + Math.cos(days / 3) * 18;

    await db.collection('waterLogs').add({
      farmId,
      pondId,
      date: dt,
      waterTempC: +temp.toFixed(1),
      dissolvedOxygen: +doVal.toFixed(1),
      ph: +ph.toFixed(2),
      salinityPpt: +sal.toFixed(1),
      ammoniaPpm: +ammo.toFixed(2),
      hardnessMgL: +hardness.toFixed(0),
      feedKg: 0,
      mortalityCount: 0,
    });
  }

  let totalFeedKg = 0;
  const feedTypes = [
    'Probiotic Starter Feed',
    'Growth Booster Feed',
    'Regular Pellet Feed',
  ];
  const trayPatternsByPond = [
    ['empty', 'empty', 'partial', 'empty', 'partial', 'empty'],
    ['partial', 'partial', 'empty', 'partial', 'full', 'partial'],
    ['full', 'partial', 'full', 'full', 'partial', 'full'],
    ['empty', 'partial', 'full', 'partial', 'empty', 'full'],
  ];
  const trayPattern = trayPatternsByPond[pondIndex % trayPatternsByPond.length];

  for (let days = 14; days >= 1; days--) {
    const trend = 58 + pondIndex * 9 + (14 - days) * 2.6;
    const wave = Math.sin((14 - days) / 1.8) * 5.5;
    const dip = days % 6 === 0 ? -6.5 : 0;
    const base = Math.max(28, trend + wave + dip);

    for (const [hour, step] of [
      [11, 0.55],
      [16, 0.45],
    ]) {
      const dt = at(daysAgo(days), hour, 0);
      const slotAdjust = hour === 11 ? 1.03 : 0.97;
      const qty = base * step * slotAdjust;
      totalFeedKg += qty;
      const trayStatus =
        trayPattern[(days + (hour === 11 ? 0 : 1)) % trayPattern.length];

      await db.collection('feedLogs').add({
        farmId,
        pondId,
        dateTime: dt,
        feedType:
          feedTypes[(days + pondIndex + (hour === 11 ? 0 : 1)) % feedTypes.length],
        quantityKg: +qty.toFixed(1),
        trayStatus,
      });
    }
  }

  for (let i = 4; i >= 0; i--) {
    const dt = at(daysAgo(i * 7), 9, 0);
    const avgBody = 10 + (4 - i) * 2.4 + pondIndex * 0.6;
    const survival = 92 - (4 - i) * 1.3 - pondIndex * 0.6;

    await db.collection('growthSamples').add({
      farmId,
      pondId,
      date: dt,
      avgBodyWeightGrams: +avgBody.toFixed(1),
      survivalPercent: +survival.toFixed(1),
      sampleSize: 50 + pondIndex * 10,
      notes: 'Demo growth sample',
    });
  }

  for (let d = 12; d >= 3; d -= 4) {
    const dt = at(daysAgo(d), 7, 30);
    await db.collection('mortalityLogs').add({
      farmId,
      pondId,
      dateTime: dt,
      count: 6 + pondIndex * 2 + (d % 3),
      reason: 'Bird attack',
      notes: 'Demo mortality entry',
    });
  }

  const cats = ['Feed', 'Seed', 'Labor', 'Electricity', 'Maintenance', 'Other'];
  for (let d = 12; d >= 1; d -= 2) {
    const dt = at(daysAgo(d), 10, 0);
    const cat = cats[(d + pondIndex) % cats.length];
    await db.collection('expenses').add({
      farmId,
      date: dt,
      amount: 1500 + (12 - d) * 380 + pondIndex * 220,
      currency: 'INR',
      description: `${cat} expense (demo)`,
      category: cat,
      pondIds: [pondId],
    });
  }

  return totalFeedKg;
}

async function updatePondTotals({ farmId, pondId, pondIndex, totalFeedKg }) {
  const totalFeedTons = totalFeedKg / 1000.0;
  const biomassTons = 2.1 + pondIndex * 0.45;
  const fcr = totalFeedTons > 0 ? +(totalFeedTons / biomassTons).toFixed(2) : 0;

  await db.collection('ponds').doc(pondId).set(
    {
      totalFeedTons: +totalFeedTons.toFixed(3),
      estimatedBiomassTons: +biomassTons.toFixed(3),
      fcr,
      avgBodyWeightGrams: 18 + pondIndex * 1.6,
      survivalPercent: 87 - pondIndex * 1.4,
    },
    { merge: true },
  );
}

async function wipeFarmDemoData(user) {
  const farmId = user.uid;
  const demoPondNames = new Set(user.ponds.map((n) => n.toLowerCase()));
  const pondDocs = await db.collection('ponds').where('farmId', '==', farmId).get();
  const demoPondDocs = pondDocs.docs.filter((d) => {
    const name = String(d.data().name || '').toLowerCase();
    return demoPondNames.has(name);
  });
  const demoPondIds = demoPondDocs.map((d) => d.id);

  if (demoPondIds.length === 0) {
    return;
  }

  for (const pondId of demoPondIds) {
    for (const col of ['waterLogs', 'feedLogs', 'growthSamples', 'mortalityLogs']) {
      const snap = await db.collection(col).where('pondId', '==', pondId).get();
      await Promise.all(snap.docs.map((d) => d.ref.delete()));
    }
  }

  for (let i = 0; i < demoPondIds.length; i += 10) {
    const chunk = demoPondIds.slice(i, i + 10);
    const expenses = await db
      .collection('expenses')
      .where('farmId', '==', farmId)
      .where('pondIds', 'array-contains-any', chunk)
      .get();
    await Promise.all(expenses.docs.map((d) => d.ref.delete()));
  }

  await Promise.all(demoPondDocs.map((d) => d.ref.delete()));
}

async function wipeTraderRequirements(traderId) {
  if (!traderId || traderId.includes('PASTE_')) {
    return;
  }
  const snap = await db
    .collection('requirements')
    .where('traderId', '==', traderId)
    .get();
  for (const doc of snap.docs) {
    const interested = await doc.ref.collection('interested').get();
    await Promise.all(interested.docs.map((d) => d.ref.delete()));
    await doc.ref.delete();
  }
}

/**
 * Seeds interested/{farmerUid} docs so trader "Interested farmers" sheet
 * shows real displayName / region / phoneNumber in demos.
 */
async function seedInterestedOnRequirement(requirementRef, farmers) {
  if (!farmers?.length) return;

  for (const farmer of farmers) {
    if (!farmer?.uid || String(farmer.uid).includes('PASTE_')) continue;
    const displayName =
      farmer.profile?.displayName?.trim() ||
      (farmer.email ? farmer.email.split('@')[0] : 'Farmer');
    const region = farmer.profile?.region?.trim() || DEMO_REGION;
    const phoneNumber = farmer.profile?.phoneNumber?.trim() || '';

    await requirementRef.collection('interested').doc(farmer.uid).set({
      farmerUid: farmer.uid,
      displayName,
      email: farmer.email || '',
      region,
      phoneNumber,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(
      `    interested: ${displayName} (${farmer.email}) region=${region}`,
    );
  }

  await requirementRef.update({ interestedCount: farmers.length });
}

async function seedRequirements({ traderId, items, interestedFarmers = [] }) {
  const requirementIds = [];
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const data = {
      traderId,
      traderName: item.traderName,
      traderPhone: item.traderPhone,
      countRange: { min: item.countMin, max: item.countMax },
      quantityNeeded: item.quantityNeeded,
      unit: item.unit,
      region: item.regions,
      status: 'open',
      interestedCount: 0,
      expiresAt: admin.firestore.Timestamp.fromDate(daysFromNow(7)),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (item.pricePerKg != null) {
      data.pricePerKg = item.pricePerKg;
    }
    const ref = await db.collection('requirements').add(data);
    requirementIds.push(ref.id);
    console.log(
      `  requirement id=${ref.id} regions=${item.regions.join(',')} qty=${item.quantityNeeded}${item.unit}`,
    );

    // First Bhimavaram requirement gets demo farmers interested (trader sheet demo).
    const isPrimaryDemoReq =
      i === 0 && item.regions.includes(DEMO_REGION) && interestedFarmers.length;
    if (isPrimaryDemoReq) {
      await seedInterestedOnRequirement(ref, interestedFarmers);
    }
  }
  return requirementIds;
}

async function seedFarmUser(user) {
  console.log(`\nSeeding ${user.key} farm=${user.uid} (${user.email})`);

  await upsertUserSettings(user.uid, user.email, user.profile);

  for (let i = 0; i < user.ponds.length; i++) {
    const pondName = user.ponds[i];
    const pondId = await createPond({
      farmId: user.uid,
      name: pondName,
      pondIndex: i,
    });

    const totalFeedKg = await seedWaterAndFeed({
      farmId: user.uid,
      pondId,
      pondIndex: i,
    });

    await updatePondTotals({
      farmId: user.uid,
      pondId,
      pondIndex: i,
      totalFeedKg,
    });

    console.log(`  pond ${pondName} (${pondId})`);
  }
}

async function seedProfileOnlyUser(user) {
  if (!user.uid || user.uid.includes('PASTE_')) {
    console.warn(
      `\nSkipping ${user.key} seed: set UID for ${user.email} or re-run to auto-create Auth user.`,
    );
    return;
  }

  console.log(`\nSeeding ${user.key} profile=${user.uid} (${user.email})`);
  await upsertUserSettings(user.uid, user.email, user.profile);
}

async function seedTraderUser(user, { interestedFarmers = [] } = {}) {
  if (!user.uid || user.uid.includes('PASTE_')) {
    console.warn(
      `\nSkipping trader seed: set USER_TRADER_UID after creating demo3@prawnfarm.com in Auth.`,
    );
    return;
  }

  console.log(`\nSeeding ${user.key} trader=${user.uid} (${user.email})`);

  await upsertUserSettings(user.uid, user.email, user.profile);

  if (user.requirements?.length) {
    console.log('  posting buyer requirements...');
    await seedRequirements({
      traderId: user.uid,
      items: user.requirements,
      interestedFarmers,
    });
  }
}

async function ensureAuthUser(email, displayName) {
  const password = 'Demo@123';
  try {
    const existing = await admin.auth().getUserByEmail(email);
    console.log(`Auth user exists: ${email} uid=${existing.uid}`);
    return existing.uid;
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      const user = await admin.auth().createUser({
        email,
        password,
        displayName,
      });
      console.log(`Created Auth user ${email} uid=${user.uid}`);
      return user.uid;
    }
    throw e;
  }
}

async function run() {
  const cliUid = process.argv[2];
  let usersToSeed = DEMO_USERS.map((u) => ({ ...u }));

  if (cliUid) {
    usersToSeed = [
      {
        ...DEMO_USERS[0],
        uid: cliUid,
        ponds: DEMO_USERS[0].ponds,
      },
    ];
    console.log(`CLI mode: seeding farmer-both data only for uid=${cliUid}`);
  } else {
    for (const user of usersToSeed) {
      if (user.uid.includes('PASTE_')) {
        const displayName =
          user.profile.displayName ??
          user.email.split('@')[0];
        user.uid = await ensureAuthUser(user.email, displayName);
      }
    }
  }

  if (WIPE_EXISTING) {
    for (const user of usersToSeed) {
      if (user.ponds?.length) {
        console.log(`Wiping farm demo data for ${user.key} (${user.uid})...`);
        await wipeFarmDemoData(user);
      }
      if (user.key === 'trader') {
        console.log(`Wiping trader requirements for ${user.uid}...`);
        await wipeTraderRequirements(user.uid);
      }
    }
  }

  // Resolve farmer profiles first so trader requirements can attach interest.
  const farmerBoth = usersToSeed.find((u) => u.key === 'farmerBoth');
  const buyerFarmer = usersToSeed.find((u) => u.key === 'buyerFarmer');
  const interestedFarmers = [farmerBoth, buyerFarmer].filter(
    (u) => u && u.uid && !String(u.uid).includes('PASTE_'),
  );

  for (const user of usersToSeed) {
    if (user.ponds?.length) {
      await seedFarmUser(user);
    } else if (user.key === 'trader') {
      await seedTraderUser(user, { interestedFarmers });
    } else {
      await seedProfileOnlyUser(user);
    }
  }

  console.log('\nDemo seed complete.');
  console.log('\nDemo logins (password Demo@123):');
  console.log('  demo1@prawnfarm.com  — Farmer (both): Pond A1–A4 + Market');
  console.log('  demo2@prawnfarm.com  — Supervisor: Pond B1–B4');
  console.log('  demo3@prawnfarm.com  — Trader: post/view requirements');
  console.log('  demo4@prawnfarm.com  — Farmer (notifications only): Market only');
  console.log(
    '\nTrader interested sheet: first Bhimavaram requirement includes',
  );
  for (const f of interestedFarmers) {
    console.log(
      `  - ${f.profile.displayName} / ${f.profile.region} (${f.email})`,
    );
  }
  process.exit(0);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
