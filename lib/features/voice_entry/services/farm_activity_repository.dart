import 'package:prawn_farm_app/features/pond/pond_model.dart';

abstract interface class FarmActivityRepository {
  Future<void> addFeedLog(FeedLog log);
  Future<void> addWaterLog(PondLog log);
  Future<void> addGrowthSample(
    GrowthSample sample, {
    Map<String, dynamic>? pondGrowthSummary,
  });
  Future<void> addMortalityLog(MortalityLog log);
}
