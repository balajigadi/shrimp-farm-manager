import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Prawn Farm Manager'**
  String get appTitle;

  /// No description provided for @tabPonds.
  ///
  /// In en, this message translates to:
  /// **'Ponds'**
  String get tabPonds;

  /// No description provided for @tabWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get tabWater;

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get tabFeed;

  /// No description provided for @tabGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get tabGrowth;

  /// No description provided for @tabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tabExpenses;

  /// No description provided for @tabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tabReports;

  /// No description provided for @titlePondOverview.
  ///
  /// In en, this message translates to:
  /// **'Pond Overview'**
  String get titlePondOverview;

  /// No description provided for @titleWaterQuality.
  ///
  /// In en, this message translates to:
  /// **'Water Quality'**
  String get titleWaterQuality;

  /// No description provided for @titleFeedManagement.
  ///
  /// In en, this message translates to:
  /// **'Feed Management'**
  String get titleFeedManagement;

  /// No description provided for @titleGrowthSampling.
  ///
  /// In en, this message translates to:
  /// **'Growth Sampling'**
  String get titleGrowthSampling;

  /// No description provided for @titleExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get titleExpenses;

  /// No description provided for @titleReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get titleReports;

  /// No description provided for @titleMortalityLog.
  ///
  /// In en, this message translates to:
  /// **'Mortality Log'**
  String get titleMortalityLog;

  /// No description provided for @titlePonds.
  ///
  /// In en, this message translates to:
  /// **'Ponds'**
  String get titlePonds;

  /// No description provided for @allPonds.
  ///
  /// In en, this message translates to:
  /// **'All ponds'**
  String get allPonds;

  /// No description provided for @logMortality.
  ///
  /// In en, this message translates to:
  /// **'Log Mortality'**
  String get logMortality;

  /// No description provided for @pleaseSelectPondFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a pond first.'**
  String get pleaseSelectPondFirst;

  /// No description provided for @feedEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Feed entry saved.'**
  String get feedEntrySaved;

  /// No description provided for @waterQualityLogSaved.
  ///
  /// In en, this message translates to:
  /// **'Water quality log saved.'**
  String get waterQualityLogSaved;

  /// No description provided for @growthSampleSaved.
  ///
  /// In en, this message translates to:
  /// **'Growth sample saved. Pond metrics updated.'**
  String get growthSampleSaved;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved.'**
  String get expenseSaved;

  /// No description provided for @mortalityLogSaved.
  ///
  /// In en, this message translates to:
  /// **'Mortality log saved.'**
  String get mortalityLogSaved;

  /// No description provided for @pleaseEnterAllValues.
  ///
  /// In en, this message translates to:
  /// **'Please enter all values correctly.'**
  String get pleaseEnterAllValues;

  /// No description provided for @pondOverview.
  ///
  /// In en, this message translates to:
  /// **'Pond Overview'**
  String get pondOverview;

  /// No description provided for @pond.
  ///
  /// In en, this message translates to:
  /// **'Pond'**
  String get pond;

  /// No description provided for @pondInformation.
  ///
  /// In en, this message translates to:
  /// **'Pond Information'**
  String get pondInformation;

  /// No description provided for @pondName.
  ///
  /// In en, this message translates to:
  /// **'Pond Name'**
  String get pondName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @species.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// No description provided for @stockingDate.
  ///
  /// In en, this message translates to:
  /// **'Stocking Date'**
  String get stockingDate;

  /// No description provided for @stockingCount.
  ///
  /// In en, this message translates to:
  /// **'Stocking Count'**
  String get stockingCount;

  /// No description provided for @initialStockingDensity.
  ///
  /// In en, this message translates to:
  /// **'Initial Stocking Density'**
  String get initialStockingDensity;

  /// No description provided for @daysOfCulture.
  ///
  /// In en, this message translates to:
  /// **'Days of Culture'**
  String get daysOfCulture;

  /// No description provided for @avgBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Avg. Body Weight'**
  String get avgBodyWeight;

  /// No description provided for @growthTrend.
  ///
  /// In en, this message translates to:
  /// **'Growth Trend'**
  String get growthTrend;

  /// No description provided for @growthChartComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Growth chart coming soon'**
  String get growthChartComingSoon;

  /// No description provided for @survival.
  ///
  /// In en, this message translates to:
  /// **'Survival'**
  String get survival;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @fcr.
  ///
  /// In en, this message translates to:
  /// **'FCR'**
  String get fcr;

  /// No description provided for @recommendedFeedToday.
  ///
  /// In en, this message translates to:
  /// **'Recommended feed today'**
  String get recommendedFeedToday;

  /// No description provided for @biomass.
  ///
  /// In en, this message translates to:
  /// **'Biomass'**
  String get biomass;

  /// No description provided for @harvestEstimate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Estimate'**
  String get harvestEstimate;

  /// No description provided for @mortality.
  ///
  /// In en, this message translates to:
  /// **'Mortality'**
  String get mortality;

  /// No description provided for @deadCount.
  ///
  /// In en, this message translates to:
  /// **'Dead Count'**
  String get deadCount;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @birdAttack.
  ///
  /// In en, this message translates to:
  /// **'Bird attack'**
  String get birdAttack;

  /// No description provided for @disease.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get disease;

  /// No description provided for @waterQuality.
  ///
  /// In en, this message translates to:
  /// **'Water Quality'**
  String get waterQuality;

  /// No description provided for @molting.
  ///
  /// In en, this message translates to:
  /// **'Molting'**
  String get molting;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveLog.
  ///
  /// In en, this message translates to:
  /// **'Save Log'**
  String get saveLog;

  /// No description provided for @saveSample.
  ///
  /// In en, this message translates to:
  /// **'Save Sample'**
  String get saveSample;

  /// No description provided for @saveMortality.
  ///
  /// In en, this message translates to:
  /// **'Save Mortality'**
  String get saveMortality;

  /// No description provided for @addFeedEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Feed Entry'**
  String get addFeedEntry;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @waterQualityLog.
  ///
  /// In en, this message translates to:
  /// **'Daily water quality log'**
  String get waterQualityLog;

  /// No description provided for @dailyEntry.
  ///
  /// In en, this message translates to:
  /// **'Daily Entry'**
  String get dailyEntry;

  /// No description provided for @historicalTrends.
  ///
  /// In en, this message translates to:
  /// **'Historical Trends'**
  String get historicalTrends;

  /// No description provided for @ph.
  ///
  /// In en, this message translates to:
  /// **'pH Level'**
  String get ph;

  /// No description provided for @salinity.
  ///
  /// In en, this message translates to:
  /// **'Salinity'**
  String get salinity;

  /// No description provided for @ammonia.
  ///
  /// In en, this message translates to:
  /// **'Ammonia'**
  String get ammonia;

  /// No description provided for @dissolvedOxygen.
  ///
  /// In en, this message translates to:
  /// **'Dissolved Oxygen'**
  String get dissolvedOxygen;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @recentLogs.
  ///
  /// In en, this message translates to:
  /// **'Recent Logs'**
  String get recentLogs;

  /// No description provided for @feedManagement.
  ///
  /// In en, this message translates to:
  /// **'Feed Management'**
  String get feedManagement;

  /// No description provided for @feedType.
  ///
  /// In en, this message translates to:
  /// **'Feed Type'**
  String get feedType;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @recentFeedInputs.
  ///
  /// In en, this message translates to:
  /// **'Recent feed entries'**
  String get recentFeedInputs;

  /// No description provided for @feedReport.
  ///
  /// In en, this message translates to:
  /// **'Feed Report'**
  String get feedReport;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @totalThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Total This Period'**
  String get totalThisPeriod;

  /// No description provided for @dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get dailyAverage;

  /// No description provided for @detailedLog.
  ///
  /// In en, this message translates to:
  /// **'Detailed log'**
  String get detailedLog;

  /// No description provided for @growthSampling.
  ///
  /// In en, this message translates to:
  /// **'Growth Sampling'**
  String get growthSampling;

  /// No description provided for @recordSample.
  ///
  /// In en, this message translates to:
  /// **'Record Sample'**
  String get recordSample;

  /// No description provided for @sampleDate.
  ///
  /// In en, this message translates to:
  /// **'Sample Date'**
  String get sampleDate;

  /// No description provided for @sampleSize.
  ///
  /// In en, this message translates to:
  /// **'Sample Size'**
  String get sampleSize;

  /// No description provided for @recentSamples.
  ///
  /// In en, this message translates to:
  /// **'Recent samples'**
  String get recentSamples;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @expenseReport.
  ///
  /// In en, this message translates to:
  /// **'Expense Report'**
  String get expenseReport;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @assignToPonds.
  ///
  /// In en, this message translates to:
  /// **'Assign to ponds'**
  String get assignToPonds;

  /// No description provided for @feedExpense.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedExpense;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// No description provided for @labor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get labor;

  /// No description provided for @electricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get electricity;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense breakdown'**
  String get expenseBreakdown;

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent expenses'**
  String get recentExpenses;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @cycleSummary.
  ///
  /// In en, this message translates to:
  /// **'Cycle Summary'**
  String get cycleSummary;

  /// No description provided for @profitEstimate.
  ///
  /// In en, this message translates to:
  /// **'Profit Estimate'**
  String get profitEstimate;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @noGrowthSamples.
  ///
  /// In en, this message translates to:
  /// **'No growth samples for this pond yet'**
  String get noGrowthSamples;

  /// No description provided for @noFeedData.
  ///
  /// In en, this message translates to:
  /// **'No feed data in the last 7 days'**
  String get noFeedData;

  /// No description provided for @noWaterData.
  ///
  /// In en, this message translates to:
  /// **'No water quality data'**
  String get noWaterData;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded for this pond'**
  String get noExpenses;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @amountInr.
  ///
  /// In en, this message translates to:
  /// **'Amount (INR)'**
  String get amountInr;

  /// No description provided for @quantityKg.
  ///
  /// In en, this message translates to:
  /// **'Quantity (kg)'**
  String get quantityKg;

  /// No description provided for @survivalPercent.
  ///
  /// In en, this message translates to:
  /// **'Survival (%)'**
  String get survivalPercent;

  /// No description provided for @estimatedHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Estimated Harvest Date'**
  String get estimatedHarvestDate;

  /// No description provided for @estimatedBiomassTons.
  ///
  /// In en, this message translates to:
  /// **'Estimated Biomass (tons)'**
  String get estimatedBiomassTons;

  /// No description provided for @harvestBiomass.
  ///
  /// In en, this message translates to:
  /// **'Harvest biomass'**
  String get harvestBiomass;

  /// No description provided for @estimatedProfit.
  ///
  /// In en, this message translates to:
  /// **'Estimated Profit'**
  String get estimatedProfit;

  /// No description provided for @historicalDataLast7.
  ///
  /// In en, this message translates to:
  /// **'Historical Data (last 7 days)'**
  String get historicalDataLast7;

  /// No description provided for @salinityPpt.
  ///
  /// In en, this message translates to:
  /// **'Salinity (ppt)'**
  String get salinityPpt;

  /// No description provided for @ammoniaPpm.
  ///
  /// In en, this message translates to:
  /// **'Ammonia (ppm)'**
  String get ammoniaPpm;

  /// No description provided for @dissolvedOxygenMgL.
  ///
  /// In en, this message translates to:
  /// **'Dissolved Oxygen (mg/L)'**
  String get dissolvedOxygenMgL;

  /// No description provided for @temperatureC.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperatureC;

  /// No description provided for @feedReportTab.
  ///
  /// In en, this message translates to:
  /// **'Feed Report'**
  String get feedReportTab;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @noPondsYetAddFirst.
  ///
  /// In en, this message translates to:
  /// **'No ponds yet.\nTap + to add your first pond.'**
  String get noPondsYetAddFirst;

  /// No description provided for @noPondsYetReports.
  ///
  /// In en, this message translates to:
  /// **'No ponds yet.\nAdd a pond first to see reports.'**
  String get noPondsYetReports;

  /// No description provided for @doc.
  ///
  /// In en, this message translates to:
  /// **'DOC'**
  String get doc;

  /// No description provided for @avgWeight.
  ///
  /// In en, this message translates to:
  /// **'Avg Weight'**
  String get avgWeight;

  /// No description provided for @totalFeed.
  ///
  /// In en, this message translates to:
  /// **'Total Feed'**
  String get totalFeed;

  /// No description provided for @expenseSummary.
  ///
  /// In en, this message translates to:
  /// **'Expense Summary'**
  String get expenseSummary;

  /// No description provided for @feedLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Feed (last 7 days)'**
  String get feedLast7Days;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @dailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily Avg'**
  String get dailyAvg;

  /// No description provided for @phAvg.
  ///
  /// In en, this message translates to:
  /// **'pH avg'**
  String get phAvg;

  /// No description provided for @doAvg.
  ///
  /// In en, this message translates to:
  /// **'DO avg'**
  String get doAvg;

  /// No description provided for @ammoniaAvg.
  ///
  /// In en, this message translates to:
  /// **'Ammonia avg'**
  String get ammoniaAvg;

  /// No description provided for @tempAvg.
  ///
  /// In en, this message translates to:
  /// **'Temp avg'**
  String get tempAvg;

  /// No description provided for @noGrowthSamplesYet.
  ///
  /// In en, this message translates to:
  /// **'No growth samples yet.'**
  String get noGrowthSamplesYet;

  /// No description provided for @waterQualityLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Water Quality (last 7 days)'**
  String get waterQualityLast7Days;

  /// No description provided for @noPondsYetFeed.
  ///
  /// In en, this message translates to:
  /// **'No ponds yet.\nAdd a pond first to log feed.'**
  String get noPondsYetFeed;

  /// No description provided for @noPondsYetWater.
  ///
  /// In en, this message translates to:
  /// **'No ponds yet.\nAdd a pond first to log water quality.'**
  String get noPondsYetWater;

  /// No description provided for @noPondsYetGrowth.
  ///
  /// In en, this message translates to:
  /// **'No ponds yet.\nAdd a pond first to record growth samples.'**
  String get noPondsYetGrowth;

  /// No description provided for @noPondsYetMortality.
  ///
  /// In en, this message translates to:
  /// **'No ponds yet.\nAdd a pond first to log mortality.'**
  String get noPondsYetMortality;

  /// No description provided for @noDataLast7Days.
  ///
  /// In en, this message translates to:
  /// **'No data available for the last 7 days.'**
  String get noDataLast7Days;

  /// No description provided for @addPond.
  ///
  /// In en, this message translates to:
  /// **'Add New Pond'**
  String get addPond;

  /// No description provided for @editPond.
  ///
  /// In en, this message translates to:
  /// **'Edit Pond'**
  String get editPond;

  /// No description provided for @growthHarvestOptional.
  ///
  /// In en, this message translates to:
  /// **'Growth & harvest (optional)'**
  String get growthHarvestOptional;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @deletePond.
  ///
  /// In en, this message translates to:
  /// **'Delete Pond'**
  String get deletePond;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
