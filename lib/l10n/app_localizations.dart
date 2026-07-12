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

  /// No description provided for @hardness.
  ///
  /// In en, this message translates to:
  /// **'Hardness'**
  String get hardness;

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

  /// No description provided for @hardnessMgL.
  ///
  /// In en, this message translates to:
  /// **'Hardness (mg/L)'**
  String get hardnessMgL;

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

  /// No description provided for @hardnessAvg.
  ///
  /// In en, this message translates to:
  /// **'Hardness avg'**
  String get hardnessAvg;

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

  /// No description provided for @checkTrayStatus.
  ///
  /// In en, this message translates to:
  /// **'Check tray status'**
  String get checkTrayStatus;

  /// No description provided for @trayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get trayEmpty;

  /// No description provided for @trayPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get trayPartial;

  /// No description provided for @trayFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get trayFull;

  /// No description provided for @suggestedNextFeed.
  ///
  /// In en, this message translates to:
  /// **'Suggested next feed'**
  String get suggestedNextFeed;

  /// No description provided for @nextFeedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get nextFeedReason;

  /// No description provided for @nextFeedReasonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tray empty — shrimp likely consumed well; try a bit more next feeding.'**
  String get nextFeedReasonEmpty;

  /// No description provided for @nextFeedReasonPartial.
  ///
  /// In en, this message translates to:
  /// **'Tray partial — amount is close; adjust slightly if needed.'**
  String get nextFeedReasonPartial;

  /// No description provided for @nextFeedReasonFull.
  ///
  /// In en, this message translates to:
  /// **'Tray still has leftover feed — reduce next amount to cut waste.'**
  String get nextFeedReasonFull;

  /// No description provided for @feedInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'7-Day feeding insight'**
  String get feedInsightTitle;

  /// No description provided for @feedInsightAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg feed (active days)'**
  String get feedInsightAvg;

  /// No description provided for @feedInsightTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get feedInsightTrend;

  /// No description provided for @trendIncreasing.
  ///
  /// In en, this message translates to:
  /// **'Increasing'**
  String get trendIncreasing;

  /// No description provided for @trendDecreasing.
  ///
  /// In en, this message translates to:
  /// **'Decreasing'**
  String get trendDecreasing;

  /// No description provided for @trendStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get trendStable;

  /// No description provided for @feedInsightTrayPattern.
  ///
  /// In en, this message translates to:
  /// **'Tray pattern (entries)'**
  String get feedInsightTrayPattern;

  /// No description provided for @feedInsightTrayLine.
  ///
  /// In en, this message translates to:
  /// **'Empty: {emptyCount}  ·  Partial: {partialCount}  ·  Full: {fullCount}'**
  String feedInsightTrayLine(int emptyCount, int partialCount, int fullCount);

  /// No description provided for @feedInsightSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedInsightSuggestion;

  /// No description provided for @feedInsightSuggestIncrease.
  ///
  /// In en, this message translates to:
  /// **'Feed may be on the low side — consider increasing slightly.'**
  String get feedInsightSuggestIncrease;

  /// No description provided for @feedInsightSuggestDecrease.
  ///
  /// In en, this message translates to:
  /// **'Leftovers often seen — consider reducing slightly.'**
  String get feedInsightSuggestDecrease;

  /// No description provided for @feedInsightSuggestOk.
  ///
  /// In en, this message translates to:
  /// **'Pattern looks reasonable for this week.'**
  String get feedInsightSuggestOk;

  /// No description provided for @feedInsightNoTrayData.
  ///
  /// In en, this message translates to:
  /// **'Log tray status with each feed entry to see tray patterns here.'**
  String get feedInsightNoTrayData;

  /// No description provided for @selectTrayBeforeSave.
  ///
  /// In en, this message translates to:
  /// **'Select check tray status before saving.'**
  String get selectTrayBeforeSave;

  /// No description provided for @logNewFeed.
  ///
  /// In en, this message translates to:
  /// **'Log New Feed'**
  String get logNewFeed;

  /// No description provided for @growthAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Growth Analysis'**
  String get growthAnalysisTitle;

  /// No description provided for @growthAnalysisExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected: {min}-{max} g'**
  String growthAnalysisExpected(String min, String max);

  /// No description provided for @growthAnalysisActual.
  ///
  /// In en, this message translates to:
  /// **'Actual: {actual} g'**
  String growthAnalysisActual(String actual);

  /// No description provided for @growthAnalysisStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String growthAnalysisStatus(String status);

  /// No description provided for @growthStatusGood.
  ///
  /// In en, this message translates to:
  /// **'GOOD'**
  String get growthStatusGood;

  /// No description provided for @growthStatusSlow.
  ///
  /// In en, this message translates to:
  /// **'SLOW'**
  String get growthStatusSlow;

  /// No description provided for @growthStatusExcellent.
  ///
  /// In en, this message translates to:
  /// **'EXCELLENT'**
  String get growthStatusExcellent;

  /// No description provided for @growthSuggestionCheckFeedQty.
  ///
  /// In en, this message translates to:
  /// **'Check feed quantity'**
  String get growthSuggestionCheckFeedQty;

  /// No description provided for @growthSuggestionCheckWaterQuality.
  ///
  /// In en, this message translates to:
  /// **'Check water quality'**
  String get growthSuggestionCheckWaterQuality;

  /// No description provided for @growthSuggestionOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Growth on track'**
  String get growthSuggestionOnTrack;

  /// No description provided for @growthSuggestionAboveExpected.
  ///
  /// In en, this message translates to:
  /// **'Growth above expected'**
  String get growthSuggestionAboveExpected;

  /// No description provided for @growthCombinedSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Growth below expected. Likely due to low feeding or water issue.'**
  String get growthCombinedSuggestion;

  /// No description provided for @growthExpectedShort.
  ///
  /// In en, this message translates to:
  /// **'Expected: {min}-{max}g'**
  String growthExpectedShort(String min, String max);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageTelugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get settingsLanguageTelugu;

  /// No description provided for @settingsResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get settingsResetPassword;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsDailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get settingsDailyReminders;

  /// No description provided for @settingsCheckWaterQuality.
  ///
  /// In en, this message translates to:
  /// **'Check Water Quality'**
  String get settingsCheckWaterQuality;

  /// No description provided for @settingsAlertTime.
  ///
  /// In en, this message translates to:
  /// **'Alert time'**
  String get settingsAlertTime;

  /// No description provided for @settingsFeedThePond.
  ///
  /// In en, this message translates to:
  /// **'Feed the Pond'**
  String get settingsFeedThePond;

  /// No description provided for @settingsTime1.
  ///
  /// In en, this message translates to:
  /// **'Time 1'**
  String get settingsTime1;

  /// No description provided for @settingsTime2.
  ///
  /// In en, this message translates to:
  /// **'Time 2'**
  String get settingsTime2;

  /// No description provided for @settingsTime3.
  ///
  /// In en, this message translates to:
  /// **'Time 3'**
  String get settingsTime3;

  /// No description provided for @settingsTime4.
  ///
  /// In en, this message translates to:
  /// **'Time 4'**
  String get settingsTime4;

  /// No description provided for @settingsTime5.
  ///
  /// In en, this message translates to:
  /// **'Time 5'**
  String get settingsTime5;

  /// No description provided for @settingsLogExpenses.
  ///
  /// In en, this message translates to:
  /// **'Log Expenses'**
  String get settingsLogExpenses;

  /// No description provided for @settingsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get settingsNotSet;

  /// No description provided for @settingsApplying.
  ///
  /// In en, this message translates to:
  /// **'Applying...'**
  String get settingsApplying;

  /// No description provided for @settingsApplyAlertSettings.
  ///
  /// In en, this message translates to:
  /// **'Apply Alert Settings'**
  String get settingsApplyAlertSettings;

  /// No description provided for @settingsTestAlerts.
  ///
  /// In en, this message translates to:
  /// **'Test alerts'**
  String get settingsTestAlerts;

  /// No description provided for @settingsSendTestNotificationNow.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification now'**
  String get settingsSendTestNotificationNow;

  /// No description provided for @settingsTestNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent.'**
  String get settingsTestNotificationSent;

  /// No description provided for @settingsTestAlertIn10Sec.
  ///
  /// In en, this message translates to:
  /// **'Test alert in 10 sec'**
  String get settingsTestAlertIn10Sec;

  /// No description provided for @settingsScheduleNotificationIn10Seconds.
  ///
  /// In en, this message translates to:
  /// **'Schedule a notification in 10 seconds'**
  String get settingsScheduleNotificationIn10Seconds;

  /// No description provided for @settingsNotificationIn10Seconds.
  ///
  /// In en, this message translates to:
  /// **'Notification in 10 seconds.'**
  String get settingsNotificationIn10Seconds;

  /// No description provided for @settingsAppSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSection;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// No description provided for @alertSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Alert settings updated.'**
  String get alertSettingsUpdated;

  /// No description provided for @couldNotUpdateAlerts.
  ///
  /// In en, this message translates to:
  /// **'Could not update alerts'**
  String get couldNotUpdateAlerts;

  /// No description provided for @currentAccountNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Current account has no email.'**
  String get currentAccountNoEmail;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String passwordResetEmailSent(String email);

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsOperationalReminders.
  ///
  /// In en, this message translates to:
  /// **'Operational reminders'**
  String get alertsOperationalReminders;

  /// No description provided for @alertFeedReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed Reminder'**
  String get alertFeedReminderTitle;

  /// No description provided for @alertFeedReminderSchedule.
  ///
  /// In en, this message translates to:
  /// **'6:00, 11:00, 16:00, 21:00'**
  String get alertFeedReminderSchedule;

  /// No description provided for @alertFeedReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to log feed'**
  String get alertFeedReminderBody;

  /// No description provided for @alertWaterCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Quality Check'**
  String get alertWaterCheckTitle;

  /// No description provided for @alertWaterCheckSchedule.
  ///
  /// In en, this message translates to:
  /// **'Daily 7:00 AM'**
  String get alertWaterCheckSchedule;

  /// No description provided for @alertWaterCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Test pH, DO, Ammonia, Temperature'**
  String get alertWaterCheckBody;

  /// No description provided for @alertGrowthSamplingTitle.
  ///
  /// In en, this message translates to:
  /// **'Growth Sampling Due'**
  String get alertGrowthSamplingTitle;

  /// No description provided for @alertGrowthSamplingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly Monday 9:00 AM'**
  String get alertGrowthSamplingSchedule;

  /// No description provided for @alertGrowthSamplingBody.
  ///
  /// In en, this message translates to:
  /// **'Take shrimp sample and record growth'**
  String get alertGrowthSamplingBody;

  /// No description provided for @alertMortalityTitle.
  ///
  /// In en, this message translates to:
  /// **'Mortality Check'**
  String get alertMortalityTitle;

  /// No description provided for @alertMortalitySchedule.
  ///
  /// In en, this message translates to:
  /// **'Daily 7:30 AM'**
  String get alertMortalitySchedule;

  /// No description provided for @alertMortalityBody.
  ///
  /// In en, this message translates to:
  /// **'Check ponds and log mortality'**
  String get alertMortalityBody;

  /// No description provided for @alertsTestNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get alertsTestNotificationTitle;

  /// No description provided for @alertsTestNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a test alert now'**
  String get alertsTestNotificationSubtitle;

  /// No description provided for @alertsTestNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent. Check status bar.'**
  String get alertsTestNotificationSent;

  /// No description provided for @waterNoDataForPondYet.
  ///
  /// In en, this message translates to:
  /// **'No water quality data for this pond yet.'**
  String get waterNoDataForPondYet;

  /// No description provided for @waterNoDataForPondAndRange.
  ///
  /// In en, this message translates to:
  /// **'There is no water quality data for the selected pond and date range.'**
  String get waterNoDataForPondAndRange;

  /// No description provided for @growthSampleSizeOptional.
  ///
  /// In en, this message translates to:
  /// **'Sample size (optional)'**
  String get growthSampleSizeOptional;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @couldNotSaveSample.
  ///
  /// In en, this message translates to:
  /// **'Could not save sample'**
  String get couldNotSaveSample;

  /// No description provided for @expenseTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get expenseTakePhoto;

  /// No description provided for @expenseUploadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get expenseUploadFromGallery;

  /// No description provided for @expenseRemoveReceipt.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get expenseRemoveReceipt;

  /// No description provided for @expenseReceiptPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get expenseReceiptPreviewTitle;

  /// No description provided for @expenseReceiptLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load receipt image'**
  String get expenseReceiptLoadFailed;

  /// No description provided for @expenseSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save expense'**
  String get expenseSaveFailed;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @recentMortality.
  ///
  /// In en, this message translates to:
  /// **'Recent mortality'**
  String get recentMortality;

  /// No description provided for @recordMortality.
  ///
  /// In en, this message translates to:
  /// **'Record mortality'**
  String get recordMortality;

  /// No description provided for @noMortalityToday.
  ///
  /// In en, this message translates to:
  /// **'No mortality today'**
  String get noMortalityToday;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @enterNonNegativeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-negative number'**
  String get enterNonNegativeNumber;

  /// No description provided for @tabMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get tabMarket;

  /// No description provided for @titleMarket.
  ///
  /// In en, this message translates to:
  /// **'Buyer Requirements'**
  String get titleMarket;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingWelcome;

  /// No description provided for @onboardingRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'What best describes you?'**
  String get onboardingRoleTitle;

  /// No description provided for @onboardingRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor the app to your needs.'**
  String get onboardingRoleSubtitle;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @roleFarmerDesc.
  ///
  /// In en, this message translates to:
  /// **'Own or operate shrimp ponds'**
  String get roleFarmerDesc;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleSupervisorDesc.
  ///
  /// In en, this message translates to:
  /// **'Oversee farm operations'**
  String get roleSupervisorDesc;

  /// No description provided for @roleTrader.
  ///
  /// In en, this message translates to:
  /// **'Trader'**
  String get roleTrader;

  /// No description provided for @roleTraderDesc.
  ///
  /// In en, this message translates to:
  /// **'Buy shrimp from farmers'**
  String get roleTraderDesc;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingFarmerSetup.
  ///
  /// In en, this message translates to:
  /// **'Farmer setup'**
  String get onboardingFarmerSetup;

  /// No description provided for @onboardingSupervisorSetup.
  ///
  /// In en, this message translates to:
  /// **'Supervisor setup'**
  String get onboardingSupervisorSetup;

  /// No description provided for @onboardingIntentTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to use the app for?'**
  String get onboardingIntentTitle;

  /// No description provided for @intentBuyerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive buyer notifications'**
  String get intentBuyerNotifications;

  /// No description provided for @intentBuyerNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'See trader requirements in your area'**
  String get intentBuyerNotificationsDesc;

  /// No description provided for @intentManageFarm.
  ///
  /// In en, this message translates to:
  /// **'Manage my farm'**
  String get intentManageFarm;

  /// No description provided for @intentManageFarmDesc.
  ///
  /// In en, this message translates to:
  /// **'Track ponds, feed, water, and expenses'**
  String get intentManageFarmDesc;

  /// No description provided for @intentBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get intentBoth;

  /// No description provided for @intentBothDesc.
  ///
  /// In en, this message translates to:
  /// **'Market alerts plus full farm management'**
  String get intentBothDesc;

  /// No description provided for @onboardingYourName.
  ///
  /// In en, this message translates to:
  /// **'మీ పేరు / Your Name'**
  String get onboardingYourName;

  /// No description provided for @onboardingPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'మొబైల్ నంబర్ / Phone Number'**
  String get onboardingPhoneNumber;

  /// No description provided for @onboardingPhoneOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional for supervisors'**
  String get onboardingPhoneOptionalHint;

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name (letters only, min 2 characters)'**
  String get nameInvalid;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit Indian mobile number'**
  String get phoneInvalid;

  /// No description provided for @contactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact unavailable'**
  String get contactUnavailable;

  /// No description provided for @noContact.
  ///
  /// In en, this message translates to:
  /// **'No contact'**
  String get noContact;

  /// No description provided for @onboardingRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your region (mandal)'**
  String get onboardingRegionTitle;

  /// No description provided for @onboardingRegionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to match buyer requirements near you.'**
  String get onboardingRegionSubtitle;

  /// No description provided for @onboardingRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Mandal / region'**
  String get onboardingRegionLabel;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingFinish;

  /// No description provided for @onboardingTraderVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify phone'**
  String get onboardingTraderVerify;

  /// No description provided for @onboardingTraderVerifyDesc.
  ///
  /// In en, this message translates to:
  /// **'Traders must verify a phone number before posting requirements.'**
  String get onboardingTraderVerifyDesc;

  /// No description provided for @traderDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Business / trader name'**
  String get traderDisplayName;

  /// No description provided for @traderPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get traderPhone;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP code'**
  String get otpCode;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get verifyAndContinue;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhone;

  /// No description provided for @pleaseCompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields.'**
  String get pleaseCompleteFields;

  /// No description provided for @marketEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requirements in your area yet'**
  String get marketEmptyTitle;

  /// No description provided for @marketEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When traders post buyer needs matching your mandal, they will appear here.'**
  String get marketEmptySubtitle;

  /// No description provided for @marketLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load market requirements.'**
  String get marketLoadError;

  /// No description provided for @interested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get interested;

  /// No description provided for @traderContact.
  ///
  /// In en, this message translates to:
  /// **'Trader contact'**
  String get traderContact;

  /// No description provided for @phoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get phoneCopied;

  /// No description provided for @copyPhone.
  ///
  /// In en, this message translates to:
  /// **'Copy phone'**
  String get copyPhone;

  /// No description provided for @priceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on request'**
  String get priceOnRequest;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @postRequirement.
  ///
  /// In en, this message translates to:
  /// **'Post requirement'**
  String get postRequirement;

  /// No description provided for @quantityNeeded.
  ///
  /// In en, this message translates to:
  /// **'Quantity needed'**
  String get quantityNeeded;

  /// No description provided for @countMin.
  ///
  /// In en, this message translates to:
  /// **'Count min'**
  String get countMin;

  /// No description provided for @countMax.
  ///
  /// In en, this message translates to:
  /// **'Count max'**
  String get countMax;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @pricePerKgOptional.
  ///
  /// In en, this message translates to:
  /// **'Price per kg (optional)'**
  String get pricePerKgOptional;

  /// No description provided for @selectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select a region'**
  String get selectRegion;

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value'**
  String get invalidValue;

  /// No description provided for @requirementPosted.
  ///
  /// In en, this message translates to:
  /// **'Requirement posted'**
  String get requirementPosted;

  /// No description provided for @traderPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone in onboarding before posting.'**
  String get traderPhoneRequired;

  /// No description provided for @markFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Mark fulfilled'**
  String get markFulfilled;

  /// No description provided for @requirementExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get requirementExpired;

  /// No description provided for @requirementExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get requirementExpiresToday;

  /// No description provided for @requirementExpiresInOneDay.
  ///
  /// In en, this message translates to:
  /// **'Expires in 1 day'**
  String get requirementExpiresInOneDay;

  /// No description provided for @requirementExpiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String requirementExpiresInDays(int days);

  /// No description provided for @farmersInterested.
  ///
  /// In en, this message translates to:
  /// **'{count} farmer(s) interested'**
  String farmersInterested(int count);

  /// No description provided for @interestedFarmersTitle.
  ///
  /// In en, this message translates to:
  /// **'Interested farmers'**
  String get interestedFarmersTitle;

  /// No description provided for @interestedFarmersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No interested farmers yet.'**
  String get interestedFarmersEmpty;

  /// No description provided for @interestedFarmersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load interested farmers.'**
  String get interestedFarmersLoadError;

  /// No description provided for @noPhoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get noPhoneAvailable;

  /// No description provided for @interestRecordError.
  ///
  /// In en, this message translates to:
  /// **'Could not record your interest. Try again.'**
  String get interestRecordError;

  /// No description provided for @countMinLessThanMax.
  ///
  /// In en, this message translates to:
  /// **'Count min must be less than count max'**
  String get countMinLessThanMax;

  /// No description provided for @expiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDateLabel;

  /// No description provided for @expiryMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'Expiry must be in the future'**
  String get expiryMustBeFuture;

  /// No description provided for @selectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select expiry date'**
  String get selectExpiryDate;

  /// No description provided for @setUpYourFarm.
  ///
  /// In en, this message translates to:
  /// **'Set up your farm'**
  String get setUpYourFarm;

  /// No description provided for @setUpYourFarmDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first pond to track water, feed, and growth.'**
  String get setUpYourFarmDesc;

  /// No description provided for @marketDay7Nudge.
  ///
  /// In en, this message translates to:
  /// **'You can also manage your ponds — add a pond anytime.'**
  String get marketDay7Nudge;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;
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
