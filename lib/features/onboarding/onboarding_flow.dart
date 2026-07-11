import 'package:flutter/material.dart';
import 'role_picker_screen.dart';

class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return RolePickerScreen(
      onRoleSelected: (_) {},
    );
  }
}
