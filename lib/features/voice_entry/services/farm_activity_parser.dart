import 'package:prawn_farm_app/features/pond/pond_model.dart';
import '../models/farm_activity_draft.dart';

abstract interface class FarmActivityParser {
  Future<FarmActivityDraft> parse(
    String transcript, {
    required List<Pond> ponds,
    DateTime? now,
  });
}
