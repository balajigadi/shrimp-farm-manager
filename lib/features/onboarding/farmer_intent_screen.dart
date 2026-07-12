import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prawn_farm_app/data/regions.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../profile/user_profile.dart';
import '../../services/user_profile_service.dart';

class FarmerIntentScreen extends StatefulWidget {
  const FarmerIntentScreen({
    super.key,
    this.supervisorMode = false,
  });

  final bool supervisorMode;

  @override
  State<FarmerIntentScreen> createState() => _FarmerIntentScreenState();
}

class _FarmerIntentScreenState extends State<FarmerIntentScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  FarmerIntent? _intent;
  String? _region;
  bool _saving = false;
  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.supervisorMode
              ? l10n.onboardingSupervisorSetup
              : l10n.onboardingFarmerSetup,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.onboardingYourName,
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = _validateName());
                }
              },
            ),
            const SizedBox(height: 16),
            if (!widget.supervisorMode) ...[
              Text(
                l10n.onboardingIntentTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _intentTile(
                intent: FarmerIntent.buyerNotifications,
                title: l10n.intentBuyerNotifications,
                subtitle: l10n.intentBuyerNotificationsDesc,
              ),
              const SizedBox(height: 10),
              _intentTile(
                intent: FarmerIntent.manageFarm,
                title: l10n.intentManageFarm,
                subtitle: l10n.intentManageFarmDesc,
              ),
              const SizedBox(height: 10),
              _intentTile(
                intent: FarmerIntent.both,
                title: l10n.intentBoth,
                subtitle: l10n.intentBothDesc,
              ),
              const SizedBox(height: 24),
            ],
            Text(
              l10n.onboardingRegionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingRegionSubtitle,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
              onChanged: (v) => setState(() => _region = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: l10n.onboardingPhoneNumber,
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _phoneError,
                helperText: widget.supervisorMode
                    ? l10n.onboardingPhoneOptionalHint
                    : null,
              ),
              onChanged: (_) {
                if (_phoneError != null) {
                  setState(() => _phoneError = _validatePhone());
                }
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.onboardingFinish),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSave {
    if (_region == null || _region!.isEmpty) return false;
    if (widget.supervisorMode) return true;
    return _intent != null;
  }

  String? _validateName() {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      return AppLocalizations.of(context)!.nameInvalid;
    }
    // Letters (any script), spaces, and common name punctuation — no digits.
    if (RegExp(r'[0-9]').hasMatch(name) ||
        !RegExp(r'^[\p{L}\s.\-]+$', unicode: true).hasMatch(name)) {
      return AppLocalizations.of(context)!.nameInvalid;
    }
    return null;
  }

  String? _validatePhone() {
    var digits = _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (widget.supervisorMode && digits.isEmpty) {
      return null;
    }
    if (digits.isEmpty) {
      return AppLocalizations.of(context)!.phoneRequired;
    }
    if (digits.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return AppLocalizations.of(context)!.phoneInvalid;
    }
    return null;
  }

  String? _normalizedPhoneOrNull() {
    var digits = _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.isEmpty) return null;
    return digits;
  }

  Widget _intentTile({
    required FarmerIntent intent,
    required String title,
    required String subtitle,
  }) {
    final selected = _intent == intent;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _intent = intent),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F2F1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF005F73) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check, color: Color(0xFF005F73)),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final intent = _intent;
    final region = _region;
    if (region == null || region.isEmpty) return;
    if (!widget.supervisorMode && intent == null) return;

    final nameError = _validateName();
    final phoneError = _validatePhone();
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
    });
    if (nameError != null || phoneError != null) return;

    final displayName = _nameController.text.trim();
    final phoneNumber = _normalizedPhoneOrNull();

    setState(() => _saving = true);
    try {
      await UserProfileService.instance.completeOnboarding(
        role: widget.supervisorMode ? UserRole.supervisor : UserRole.farmer,
        farmerIntent: widget.supervisorMode ? FarmerIntent.manageFarm : intent,
        region: region,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
      }
      // AuthGate listens to watchProfile() and swaps OnboardingFlow → AppShell.
      // Do not Navigator.pop here — the widget tree is replaced and popping crashes.
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}
