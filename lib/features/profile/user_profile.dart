import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, supervisor, trader }

enum FarmerIntent { buyerNotifications, manageFarm, both }

extension UserRoleX on UserRole {
  String get storageValue {
    switch (this) {
      case UserRole.farmer:
        return 'farmer';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.trader:
        return 'trader';
    }
  }

  static UserRole fromString(String? raw) {
    switch (raw) {
      case 'supervisor':
        return UserRole.supervisor;
      case 'trader':
        return UserRole.trader;
      default:
        return UserRole.farmer;
    }
  }
}

extension FarmerIntentX on FarmerIntent {
  String get storageValue {
    switch (this) {
      case FarmerIntent.buyerNotifications:
        return 'buyer_notifications';
      case FarmerIntent.manageFarm:
        return 'manage_farm';
      case FarmerIntent.both:
        return 'both';
    }
  }

  static FarmerIntent fromString(String? raw) {
    switch (raw) {
      case 'buyer_notifications':
        return FarmerIntent.buyerNotifications;
      case 'manage_farm':
        return FarmerIntent.manageFarm;
      case 'both':
        return FarmerIntent.both;
      default:
        return FarmerIntent.manageFarm;
    }
  }

  bool get showsMarket =>
      this == FarmerIntent.buyerNotifications || this == FarmerIntent.both;

  bool get showsFarm =>
      this == FarmerIntent.manageFarm || this == FarmerIntent.both;
}

/// Per-user profile stored on [userSettings/{uid}] (same doc as alert settings).
class UserProfile {
  final String uid;
  final String? email;
  final UserRole role;
  final FarmerIntent? farmerIntent;
  final String? region;
  final bool onboardingComplete;
  final bool phoneVerified;
  final String? phoneNumber;
  final String? displayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    this.email,
    this.role = UserRole.farmer,
    this.farmerIntent,
    this.region,
    this.onboardingComplete = false,
    this.phoneVerified = false,
    this.phoneNumber,
    this.displayName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isTrader => role == UserRole.trader;

  bool get isFarmerOrSupervisor =>
      role == UserRole.farmer || role == UserRole.supervisor;

  bool get showsMarketTab {
    if (role == UserRole.trader) return true;
    if (role == UserRole.supervisor) return false;
    return farmerIntent?.showsMarket ?? false;
  }

  bool get showsFarmTabs {
    if (role == UserRole.trader) return false;
    if (role == UserRole.supervisor) return true;
    return farmerIntent?.showsFarm ?? true;
  }

  int get preferredInitialTabIndex => showsMarketTab ? 0 : 0;

  factory UserProfile.fromDoc(String uid, Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return UserProfile(uid: uid);
    }
    return UserProfile(
      uid: uid,
      email: data['email'] as String?,
      role: UserRoleX.fromString(data['role'] as String?),
      farmerIntent: data['farmerIntent'] == null
          ? null
          : FarmerIntentX.fromString(data['farmerIntent'] as String?),
      region: data['region'] as String?,
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      phoneVerified: data['phoneVerified'] as bool? ?? false,
      phoneNumber: data['phoneNumber'] as String?,
      displayName: data['displayName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool merge = true}) {
    return {
      'uid': uid,
      if (email != null) 'email': email,
      'role': role.storageValue,
      if (farmerIntent != null) 'farmerIntent': farmerIntent!.storageValue,
      if (region != null) 'region': region,
      'onboardingComplete': onboardingComplete,
      'phoneVerified': phoneVerified,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (displayName != null) 'displayName': displayName,
      if (!merge || createdAt == null)
        'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? email,
    UserRole? role,
    FarmerIntent? farmerIntent,
    String? region,
    bool? onboardingComplete,
    bool? phoneVerified,
    String? phoneNumber,
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      role: role ?? this.role,
      farmerIntent: farmerIntent ?? this.farmerIntent,
      region: region ?? this.region,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
