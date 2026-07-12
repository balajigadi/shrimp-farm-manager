import 'package:flutter/widgets.dart';
import 'package:prawn_farm_app/features/profile/user_profile.dart';

/// Destination [AuthGate] would show for a given auth/profile snapshot.
enum AuthGateView {
  loading,
  signIn,
  onboarding,
  legacyBootstrap,
  home,
}

/// Mirrors [AuthGate] branching without Firebase/widget dependencies.
AuthGateView resolveAuthGateView({
  required ConnectionState authConnectionState,
  required bool signedIn,
  required ConnectionState profileConnectionState,
  required bool profileHasData,
  required UserProfile? profile,
  required bool hasPonds,
}) {
  if (authConnectionState == ConnectionState.waiting) {
    return AuthGateView.loading;
  }
  if (!signedIn) {
    return AuthGateView.signIn;
  }

  if (profileConnectionState == ConnectionState.waiting && !profileHasData) {
    return AuthGateView.loading;
  }
  if (profile == null) {
    return AuthGateView.loading;
  }

  if (!profile.onboardingComplete) {
    if (hasPonds) {
      return AuthGateView.legacyBootstrap;
    }
    return AuthGateView.onboarding;
  }

  return AuthGateView.home;
}
