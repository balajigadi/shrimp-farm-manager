import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/profile/user_profile.dart';

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _demoEmails = {
    'demo1@prawnfarm.com',
    'demo2@prawnfarm.com',
    'demo3@prawnfarm.com',
    'demo4@prawnfarm.com',
  };

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('userSettings');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool _isDemoEmail(String? email) =>
      email != null && _demoEmails.contains(email.toLowerCase());

  /// Fallback when demo [userSettings] has not been seeded yet.
  UserProfile _demoProfile(String uid, String? email) {
    switch (email?.toLowerCase()) {
      case 'demo1@prawnfarm.com':
        return UserProfile(
          uid: uid,
          email: email,
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.both,
          region: 'Bhimavaram',
          displayName: 'Ravi Kumar',
          phoneNumber: '9059122848',
          onboardingComplete: true,
          createdAt: DateTime.now(),
        );
      case 'demo2@prawnfarm.com':
        return UserProfile(
          uid: uid,
          email: email,
          role: UserRole.supervisor,
          region: 'Bhimavaram',
          onboardingComplete: true,
          createdAt: DateTime.now(),
        );
      case 'demo3@prawnfarm.com':
        return UserProfile(
          uid: uid,
          email: email,
          role: UserRole.trader,
          region: 'Bhimavaram',
          displayName: 'Demo Trader Co',
          phoneNumber: '9886134848',
          phoneVerified: true,
          onboardingComplete: true,
          createdAt: DateTime.now(),
        );
      case 'demo4@prawnfarm.com':
        return UserProfile(
          uid: uid,
          email: email,
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.buyerNotifications,
          region: 'Bhimavaram',
          displayName: 'Suresh Reddy',
          phoneNumber: '950528889',
          onboardingComplete: true,
          createdAt: DateTime.now(),
        );
      default:
        return UserProfile(
          uid: uid,
          email: email,
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.manageFarm,
          region: 'Bhimavaram',
          onboardingComplete: true,
          createdAt: DateTime.now(),
        );
    }
  }

  UserProfile _profileFromSnapshot(String uid, String? email, DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists && _isDemoEmail(email)) {
      return _demoProfile(uid, email);
    }
    final profile = UserProfile.fromDoc(uid, snap.data());
    if (!profile.onboardingComplete && _isDemoEmail(email)) {
      return _demoProfile(uid, email);
    }
    return profile;
  }

  Stream<UserProfile?> watchProfile() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<UserProfile?>.value(null);
      return _col.doc(user.uid).snapshots().map(
            (snap) => _profileFromSnapshot(user.uid, user.email, snap),
          );
    });
  }

  Future<UserProfile?> getProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final email = FirebaseAuth.instance.currentUser?.email;
    final snap = await _col.doc(uid).get();
    return _profileFromSnapshot(uid, email, snap);
  }

  /// Loads any user's [userSettings/{uid}] (e.g. interested farmers list).
  Future<UserProfile?> getProfileByUid(String uid) async {
    if (uid.isEmpty) return null;
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromDoc(uid, snap.data());
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _col.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<void> completeOnboarding({
    required UserRole role,
    FarmerIntent? farmerIntent,
    String? region,
    bool phoneVerified = false,
    String? phoneNumber,
    String? displayName,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final email = FirebaseAuth.instance.currentUser?.email;

    final profile = UserProfile(
      uid: uid,
      email: email,
      role: role,
      farmerIntent: role == UserRole.farmer ? farmerIntent : null,
      region: region,
      onboardingComplete: true,
      phoneVerified: phoneVerified,
      phoneNumber: phoneNumber,
      displayName: displayName,
    );
    await saveProfile(profile);
  }

  Future<void> saveFcmToken(String token) async {
    final uid = _uid;
    if (uid == null || token.isEmpty) return;
    await _col.doc(uid).set(
      {
        'uid': uid,
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// If user has farm data but no onboarding flag, auto-complete as farmer.
  Future<UserProfile> ensureLegacyProfile({required bool hasPonds}) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Not signed in');
    }
    final existing = await getProfile();
    if (existing != null && existing.onboardingComplete) return existing;

    if (hasPonds) {
      final legacy = UserProfile(
        uid: uid,
        email: FirebaseAuth.instance.currentUser?.email,
        role: UserRole.farmer,
        farmerIntent: FarmerIntent.manageFarm,
        region: existing?.region ?? 'Other',
        onboardingComplete: true,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );
      await saveProfile(legacy);
      return legacy;
    }
    return existing ?? UserProfile(uid: uid);
  }
}
