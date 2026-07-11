import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../profile/user_profile.dart';
import 'farmer_intent_screen.dart';
import 'trader_phone_verify_screen.dart';

class RolePickerScreen extends StatefulWidget {
  const RolePickerScreen({
    super.key,
    required this.onRoleSelected,
  });

  final void Function(UserRole role) onRoleSelected;

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingWelcome),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.onboardingRoleTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingRoleSubtitle,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            _roleTile(
              role: UserRole.farmer,
              title: l10n.roleFarmer,
              subtitle: l10n.roleFarmerDesc,
              icon: Icons.agriculture_outlined,
            ),
            const SizedBox(height: 12),
            _roleTile(
              role: UserRole.supervisor,
              title: l10n.roleSupervisor,
              subtitle: l10n.roleSupervisorDesc,
              icon: Icons.supervisor_account_outlined,
            ),
            const SizedBox(height: 12),
            _roleTile(
              role: UserRole.trader,
              title: l10n.roleTrader,
              subtitle: l10n.roleTraderDesc,
              icon: Icons.storefront_outlined,
            ),
            const Spacer(),
            FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => _continueWithRole(context),
              child: Text(l10n.onboardingContinue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleTile({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selected == role;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selected = role),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F2F1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF005F73) : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF005F73), size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF005F73)),
          ],
        ),
      ),
    );
  }

  void _continueWithRole(BuildContext context) {
    final role = _selected!;
    widget.onRoleSelected(role);

    switch (role) {
      case UserRole.farmer:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FarmerIntentScreen(),
          ),
        );
        break;
      case UserRole.supervisor:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FarmerIntentScreen(supervisorMode: true),
          ),
        );
        break;
      case UserRole.trader:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TraderPhoneVerifyScreen(),
          ),
        );
        break;
    }
  }
}
