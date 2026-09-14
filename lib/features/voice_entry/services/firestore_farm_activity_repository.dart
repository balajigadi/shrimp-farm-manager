import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/services/firestore_service.dart';
import 'farm_activity_repository.dart';

class FirestoreFarmActivityRepository implements FarmActivityRepository {
  FirestoreFarmActivityRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Future<void> addFeedLog(FeedLog log) => _firestore.addFeedLog(log);

  @override
  Future<void> addWaterLog(PondLog log) => _firestore.addWaterLog(log);

  @override
  Future<void> addGrowthSample(
    GrowthSample sample, {
    Map<String, dynamic>? pondGrowthSummary,
  }) {
    return _firestore.addGrowthSample(
      sample,
      pondGrowthSummary: pondGrowthSummary,
    );
  }

  @override
  Future<void> addMortalityLog(MortalityLog log) =>
      _firestore.addMortalityLog(log);
}
