import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/auth/auth_routing.dart';
import 'package:prawn_farm_app/features/profile/user_profile.dart';

void main() {
  group('UserProfile tab visibility', () {
    test('trader sees market only', () {
      const p = UserProfile(uid: 'u', role: UserRole.trader);
      expect(p.showsMarketTab, isTrue);
      expect(p.showsFarmTabs, isFalse);
    });

    test('supervisor sees farm only', () {
      const p = UserProfile(uid: 'u', role: UserRole.supervisor);
      expect(p.showsMarketTab, isFalse);
      expect(p.showsFarmTabs, isTrue);
    });

    test('farmer intents control tabs', () {
      expect(
        const UserProfile(
          uid: 'u',
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.buyerNotifications,
        ).showsMarketTab,
        isTrue,
      );
      expect(
        const UserProfile(
          uid: 'u',
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.buyerNotifications,
        ).showsFarmTabs,
        isFalse,
      );
      expect(
        const UserProfile(
          uid: 'u',
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.manageFarm,
        ).showsMarketTab,
        isFalse,
      );
      expect(
        const UserProfile(
          uid: 'u',
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.both,
        ).showsMarketTab,
        isTrue,
      );
      expect(
        const UserProfile(
          uid: 'u',
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.both,
        ).showsFarmTabs,
        isTrue,
      );
    });

    test('fromDoc parses role and intent storage values', () {
      final profile = UserProfile.fromDoc('uid1', {
        'email': 'a@b.com',
        'role': 'trader',
        'farmerIntent': 'both',
        'region': 'Bhimavaram',
        'onboardingComplete': true,
        'phoneVerified': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      expect(profile.role, UserRole.trader);
      expect(profile.farmerIntent, FarmerIntent.both);
      expect(profile.onboardingComplete, isTrue);
      expect(profile.region, 'Bhimavaram');
    });
  });

  group('resolveAuthGateView', () {
    const incomplete = UserProfile(uid: 'u', onboardingComplete: false);
    const complete = UserProfile(uid: 'u', onboardingComplete: true);

    test('waiting auth -> loading', () {
      expect(
        resolveAuthGateView(
          authConnectionState: ConnectionState.waiting,
          signedIn: false,
          profileConnectionState: ConnectionState.waiting,
          profileHasData: false,
          profile: null,
          hasPonds: false,
        ),
        AuthGateView.loading,
      );
    });

    test('signed out -> signIn', () {
      expect(
        resolveAuthGateView(
          authConnectionState: ConnectionState.active,
          signedIn: false,
          profileConnectionState: ConnectionState.active,
          profileHasData: false,
          profile: null,
          hasPonds: false,
        ),
        AuthGateView.signIn,
      );
    });

    test('signed in incomplete without ponds -> onboarding', () {
      expect(
        resolveAuthGateView(
          authConnectionState: ConnectionState.active,
          signedIn: true,
          profileConnectionState: ConnectionState.active,
          profileHasData: true,
          profile: incomplete,
          hasPonds: false,
        ),
        AuthGateView.onboarding,
      );
    });

    test('signed in incomplete with ponds -> legacyBootstrap', () {
      expect(
        resolveAuthGateView(
          authConnectionState: ConnectionState.active,
          signedIn: true,
          profileConnectionState: ConnectionState.active,
          profileHasData: true,
          profile: incomplete,
          hasPonds: true,
        ),
        AuthGateView.legacyBootstrap,
      );
    });

    test('signed in complete -> home', () {
      expect(
        resolveAuthGateView(
          authConnectionState: ConnectionState.active,
          signedIn: true,
          profileConnectionState: ConnectionState.active,
          profileHasData: true,
          profile: complete,
          hasPonds: false,
        ),
        AuthGateView.home,
      );
    });
  });
}
