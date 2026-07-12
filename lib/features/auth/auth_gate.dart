import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prawn_farm_app/features/auth/auth_routing.dart';
import 'package:prawn_farm_app/features/auth/sign_in_screen.dart';
import 'package:prawn_farm_app/features/onboarding/onboarding_flow.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/profile/user_profile.dart';
import 'package:prawn_farm_app/features/shell/app_shell.dart';
import 'package:prawn_farm_app/services/firestore_service.dart';
import 'package:prawn_farm_app/services/user_profile_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return StreamBuilder<List<Pond>>(
          stream: user == null
              ? Stream<List<Pond>>.value(const [])
              : FirestoreService.instance.watchPonds(),
          builder: (context, pondSnapshot) {
            return StreamBuilder<UserProfile?>(
              stream: user == null
                  ? Stream<UserProfile?>.value(null)
                  : UserProfileService.instance.watchProfile(),
              builder: (context, profileSnapshot) {
                final view = resolveAuthGateView(
                  authConnectionState: authSnapshot.connectionState,
                  signedIn: user != null,
                  profileConnectionState: profileSnapshot.connectionState,
                  profileHasData: profileSnapshot.hasData,
                  profile: profileSnapshot.data,
                  hasPonds: (pondSnapshot.data ?? const []).isNotEmpty,
                );

                switch (view) {
                  case AuthGateView.loading:
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  case AuthGateView.signIn:
                    return const SignInScreen();
                  case AuthGateView.onboarding:
                    return const OnboardingFlow();
                  case AuthGateView.legacyBootstrap:
                    return _LegacyProfileLoader(
                      onReady: (resolved) => AppShell(profile: resolved),
                    );
                  case AuthGateView.home:
                    return AppShell(profile: profileSnapshot.data!);
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Auto-complete onboarding for users who already have pond data.
class _LegacyProfileLoader extends StatefulWidget {
  const _LegacyProfileLoader({required this.onReady});

  final Widget Function(UserProfile resolved) onReady;

  @override
  State<_LegacyProfileLoader> createState() => _LegacyProfileLoaderState();
}

class _LegacyProfileLoaderState extends State<_LegacyProfileLoader> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await UserProfileService.instance.ensureLegacyProfile(
      hasPonds: true,
    );
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.onReady(_profile!);
  }
}
