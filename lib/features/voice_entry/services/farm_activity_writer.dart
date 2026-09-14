import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/services/firestore_service.dart';
import 'package:prawn_farm_app/services/growth_analysis_service.dart';
import '../models/farm_activity_draft.dart';
import 'farm_activity_repository.dart';
import 'farm_activity_validator.dart';
import 'firestore_farm_activity_repository.dart';

class FarmActivityWriter {
  FarmActivityWriter({
    FarmActivityRepository? repository,
    GrowthAnalysisService? growthAnalysis,
    String Function()? farmId,
  }) : _repository = repository ?? FirestoreFarmActivityRepository(),
       _growth = growthAnalysis ?? GrowthAnalysisService.instance,
       _farmId = farmId ?? (() => FirestoreService.instance.currentFarmId);

  final FarmActivityRepository _repository;
  final GrowthAnalysisService _growth;
  final String Function() _farmId;
  final FarmActivityValidator _validator = const FarmActivityValidator();

  Future<void> save(
    FarmActivityDraft draft, {
    required List<Pond> ponds,
  }) async {
    final validation = _validator.validate(draft);
    if (!validation.isValid) {
      throw StateError('Draft is not valid to save');
    }
    return switch (draft) {
      FeedActivityDraft d => _saveFeed(d),
      WaterQualityActivityDraft d => _saveWater(d),
      GrowthActivityDraft d => _saveGrowth(d, ponds),
      MortalityActivityDraft d => _saveMortality(d),
      UnknownActivityDraft _ => throw StateError(
        'Cannot save an unknown activity',
      ),
    };
  }

  Future<void> _saveFeed(FeedActivityDraft d) {
    return _repository.addFeedLog(
      FeedLog(
        id: '',
        farmId: _farmId(),
        pondId: d.pondId!,
        dateTime: d.occurredAt,
        feedType: d.feedType!.trim(),
        quantityKg: d.quantityKg!,
        trayStatus: d.trayStatus,
      ),
    );
  }

  Future<void> _saveWater(WaterQualityActivityDraft d) {
    return _repository.addWaterLog(
      PondLog(
        id: '',
        farmId: _farmId(),
        pondId: d.pondId!,
        date: d.occurredAt,
        waterTempC: d.temperatureC!,
        dissolvedOxygen: d.dissolvedOxygen!,
        ph: d.ph!,
        salinityPpt: d.salinityPpt!,
        ammoniaPpm: d.ammoniaPpm!,
        hardnessMgL: d.hardnessMgL!,
        feedKg: 0,
        mortalityCount: 0,
      ),
    );
  }

  Future<void> _saveGrowth(GrowthActivityDraft d, List<Pond> ponds) {
    Pond? pond;
    for (final p in ponds) {
      if (p.id == d.pondId) {
        pond = p;
        break;
      }
    }
    Map<String, dynamic>? summary;
    if (pond != null) {
      final analysis = _growth.analyze(
        stockingDate: pond.stockingDate,
        actualAbw: d.avgBodyWeightGrams!,
        asOf: d.occurredAt,
      );
      summary = _growth.pondSummaryUpdate(
        analysis: analysis,
        survivalPercent: d.survivalPercent!,
      );
    }
    return _repository.addGrowthSample(
      GrowthSample(
        id: '',
        farmId: _farmId(),
        pondId: d.pondId!,
        date: d.occurredAt,
        avgBodyWeightGrams: d.avgBodyWeightGrams!,
        survivalPercent: d.survivalPercent!,
        sampleSize: d.sampleSize ?? 0,
        notes: d.notes ?? '',
      ),
      pondGrowthSummary: summary,
    );
  }

  Future<void> _saveMortality(MortalityActivityDraft d) {
    return _repository.addMortalityLog(
      MortalityLog(
        id: '',
        farmId: _farmId(),
        pondId: d.pondId!,
        dateTime: d.occurredAt,
        count: d.count!,
        reason: d.reason ?? '',
        notes: d.notes ?? '',
      ),
    );
  }
}
