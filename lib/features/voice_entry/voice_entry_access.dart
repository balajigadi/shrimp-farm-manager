import 'package:prawn_farm_app/features/profile/user_profile.dart';

/// Voice farm entry is only for accounts that already see farm tabs.
bool canAccessVoiceFarmEntry(UserProfile profile) => profile.showsFarmTabs;
