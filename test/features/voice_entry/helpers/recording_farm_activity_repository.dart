import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/voice_entry/services/farm_activity_repository.dart';

class RecordingFarmActivityRepository implements FarmActivityRepository {
  final feedLogs = <FeedLog>[];
  final waterLogs = <PondLog>[];
  final growthSamples = <GrowthSample>[];
  final mortalityLogs = <MortalityLog>[];
  final pondSummaries = <Map<String, dynamic>?>[];

  Object? failWith;
  Future<void> Function()? beforeComplete;

  @override
  Future<void> addFeedLog(FeedLog log) => _complete(() => feedLogs.add(log));

  @override
  Future<void> addWaterLog(PondLog log) => _complete(() => waterLogs.add(log));

  @override
  Future<void> addGrowthSample(
    GrowthSample sample, {
    Map<String, dynamic>? pondGrowthSummary,
  }) {
    return _complete(() {
      growthSamples.add(sample);
      pondSummaries.add(pondGrowthSummary);
    });
  }

  @override
  Future<void> addMortalityLog(MortalityLog log) =>
      _complete(() => mortalityLogs.add(log));

  int get writeCount =>
      feedLogs.length +
      waterLogs.length +
      growthSamples.length +
      mortalityLogs.length;

  Future<void> _complete(void Function() record) async {
    final pending = beforeComplete;
    if (pending != null) {
      await pending();
    }
    if (failWith != null) {
      throw failWith!;
    }
    record();
  }
}
