import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CashFlow'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Track every rupee'**
  String get tagline;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// No description provided for @navCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get navCharts;

  /// No description provided for @navEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get navEmi;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @lent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get lent;

  /// No description provided for @borrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get borrowed;

  /// No description provided for @udhar.
  ///
  /// In en, this message translates to:
  /// **'Udhar'**
  String get udhar;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addEntry;

  /// No description provided for @addEmi.
  ///
  /// In en, this message translates to:
  /// **'Add EMI'**
  String get addEmi;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get addBill;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @paidVia.
  ///
  /// In en, this message translates to:
  /// **'Paid via'**
  String get paidVia;

  /// No description provided for @receivedIn.
  ///
  /// In en, this message translates to:
  /// **'Received in'**
  String get receivedIn;

  /// No description provided for @choosePayment.
  ///
  /// In en, this message translates to:
  /// **'Choose how you paid'**
  String get choosePayment;

  /// No description provided for @chooseReceived.
  ///
  /// In en, this message translates to:
  /// **'Choose how you received it'**
  String get chooseReceived;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get enterAmount;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptional;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get addTitle;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNote;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumTryButton.
  ///
  /// In en, this message translates to:
  /// **'Try Premium · ₹1 for 3 months'**
  String get premiumTryButton;

  /// No description provided for @premiumFineprint.
  ///
  /// In en, this message translates to:
  /// **'Then ₹20/month. Cancel anytime.'**
  String get premiumFineprint;

  /// No description provided for @premiumSheetDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Due dates are Premium'**
  String get premiumSheetDueTitle;

  /// No description provided for @premiumSheetDueBody.
  ///
  /// In en, this message translates to:
  /// **'Set when {name} should pay back, and get a reminder before the day.'**
  String premiumSheetDueBody(String name);

  /// No description provided for @premiumSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all features'**
  String get premiumSeeAll;

  /// No description provided for @premiumSavedWithout.
  ///
  /// In en, this message translates to:
  /// **'Your entry is saved without a due date.'**
  String get premiumSavedWithout;

  /// No description provided for @premiumComingLater.
  ///
  /// In en, this message translates to:
  /// **'Premium purchase comes in a later update.'**
  String get premiumComingLater;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your money, clear and calm'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Income, expenses, udhar, EMIs and bills in one place. Works offline.'**
  String get welcomeBody;

  /// No description provided for @welcomeLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get welcomeLogin;

  /// No description provided for @welcomeSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get welcomeSignUp;

  /// No description provided for @welcomeOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Account and sync come in a later update. For now, your data stays on this phone.'**
  String get welcomeOfflineNote;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'भाषा चुनें · ભાષા પસંદ કરો'**
  String get languageSubtitle;

  /// No description provided for @languageSearch.
  ///
  /// In en, this message translates to:
  /// **'Search language'**
  String get languageSearch;

  /// No description provided for @languageLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings'**
  String get languageLater;

  /// No description provided for @pinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN'**
  String get pinCreateTitle;

  /// No description provided for @pinCreateBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use it to open CashFlow.'**
  String get pinCreateBody;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get pinConfirmTitle;

  /// No description provided for @pinConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Just to be sure.'**
  String get pinConfirmBody;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match. Try again.'**
  String get pinMismatch;

  /// No description provided for @pinEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get pinEnterTitle;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. {count, plural, =1{1 try left} other{{count} tries left}}'**
  String pinWrong(int count);

  /// No description provided for @pinLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Try again in {seconds} s'**
  String pinLocked(int seconds);

  /// No description provided for @pinForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get pinForgot;

  /// No description provided for @pinForgotBody.
  ///
  /// In en, this message translates to:
  /// **'Log in again with your account to set a new PIN. This comes with account login.'**
  String get pinForgotBody;

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get useFingerprint;

  /// No description provided for @fingerprintTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint?'**
  String get fingerprintTitle;

  /// No description provided for @fingerprintBody.
  ///
  /// In en, this message translates to:
  /// **'Open CashFlow with your finger. Your PIN still works.'**
  String get fingerprintBody;

  /// No description provided for @fingerprintEnable.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get fingerprintEnable;

  /// No description provided for @fingerprintNotSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up fingerprint first'**
  String get fingerprintNotSetTitle;

  /// No description provided for @fingerprintNotSetBody.
  ///
  /// In en, this message translates to:
  /// **'Add a fingerprint in your phone\'s settings, then turn it on in CashFlow Settings.'**
  String get fingerprintNotSetBody;

  /// No description provided for @fingerprintReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock CashFlow'**
  String get fingerprintReason;

  /// No description provided for @fingerprintFailed.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint not recognised. Use your PIN.'**
  String get fingerprintFailed;

  /// No description provided for @openingTitle.
  ///
  /// In en, this message translates to:
  /// **'How much money do you have now?'**
  String get openingTitle;

  /// No description provided for @openingBody.
  ///
  /// In en, this message translates to:
  /// **'This is your starting balance. You can enter 0.'**
  String get openingBody;

  /// No description provided for @openingCash.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get openingCash;

  /// No description provided for @openingOnline.
  ///
  /// In en, this message translates to:
  /// **'In bank / UPI'**
  String get openingOnline;

  /// No description provided for @openingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get openingTotal;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @contactsPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Track udhar with your contacts'**
  String get contactsPermTitle;

  /// No description provided for @contactsPermBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a person in one tap when you lend or borrow money.'**
  String get contactsPermBody;

  /// No description provided for @contactsPermPoint1.
  ///
  /// In en, this message translates to:
  /// **'Find people fast'**
  String get contactsPermPoint1;

  /// No description provided for @contactsPermPoint1Sub.
  ///
  /// In en, this message translates to:
  /// **'No typing names and numbers'**
  String get contactsPermPoint1Sub;

  /// No description provided for @contactsPermPoint2.
  ///
  /// In en, this message translates to:
  /// **'Contacts stay on your phone'**
  String get contactsPermPoint2;

  /// No description provided for @contactsPermPoint2Sub.
  ///
  /// In en, this message translates to:
  /// **'We read them only on this device'**
  String get contactsPermPoint2Sub;

  /// No description provided for @contactsPermPoint3.
  ///
  /// In en, this message translates to:
  /// **'Only people you add are saved'**
  String get contactsPermPoint3;

  /// No description provided for @contactsPermPoint3Sub.
  ///
  /// In en, this message translates to:
  /// **'Name and number only'**
  String get contactsPermPoint3Sub;

  /// No description provided for @contactsPermAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow contacts'**
  String get contactsPermAllow;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @balanceEndOf.
  ///
  /// In en, this message translates to:
  /// **'Balance at end of {month}'**
  String balanceEndOf(String month);

  /// No description provided for @cashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash {amount}'**
  String cashBalance(String amount);

  /// No description provided for @onlineBalance.
  ///
  /// In en, this message translates to:
  /// **'Online {amount}'**
  String onlineBalance(String amount);

  /// No description provided for @netThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Net this month'**
  String get netThisMonth;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesTitle;

  /// No description provided for @noEntriesBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first income or expense. It takes 5 seconds.'**
  String get noEntriesBody;

  /// No description provided for @tapPlusToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add'**
  String get tapPlusToAdd;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your balance and charts.'**
  String get deleteEntryBody;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" deleted'**
  String entryDeleted(String title);

  /// No description provided for @hideAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get hideAmounts;

  /// No description provided for @showAmounts.
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get showAmounts;

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpenseTitle;

  /// No description provided for @addIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncomeTitle;

  /// No description provided for @editEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntryTitle;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get saveExpense;

  /// No description provided for @saveIncome.
  ///
  /// In en, this message translates to:
  /// **'Save income'**
  String get saveIncome;

  /// No description provided for @categoryExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense category'**
  String get categoryExpenseTitle;

  /// No description provided for @categoryIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Income category'**
  String get categoryIncomeTitle;

  /// No description provided for @categoryRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get categoryRecent;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get categoryAll;

  /// No description provided for @categorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search or create category'**
  String get categorySearch;

  /// No description provided for @categoryCreate.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\"'**
  String categoryCreate(String name);

  /// No description provided for @categoryCreateSub.
  ///
  /// In en, this message translates to:
  /// **'New category, saved for next time'**
  String get categoryCreateSub;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catGroceries;

  /// No description provided for @catTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get catTravel;

  /// No description provided for @catFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catFuel;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get catBills;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catFun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get catFun;

  /// No description provided for @catRecharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get catRecharge;

  /// No description provided for @catGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get catGifts;

  /// No description provided for @catPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get catPersonal;

  /// No description provided for @catEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get catEmi;

  /// No description provided for @catOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get catOthers;

  /// No description provided for @catSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// No description provided for @catBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get catBusiness;

  /// No description provided for @catFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get catFreelance;

  /// No description provided for @catInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get catInterest;

  /// No description provided for @catGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get catGift;

  /// No description provided for @catRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get catRefund;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @toReceive.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get toReceive;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get toPay;

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String peopleCount(int count);

  /// No description provided for @recentPeople.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentPeople;

  /// No description provided for @searchPeople.
  ///
  /// In en, this message translates to:
  /// **'Search people'**
  String get searchPeople;

  /// No description provided for @allContacts.
  ///
  /// In en, this message translates to:
  /// **'All contacts'**
  String get allContacts;

  /// No description provided for @contactsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts are off'**
  String get contactsOffTitle;

  /// No description provided for @contactsOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on to pick people in one tap. Or add a person by name and number.'**
  String get contactsOffBody;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPerson;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personName;

  /// No description provided for @personPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get personPhone;

  /// No description provided for @owesYou.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you'**
  String owesYou(String name);

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name}'**
  String youOwe(String name);

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get allClear;

  /// No description provided for @lentRepaid.
  ///
  /// In en, this message translates to:
  /// **'Lent {lent} · Repaid {repaid}'**
  String lentRepaid(String lent, String repaid);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @repayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repayment;

  /// No description provided for @repaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Repayment received'**
  String get repaymentReceived;

  /// No description provided for @repaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Repayment paid'**
  String get repaymentPaid;

  /// No description provided for @repaidOf.
  ///
  /// In en, this message translates to:
  /// **'{repaid} of {total} repaid'**
  String repaidOf(String repaid, String total);

  /// No description provided for @amountLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String amountLeft(String amount);

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Due today} =1{Due tomorrow} other{Due in {days} days}}'**
  String dueInDays(int days);

  /// No description provided for @overdueDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day late} other{{days} days late}}'**
  String overdueDays(int days);

  /// No description provided for @toReceiveLabel.
  ///
  /// In en, this message translates to:
  /// **'to receive'**
  String get toReceiveLabel;

  /// No description provided for @toPayLabel.
  ///
  /// In en, this message translates to:
  /// **'to pay'**
  String get toPayLabel;

  /// No description provided for @noUdharTitle.
  ///
  /// In en, this message translates to:
  /// **'No udhar with {name} yet'**
  String noUdharTitle(String name);

  /// No description provided for @noUdharBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Lent or Borrowed to add one.'**
  String get noUdharBody;

  /// No description provided for @noPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'No people yet'**
  String get noPeopleTitle;

  /// No description provided for @noPeopleBody.
  ///
  /// In en, this message translates to:
  /// **'Add a person to track money you lend or borrow.'**
  String get noPeopleBody;

  /// No description provided for @addLentTitle.
  ///
  /// In en, this message translates to:
  /// **'Lent money'**
  String get addLentTitle;

  /// No description provided for @addBorrowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Borrowed money'**
  String get addBorrowedTitle;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @choosePerson.
  ///
  /// In en, this message translates to:
  /// **'Choose a person'**
  String get choosePerson;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @onDueDay.
  ///
  /// In en, this message translates to:
  /// **'On due day'**
  String get onDueDay;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'{days} days before'**
  String daysBefore(int days);

  /// No description provided for @saveLent.
  ///
  /// In en, this message translates to:
  /// **'Save lent'**
  String get saveLent;

  /// No description provided for @saveBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Save borrowed'**
  String get saveBorrowed;

  /// No description provided for @repaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repaymentTitle;

  /// No description provided for @repaymentFrom.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String repaymentFrom(String name);

  /// No description provided for @repaymentTo.
  ///
  /// In en, this message translates to:
  /// **'To {name}'**
  String repaymentTo(String name);

  /// No description provided for @remainingNow.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String remainingNow(String amount);

  /// No description provided for @savePayment.
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get savePayment;

  /// No description provided for @paymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment saved'**
  String get paymentSaved;

  /// No description provided for @udharRepaid.
  ///
  /// In en, this message translates to:
  /// **'Udhar repaid'**
  String get udharRepaid;

  /// No description provided for @extraAmount.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get extraAmount;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalAmount;

  /// No description provided for @extraAsBorrowed.
  ///
  /// In en, this message translates to:
  /// **'{amount} extra. Add it as borrowed?'**
  String extraAsBorrowed(String amount);

  /// No description provided for @extraAsLent.
  ///
  /// In en, this message translates to:
  /// **'{amount} extra. Add it as lent?'**
  String extraAsLent(String amount);

  /// No description provided for @extraNotAddedLent.
  ///
  /// In en, this message translates to:
  /// **'{amount} extra not added · Add as lent'**
  String extraNotAddedLent(String amount);

  /// No description provided for @extraNotAddedBorrowed.
  ///
  /// In en, this message translates to:
  /// **'{amount} extra not added · Add as borrowed'**
  String extraNotAddedBorrowed(String amount);

  /// No description provided for @udharDueToday.
  ///
  /// In en, this message translates to:
  /// **'Udhar due today'**
  String get udharDueToday;

  /// No description provided for @didYouGetIt.
  ///
  /// In en, this message translates to:
  /// **'Did you get it?'**
  String get didYouGetIt;

  /// No description provided for @didYouPayBack.
  ///
  /// In en, this message translates to:
  /// **'Did you pay it back?'**
  String get didYouPayBack;

  /// No description provided for @gotFull.
  ///
  /// In en, this message translates to:
  /// **'Got full {amount}'**
  String gotFull(String amount);

  /// No description provided for @paidFull.
  ///
  /// In en, this message translates to:
  /// **'Paid full {amount}'**
  String paidFull(String amount);

  /// No description provided for @gotSome.
  ///
  /// In en, this message translates to:
  /// **'Got some'**
  String get gotSome;

  /// No description provided for @paidSome.
  ///
  /// In en, this message translates to:
  /// **'Paid some'**
  String get paidSome;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @changeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Change due date'**
  String get changeDueDate;

  /// No description provided for @howMuchGot.
  ///
  /// In en, this message translates to:
  /// **'How much did you get?'**
  String get howMuchGot;

  /// No description provided for @howMuchPaid.
  ///
  /// In en, this message translates to:
  /// **'How much did you pay?'**
  String get howMuchPaid;

  /// No description provided for @stillLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} will still be left'**
  String stillLeft(String amount);

  /// No description provided for @dueDateChanged.
  ///
  /// In en, this message translates to:
  /// **'Due date changed: {from} → {to}'**
  String dueDateChanged(String from, String to);

  /// No description provided for @lentOnDate.
  ///
  /// In en, this message translates to:
  /// **'Lent {amount} on {date}'**
  String lentOnDate(String amount, String date);

  /// No description provided for @borrowedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Borrowed {amount} on {date}'**
  String borrowedOnDate(String amount, String date);

  /// No description provided for @alreadyBack.
  ///
  /// In en, this message translates to:
  /// **'{amount} already back'**
  String alreadyBack(String amount);

  /// No description provided for @dueKeepOrChange.
  ///
  /// In en, this message translates to:
  /// **'Due date: keep {date} or change'**
  String dueKeepOrChange(String date);

  /// No description provided for @saveAmount.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String saveAmount(String amount);

  /// No description provided for @emiBillsTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI & Bills'**
  String get emiBillsTitle;

  /// No description provided for @emis.
  ///
  /// In en, this message translates to:
  /// **'EMIs'**
  String get emis;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @dueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Due this month'**
  String get dueThisMonth;

  /// No description provided for @emiCountNext.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 EMI} other{{count} EMIs}} · next on {date}'**
  String emiCountNext(int count, String date);

  /// No description provided for @emiName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get emiName;

  /// No description provided for @emiNameHint.
  ///
  /// In en, this message translates to:
  /// **'Bike loan'**
  String get emiNameHint;

  /// No description provided for @lenderOptional.
  ///
  /// In en, this message translates to:
  /// **'Lender (optional)'**
  String get lenderOptional;

  /// No description provided for @itemPrice.
  ///
  /// In en, this message translates to:
  /// **'Item price'**
  String get itemPrice;

  /// No description provided for @downPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get downPayment;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get loanAmount;

  /// No description provided for @interestYearly.
  ///
  /// In en, this message translates to:
  /// **'Interest (yearly)'**
  String get interestYearly;

  /// No description provided for @firstEmiDate.
  ///
  /// In en, this message translates to:
  /// **'First EMI'**
  String get firstEmiDate;

  /// No description provided for @iKnowThe.
  ///
  /// In en, this message translates to:
  /// **'I know the'**
  String get iKnowThe;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @emiAmount.
  ///
  /// In en, this message translates to:
  /// **'EMI amount'**
  String get emiAmount;

  /// No description provided for @numberOfMonths.
  ///
  /// In en, this message translates to:
  /// **'Number of months'**
  String get numberOfMonths;

  /// No description provided for @yourEmi.
  ///
  /// In en, this message translates to:
  /// **'Your EMI'**
  String get yourEmi;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @totalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get totalInterest;

  /// No description provided for @totalToPay.
  ///
  /// In en, this message translates to:
  /// **'Total to pay'**
  String get totalToPay;

  /// No description provided for @lastEmi.
  ///
  /// In en, this message translates to:
  /// **'Last EMI'**
  String get lastEmi;

  /// No description provided for @endsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get endsOn;

  /// No description provided for @itWillTake.
  ///
  /// In en, this message translates to:
  /// **'It will take'**
  String get itWillTake;

  /// No description provided for @monthsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String monthsCount(int count);

  /// No description provided for @notPossible.
  ///
  /// In en, this message translates to:
  /// **'Not possible'**
  String get notPossible;

  /// No description provided for @notPossibleTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI is less than the monthly interest'**
  String get notPossibleTitle;

  /// No description provided for @notPossibleBody.
  ///
  /// In en, this message translates to:
  /// **'Interest alone is {interest} a month. Enter more than {interest}, or choose months.'**
  String notPossibleBody(String interest);

  /// No description provided for @saveEmi.
  ///
  /// In en, this message translates to:
  /// **'Save EMI'**
  String get saveEmi;

  /// No description provided for @emiNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Give this EMI a name'**
  String get emiNameMissing;

  /// No description provided for @loanMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter the loan amount'**
  String get loanMissing;

  /// No description provided for @emiTermMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter months or the EMI amount'**
  String get emiTermMissing;

  /// No description provided for @paidOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} paid'**
  String paidOfTotal(int paid, int total);

  /// No description provided for @leftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String leftCount(int count);

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String remainingAmount(String amount);

  /// No description provided for @remainingToPay.
  ///
  /// In en, this message translates to:
  /// **'Remaining to pay'**
  String get remainingToPay;

  /// No description provided for @endsMonth.
  ///
  /// In en, this message translates to:
  /// **'Ends {month}'**
  String endsMonth(String month);

  /// No description provided for @emiLabel.
  ///
  /// In en, this message translates to:
  /// **'EMI'**
  String get emiLabel;

  /// No description provided for @loanLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get loanLabel;

  /// No description provided for @interestLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interestLabel;

  /// No description provided for @installments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installments;

  /// No description provided for @earlierPaid.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 earlier paid} other{{count} earlier paid}}'**
  String earlierPaid(int count);

  /// No description provided for @paidOnTime.
  ///
  /// In en, this message translates to:
  /// **'Paid on time'**
  String get paidOnTime;

  /// No description provided for @paidOnDate.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String paidOnDate(String date);

  /// No description provided for @inclInterest.
  ///
  /// In en, this message translates to:
  /// **'incl. {amount} interest'**
  String inclInterest(String amount);

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as unpaid'**
  String get markUnpaid;

  /// No description provided for @installmentOf.
  ///
  /// In en, this message translates to:
  /// **'Installment {n} of {total} · due {date}'**
  String installmentOf(int n, int total, String date);

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get paidOn;

  /// No description provided for @expenseAddedIn.
  ///
  /// In en, this message translates to:
  /// **'An expense of {amount} is added in {category} category.'**
  String expenseAddedIn(String amount, String category);

  /// No description provided for @installmentPaid.
  ///
  /// In en, this message translates to:
  /// **'Installment {n} paid'**
  String installmentPaid(int n);

  /// No description provided for @expenseAddedLeft.
  ///
  /// In en, this message translates to:
  /// **'Expense added · {count} left'**
  String expenseAddedLeft(int count);

  /// No description provided for @emiDueToday.
  ///
  /// In en, this message translates to:
  /// **'EMI due today'**
  String get emiDueToday;

  /// No description provided for @paidOrNot.
  ///
  /// In en, this message translates to:
  /// **'Paid or not?'**
  String get paidOrNot;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paidAddsExpense.
  ///
  /// In en, this message translates to:
  /// **'\"Paid\" adds the expense and updates the EMI'**
  String get paidAddsExpense;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @emiClosed.
  ///
  /// In en, this message translates to:
  /// **'Loan closed'**
  String get emiClosed;

  /// No description provided for @noEmisTitle.
  ///
  /// In en, this message translates to:
  /// **'No EMIs yet'**
  String get noEmisTitle;

  /// No description provided for @noEmisBody.
  ///
  /// In en, this message translates to:
  /// **'Add a loan or phone EMI. We work out every installment and remind you.'**
  String get noEmisBody;

  /// No description provided for @emiLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss an EMI or bill'**
  String get emiLockTitle;

  /// No description provided for @emiLockBody.
  ///
  /// In en, this message translates to:
  /// **'Track every installment, get a reminder before the due date, and add the payment in one tap.'**
  String get emiLockBody;

  /// No description provided for @deleteEmiTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this EMI?'**
  String get deleteEmiTitle;

  /// No description provided for @deleteEmiBody.
  ///
  /// In en, this message translates to:
  /// **'All its installments are removed. Expenses already added stay.'**
  String get deleteEmiBody;

  /// No description provided for @billWhich.
  ///
  /// In en, this message translates to:
  /// **'Which bill?'**
  String get billWhich;

  /// No description provided for @billWhichSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a type. You can change the name later.'**
  String get billWhichSub;

  /// No description provided for @billElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get billElectricity;

  /// No description provided for @billGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get billGas;

  /// No description provided for @billMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get billMobile;

  /// No description provided for @billInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get billInternet;

  /// No description provided for @billDth.
  ///
  /// In en, this message translates to:
  /// **'DTH / Cable'**
  String get billDth;

  /// No description provided for @billWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get billWater;

  /// No description provided for @billInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get billInsurance;

  /// No description provided for @billOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get billOther;

  /// No description provided for @billTypeBill.
  ///
  /// In en, this message translates to:
  /// **'{type} bill'**
  String billTypeBill(String type);

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @everyNMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{every month} other{every {count} months}}'**
  String everyNMonths(int count);

  /// No description provided for @billName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get billName;

  /// No description provided for @billNameHint.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get billNameHint;

  /// No description provided for @customerIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer ID (optional)'**
  String get customerIdOptional;

  /// No description provided for @customerIdHint.
  ///
  /// In en, this message translates to:
  /// **'Add for your reference'**
  String get customerIdHint;

  /// No description provided for @comesEvery.
  ///
  /// In en, this message translates to:
  /// **'Comes every (months)'**
  String get comesEvery;

  /// No description provided for @nextDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get nextDueDate;

  /// No description provided for @chooseNextDue.
  ///
  /// In en, this message translates to:
  /// **'Choose the next due date'**
  String get chooseNextDue;

  /// No description provided for @thenDates.
  ///
  /// In en, this message translates to:
  /// **'Then {dates}…'**
  String thenDates(String dates);

  /// No description provided for @usualAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Usual amount (optional)'**
  String get usualAmountOptional;

  /// No description provided for @saveBill.
  ///
  /// In en, this message translates to:
  /// **'Save bill'**
  String get saveBill;

  /// No description provided for @editBill.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get editBill;

  /// No description provided for @billsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Bills this month'**
  String get billsThisMonth;

  /// No description provided for @billsPaidLeft.
  ///
  /// In en, this message translates to:
  /// **'{paid} paid · {left} left'**
  String billsPaidLeft(int paid, int left);

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @lastBill.
  ///
  /// In en, this message translates to:
  /// **'Last bill {amount}'**
  String lastBill(String amount);

  /// No description provided for @noBillsTitle.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBillsTitle;

  /// No description provided for @noBillsBody.
  ///
  /// In en, this message translates to:
  /// **'Add electricity, gas, mobile and other bills. We remind you on the due day.'**
  String get noBillsBody;

  /// No description provided for @billDueToday.
  ///
  /// In en, this message translates to:
  /// **'Bill due today'**
  String get billDueToday;

  /// No description provided for @billDueInfo.
  ///
  /// In en, this message translates to:
  /// **'Due {date} · {every}'**
  String billDueInfo(String date, String every);

  /// No description provided for @didYouPayBill.
  ///
  /// In en, this message translates to:
  /// **'Did you pay this bill?'**
  String get didYouPayBill;

  /// No description provided for @yesPaid.
  ///
  /// In en, this message translates to:
  /// **'Yes, paid'**
  String get yesPaid;

  /// No description provided for @notYetTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Not yet = we ask again tomorrow'**
  String get notYetTomorrow;

  /// No description provided for @howMuchWasIt.
  ///
  /// In en, this message translates to:
  /// **'How much was it?'**
  String get howMuchWasIt;

  /// No description provided for @monthBill.
  ///
  /// In en, this message translates to:
  /// **'{month} bill'**
  String monthBill(String month);

  /// No description provided for @usualLabel.
  ///
  /// In en, this message translates to:
  /// **'Usual'**
  String get usualLabel;

  /// No description provided for @otherAmount.
  ///
  /// In en, this message translates to:
  /// **'Other amount'**
  String get otherAmount;

  /// No description provided for @addedToCategory.
  ///
  /// In en, this message translates to:
  /// **'Added to Expenses · {category}'**
  String addedToCategory(String category);

  /// No description provided for @pauseBill.
  ///
  /// In en, this message translates to:
  /// **'Pause bill'**
  String get pauseBill;

  /// No description provided for @resumeBill.
  ///
  /// In en, this message translates to:
  /// **'Resume bill'**
  String get resumeBill;

  /// No description provided for @pausedTag.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedTag;

  /// No description provided for @deleteBill.
  ///
  /// In en, this message translates to:
  /// **'Delete bill'**
  String get deleteBill;

  /// No description provided for @deleteBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this bill?'**
  String get deleteBillTitle;

  /// No description provided for @deleteBillBody.
  ///
  /// In en, this message translates to:
  /// **'Its payment history is removed. Expenses already added stay.'**
  String get deleteBillBody;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get noPaymentsYet;

  /// No description provided for @nextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get nextDue;

  /// No description provided for @billPausedNote.
  ///
  /// In en, this message translates to:
  /// **'Paused: no reminders or popups until you resume it.'**
  String get billPausedNote;

  /// No description provided for @spending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get spending;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @budgetOfLimit.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit}'**
  String budgetOfLimit(String spent, String limit);

  /// No description provided for @spentIn.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String spentIn(String month);

  /// No description provided for @vsMonthDown.
  ///
  /// In en, this message translates to:
  /// **'↓ {pct}% vs {month}'**
  String vsMonthDown(int pct, String month);

  /// No description provided for @vsMonthUp.
  ///
  /// In en, this message translates to:
  /// **'↑ {pct}% vs {month}'**
  String vsMonthUp(int pct, String month);

  /// No description provided for @includeUdhar.
  ///
  /// In en, this message translates to:
  /// **'Include udhar'**
  String get includeUdhar;

  /// No description provided for @noSpendingTitle.
  ///
  /// In en, this message translates to:
  /// **'No spending this month'**
  String get noSpendingTitle;

  /// No description provided for @noSpendingBody.
  ///
  /// In en, this message translates to:
  /// **'Add expenses to see where your money goes.'**
  String get noSpendingBody;

  /// No description provided for @lastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get lastSixMonths;

  /// No description provided for @avgIncome.
  ///
  /// In en, this message translates to:
  /// **'Avg income'**
  String get avgIncome;

  /// No description provided for @avgExpense.
  ///
  /// In en, this message translates to:
  /// **'Avg expense'**
  String get avgExpense;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @bestMonthSaving.
  ///
  /// In en, this message translates to:
  /// **'Best month for saving'**
  String get bestMonthSaving;

  /// No description provided for @chartsLockTitle.
  ///
  /// In en, this message translates to:
  /// **'See where your money goes'**
  String get chartsLockTitle;

  /// No description provided for @chartsLockBody.
  ///
  /// In en, this message translates to:
  /// **'Spending by category, 6-month trends and monthly budget.'**
  String get chartsLockBody;

  /// No description provided for @setMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly budget'**
  String get setMonthlyBudget;

  /// No description provided for @budgetSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: {amount} (average of the last 3 months)'**
  String budgetSuggestion(String amount);

  /// No description provided for @spentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get spentThisMonth;

  /// No description provided for @leftDaysPerDay.
  ///
  /// In en, this message translates to:
  /// **'{left} left · {days, plural, =1{1 day} other{{days} days}} · {perDay}/day'**
  String leftDaysPerDay(String left, int days, String perDay);

  /// No description provided for @amountOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String amountOver(String amount);

  /// No description provided for @categoryLimits.
  ///
  /// In en, this message translates to:
  /// **'Category limits'**
  String get categoryLimits;

  /// No description provided for @addCategoryLimit.
  ///
  /// In en, this message translates to:
  /// **'Add category limit'**
  String get addCategoryLimit;

  /// No description provided for @categoryLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} limit'**
  String categoryLimitTitle(String name);

  /// No description provided for @monthlyBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get monthlyBudgetTitle;

  /// No description provided for @everyMonth.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get everyMonth;

  /// No description provided for @avgThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'Avg 3 months · {amount}'**
  String avgThreeMonths(String amount);

  /// No description provided for @alertMe.
  ///
  /// In en, this message translates to:
  /// **'Alert me'**
  String get alertMe;

  /// No description provided for @alertAt.
  ///
  /// In en, this message translates to:
  /// **'At 80% and 100%'**
  String get alertAt;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @saveLimit.
  ///
  /// In en, this message translates to:
  /// **'Save limit'**
  String get saveLimit;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get pickCategory;

  /// No description provided for @percentOf.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String percentOf(int pct);

  /// No description provided for @ofLimit.
  ///
  /// In en, this message translates to:
  /// **'of {limit}'**
  String ofLimit(String limit);

  /// No description provided for @ratePerYear.
  ///
  /// In en, this message translates to:
  /// **'{rate}% a year'**
  String ratePerYear(String rate);

  /// No description provided for @noCost.
  ///
  /// In en, this message translates to:
  /// **'No-cost'**
  String get noCost;

  /// No description provided for @dueOnDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOnDate(String date);

  /// No description provided for @lastTag.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get lastTag;

  /// No description provided for @paidCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} paid'**
  String paidCountLabel(int count);

  /// No description provided for @editEmi.
  ///
  /// In en, this message translates to:
  /// **'Edit EMI'**
  String get editEmi;

  /// No description provided for @deleteEmi.
  ///
  /// In en, this message translates to:
  /// **'Delete EMI'**
  String get deleteEmi;

  /// No description provided for @totalsMayDiffer.
  ///
  /// In en, this message translates to:
  /// **'Totals can differ a little from your lender\'s schedule.'**
  String get totalsMayDiffer;

  /// No description provided for @emiTermsLocked.
  ///
  /// In en, this message translates to:
  /// **'Loan details can\'t change after an installment is paid.'**
  String get emiTermsLocked;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get chooseIcon;

  /// No description provided for @devPremiumToggle.
  ///
  /// In en, this message translates to:
  /// **'Premium (dev only)'**
  String get devPremiumToggle;

  /// No description provided for @devGallery.
  ///
  /// In en, this message translates to:
  /// **'Widget gallery (dev)'**
  String get devGallery;
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
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
