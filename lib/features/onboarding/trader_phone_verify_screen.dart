import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prawn_farm_app/data/regions.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../profile/user_profile.dart';
import '../../services/user_profile_service.dart';

class TraderPhoneVerifyScreen extends StatefulWidget {
  const TraderPhoneVerifyScreen({super.key});

  @override
  State<TraderPhoneVerifyScreen> createState() =>
      _TraderPhoneVerifyScreenState();
}

class _TraderPhoneVerifyScreenState extends State<TraderPhoneVerifyScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  String? _region;
  String? _verificationId;
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTraderVerify),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.onboardingTraderVerifyDesc),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.traderDisplayName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.traderPhone,
                hintText: '+91XXXXXXXXXX',
                border: const OutlineInputBorder(),
              ),
              enabled: !_codeSent,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _region,
              decoration: InputDecoration(
                labelText: l10n.onboardingRegionLabel,
                border: const OutlineInputBorder(),
              ),
              items: FarmRegions.mandals
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: _codeSent ? null : (v) => setState(() => _region = v),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.otpCode,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!_codeSent)
              FilledButton(
                onPressed: _busy ? null : _sendOtp,
                child: Text(l10n.sendOtp),
              )
            else ...[
              FilledButton(
                onPressed: _busy ? null : _verifyOtp,
                child: Text(l10n.verifyAndContinue),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _otpController.clear();
                        }),
                child: Text(l10n.changePhone),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _normalizedPhone {
    var p = _phoneController.text.trim().replaceAll(' ', '');
    if (!p.startsWith('+')) {
      if (p.startsWith('0')) p = p.substring(1);
      p = '+91$p';
    }
    return p;
  }

  Future<void> _sendOtp() async {
    if (_region == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseCompleteFields),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _normalizedPhone,
        verificationCompleted: (credential) async {
          await _finishWithCredential(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? e.code)),
          );
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _busy = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final verificationId = _verificationId;
    if (verificationId == null) return;

    setState(() => _busy = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _otpController.text.trim(),
      );
      await _finishWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishWithCredential(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.linkWithCredential(credential);
    }

    await UserProfileService.instance.completeOnboarding(
      role: UserRole.trader,
      region: _region,
      phoneVerified: true,
      phoneNumber: _normalizedPhone,
      displayName: _nameController.text.trim(),
    );
    // AuthGate rebuilds to AppShell when profile stream updates.
  }
}
