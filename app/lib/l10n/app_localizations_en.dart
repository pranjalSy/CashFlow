// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CashFlow';

  @override
  String get tagline => 'Track every rupee';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get continueLabel => 'Continue';

  @override
  String get notNow => 'Not now';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get undo => 'Undo';

  @override
  String get yes => 'Yes';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get required => 'Required';

  @override
  String get optional => 'optional';

  @override
  String get now => 'Now';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get back => 'Back';

  @override
  String get more => 'More';

  @override
  String get settings => 'Settings';

  @override
  String get navHome => 'Home';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navCharts => 'Charts';

  @override
  String get navEmi => 'EMI';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get lent => 'Lent';

  @override
  String get borrowed => 'Borrowed';

  @override
  String get udhar => 'Udhar';

  @override
  String get addEntry => 'Add';

  @override
  String get addEmi => 'Add EMI';

  @override
  String get addBill => 'Add bill';

  @override
  String get cash => 'Cash';

  @override
  String get online => 'Online';

  @override
  String get upi => 'UPI';

  @override
  String get card => 'Card';

  @override
  String get bank => 'Bank';

  @override
  String get paidVia => 'Paid via';

  @override
  String get receivedIn => 'Received in';

  @override
  String get choosePayment => 'Choose how you paid';

  @override
  String get chooseReceived => 'Choose how you received it';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get titleOptional => 'Title (optional)';

  @override
  String get addTitle => 'Add a title';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get note => 'Note';

  @override
  String get addNote => 'Add a note';

  @override
  String get category => 'Category';

  @override
  String get premium => 'Premium';

  @override
  String get premiumTryButton => 'Try Premium · ₹1 for 3 months';

  @override
  String get premiumFineprint => 'Then ₹20/month. Cancel anytime.';

  @override
  String get premiumSheetDueTitle => 'Due dates are Premium';

  @override
  String premiumSheetDueBody(String name) {
    return 'Set when $name should pay back, and get a reminder before the day.';
  }

  @override
  String get premiumSeeAll => 'See all features';

  @override
  String get premiumSavedWithout => 'Your entry is saved without a due date.';

  @override
  String get premiumComingLater => 'Premium purchase comes in a later update.';

  @override
  String get welcomeTitle => 'Your money,\nclearly tracked.';

  @override
  String get welcomeBody =>
      'Income, expenses, udhar and EMIs. All in one calm, private place.';

  @override
  String get welcomeLogin => 'Log in';

  @override
  String get welcomeSignUp => 'Create account';

  @override
  String get welcomeOfflineNote =>
      'Account and sync come in a later update. For now, your data stays on this phone.';

  @override
  String get welcomeF1 => 'Never miss a due date';

  @override
  String get welcomeF1Sub => 'Reminders for udhar, EMIs and bills';

  @override
  String get welcomeF2 => 'Works offline';

  @override
  String get welcomeF2Sub => 'Add entries anytime, syncs later';

  @override
  String get welcomeF3 => 'Private and locked';

  @override
  String get welcomeF3Sub => 'PIN and fingerprint protected';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'भाषा चुनें · ભાષા પસંદ કરો';

  @override
  String get languageSearch => 'Search language';

  @override
  String get languageLater => 'You can change this anytime in Settings';

  @override
  String get pinCreateTitle => 'Create your PIN';

  @override
  String get pinCreateBody => 'You\'ll use this 4-digit PIN to open CashFlow.';

  @override
  String get pinAvoidEasy => 'Avoid easy PINs like 1234 or 0000';

  @override
  String get pinStoredOnPhone =>
      'Stored only on this phone, never sent anywhere';

  @override
  String get pinConfirmTitle => 'Enter the PIN again';

  @override
  String get pinConfirmBody => 'Just to be sure.';

  @override
  String get pinMismatch => 'PINs don\'t match. Try again.';

  @override
  String get pinEnterTitle => 'Enter your PIN';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left',
      one: '1 try left',
    );
    return 'Wrong PIN. $_temp0';
  }

  @override
  String pinLocked(int seconds) {
    return 'Too many tries. Try again in $seconds s';
  }

  @override
  String get pinForgot => 'Forgot PIN?';

  @override
  String get pinForgotBody =>
      'Log in again with your account to set a new PIN. This comes with account login.';

  @override
  String get useFingerprint => 'Use fingerprint';

  @override
  String get fingerprintTitle => 'Unlock with fingerprint';

  @override
  String get fingerprintBody =>
      'Open CashFlow with one touch instead of typing your PIN.';

  @override
  String get fingerprintOnTitle => 'Fingerprint is on';

  @override
  String get fingerprintOnBody =>
      'Next time, just touch the sensor to open CashFlow.';

  @override
  String get fingerprintOnNote =>
      'You can turn this off anytime in Settings › App lock';

  @override
  String get fpFaster => 'Faster';

  @override
  String get fpFasterSub => 'Open the app in under a second';

  @override
  String get fpPinBackup => 'PIN stays as backup';

  @override
  String get fpPinBackupSub => 'Use your PIN anytime';

  @override
  String get fpNeverSee => 'We never see your fingerprint';

  @override
  String get fpNeverSeeSub => 'It stays inside your phone';

  @override
  String get fingerprintEnable => 'Turn on fingerprint';

  @override
  String get fingerprintNotSetTitle => 'Set up fingerprint first';

  @override
  String get fingerprintNotSetBody =>
      'Add a fingerprint in your phone\'s settings, then turn it on in CashFlow Settings.';

  @override
  String get fingerprintReason => 'Unlock CashFlow';

  @override
  String get fingerprintFailed => 'Fingerprint not recognised. Use your PIN.';

  @override
  String get openingTitle => 'Your starting balance';

  @override
  String get openingBody =>
      'How much money do you have right now? Rough numbers are fine.';

  @override
  String get cashSub => 'In your wallet';

  @override
  String get onlineSub => 'Bank and UPI';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get openingNote =>
      'Only a starting point. We never connect to your bank. You can change it later in Settings.';

  @override
  String get next => 'Next';

  @override
  String get openingCash => 'Cash in hand';

  @override
  String get openingOnline => 'In bank / UPI';

  @override
  String get openingTotal => 'Total';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get contactsPermTitle => 'Track udhar with your contacts';

  @override
  String get contactsPermBody =>
      'Pick a person in one tap when you lend or borrow money.';

  @override
  String get contactsPermPoint1 => 'Find people fast';

  @override
  String get contactsPermPoint1Sub => 'No typing names and numbers';

  @override
  String get contactsPermPoint2 => 'Contacts stay on your phone';

  @override
  String get contactsPermPoint2Sub => 'We read them only on this device';

  @override
  String get contactsPermPoint3 => 'Only people you add are saved';

  @override
  String get contactsPermPoint3Sub => 'Name and number only';

  @override
  String get contactsPermAllow => 'Allow contacts';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String balanceEndOf(String month) {
    return 'Balance at end of $month';
  }

  @override
  String cashBalance(String amount) {
    return 'Cash $amount';
  }

  @override
  String onlineBalance(String amount) {
    return 'Online $amount';
  }

  @override
  String get netThisMonth => 'Net this month';

  @override
  String get transactions => 'Transactions';

  @override
  String get filterAll => 'All';

  @override
  String get noEntriesTitle => 'No entries yet';

  @override
  String get noEntriesBody =>
      'Add your first income or expense. It takes 5 seconds.';

  @override
  String get tapPlusToAdd => 'Tap + to add';

  @override
  String get deleteEntryTitle => 'Delete this entry?';

  @override
  String get deleteEntryBody =>
      'It will be removed from your balance and charts.';

  @override
  String entryDeleted(String title) {
    return '\"$title\" deleted';
  }

  @override
  String get hideAmounts => 'Hide amounts';

  @override
  String get showAmounts => 'Show amounts';

  @override
  String get addExpenseTitle => 'Add expense';

  @override
  String get addIncomeTitle => 'Add income';

  @override
  String get editEntryTitle => 'Edit entry';

  @override
  String get saveExpense => 'Save expense';

  @override
  String get saveIncome => 'Save income';

  @override
  String get categoryExpenseTitle => 'Expense category';

  @override
  String get categoryIncomeTitle => 'Income category';

  @override
  String get categoryRecent => 'Recent';

  @override
  String get categoryAll => 'All categories';

  @override
  String get categorySearch => 'Search or create category';

  @override
  String categoryCreate(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get categoryCreateSub => 'New category, saved for next time';

  @override
  String get catFood => 'Food';

  @override
  String get catGroceries => 'Groceries';

  @override
  String get catTravel => 'Travel';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catBills => 'Bills';

  @override
  String get catRent => 'Rent';

  @override
  String get catHealth => 'Health';

  @override
  String get catEducation => 'Education';

  @override
  String get catFun => 'Fun';

  @override
  String get catRecharge => 'Recharge';

  @override
  String get catGifts => 'Gifts';

  @override
  String get catPersonal => 'Personal';

  @override
  String get catEmi => 'EMI';

  @override
  String get catOthers => 'Others';

  @override
  String get catSalary => 'Salary';

  @override
  String get catBusiness => 'Business';

  @override
  String get catFreelance => 'Freelance';

  @override
  String get catInterest => 'Interest';

  @override
  String get catGift => 'Gift';

  @override
  String get catRefund => 'Refund';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get toReceive => 'To receive';

  @override
  String get toPay => 'To pay';

  @override
  String peopleCount(int count) {
    return 'People · $count';
  }

  @override
  String get recentPeople => 'Recent';

  @override
  String get searchPeople => 'Search people';

  @override
  String get allContacts => 'All contacts';

  @override
  String get contactsOffTitle => 'Contacts are off';

  @override
  String get contactsOffBody =>
      'Turn on to pick people in one tap. Or add a person by name and number.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get addPerson => 'Add person';

  @override
  String get personName => 'Name';

  @override
  String get personPhone => 'Phone number (optional)';

  @override
  String owesYou(String name) {
    return '$name owes you';
  }

  @override
  String youOwe(String name) {
    return 'You owe $name';
  }

  @override
  String get allClear => 'All clear';

  @override
  String lentRepaid(String lent, String repaid) {
    return 'Lent $lent · Repaid $repaid';
  }

  @override
  String get history => 'History';

  @override
  String get repayment => 'Repayment';

  @override
  String get repaymentReceived => 'Repayment received';

  @override
  String get repaymentPaid => 'Repayment paid';

  @override
  String repaidOf(String repaid, String total) {
    return '$repaid of $total repaid';
  }

  @override
  String amountLeft(String amount) {
    return '$amount left';
  }

  @override
  String get settled => 'Settled';

  @override
  String dueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due tomorrow',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String overdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get toReceiveLabel => 'to receive';

  @override
  String get toPayLabel => 'to pay';

  @override
  String noUdharTitle(String name) {
    return 'No udhar with $name yet';
  }

  @override
  String get noUdharBody => 'Tap Lent or Borrowed to add one.';

  @override
  String get noPeopleTitle => 'No people yet';

  @override
  String get noPeopleBody => 'Add a person to track money you lend or borrow.';

  @override
  String get addLentTitle => 'Lent money';

  @override
  String get addBorrowedTitle => 'Borrowed money';

  @override
  String get person => 'Person';

  @override
  String get choosePerson => 'Choose a person';

  @override
  String get dueDate => 'Due date';

  @override
  String get noDueDate => 'No due date';

  @override
  String get remindMe => 'Remind me';

  @override
  String get onDueDay => 'On due day';

  @override
  String daysBefore(int days) {
    return '$days days before';
  }

  @override
  String get saveLent => 'Save lent';

  @override
  String get saveBorrowed => 'Save borrowed';

  @override
  String get change => 'Change';

  @override
  String get fromContactsOrNew => 'From contacts or add new';

  @override
  String get chooseWhoLent => 'Choose who you gave money to';

  @override
  String get chooseWhoBorrowed => 'Choose who you borrowed from';

  @override
  String youGave(String name) {
    return 'You gave $name';
  }

  @override
  String youTook(String name) {
    return 'You took from $name';
  }

  @override
  String get youGaveSomeone => 'You gave someone';

  @override
  String get youTookSomeone => 'You took from someone';

  @override
  String get oneWeek => '1 week';

  @override
  String get twoWeeks => '2 weeks';

  @override
  String get oneMonth => '1 month';

  @override
  String get pickDate => 'Pick date';

  @override
  String get remindOff => 'Off';

  @override
  String get repaymentTitle => 'Repayment';

  @override
  String repaymentFrom(String name) {
    return 'From $name';
  }

  @override
  String repaymentTo(String name) {
    return 'To $name';
  }

  @override
  String remainingNow(String amount) {
    return '$amount remaining';
  }

  @override
  String get savePayment => 'Save payment';

  @override
  String get paymentSaved => 'Payment saved';

  @override
  String get udharRepaid => 'Udhar repaid';

  @override
  String get extraAmount => 'Extra';

  @override
  String get totalAmount => 'Total';

  @override
  String extraAsBorrowed(String amount) {
    return '$amount extra. Add it as borrowed?';
  }

  @override
  String extraAsLent(String amount) {
    return '$amount extra. Add it as lent?';
  }

  @override
  String extraNotAddedLent(String amount) {
    return '$amount extra not added · Add as lent';
  }

  @override
  String extraNotAddedBorrowed(String amount) {
    return '$amount extra not added · Add as borrowed';
  }

  @override
  String get udharDueToday => 'Udhar due today';

  @override
  String get didYouGetIt => 'Did you get it?';

  @override
  String get didYouPayBack => 'Did you pay it back?';

  @override
  String gotFull(String amount) {
    return 'Got full $amount';
  }

  @override
  String paidFull(String amount) {
    return 'Paid full $amount';
  }

  @override
  String get gotSome => 'Got some';

  @override
  String get paidSome => 'Paid some';

  @override
  String get notYet => 'Not yet';

  @override
  String get changeDueDate => 'Change due date';

  @override
  String get howMuchGot => 'How much did you get?';

  @override
  String get howMuchPaid => 'How much did you pay?';

  @override
  String stillLeft(String amount) {
    return '$amount will still be left';
  }

  @override
  String dueDateChanged(String from, String to) {
    return 'Due date changed: $from → $to';
  }

  @override
  String lentOnDate(String amount, String date) {
    return 'Lent $amount on $date';
  }

  @override
  String borrowedOnDate(String amount, String date) {
    return 'Borrowed $amount on $date';
  }

  @override
  String alreadyBack(String amount) {
    return '$amount already back';
  }

  @override
  String dueKeepOrChange(String date) {
    return 'Due date: keep $date or change';
  }

  @override
  String saveAmount(String amount) {
    return 'Save $amount';
  }

  @override
  String get emiBillsTitle => 'EMI & Bills';

  @override
  String get emis => 'EMIs';

  @override
  String get bills => 'Bills';

  @override
  String get dueThisMonth => 'Due this month';

  @override
  String emiCountNext(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count EMIs',
      one: '1 EMI',
    );
    return '$_temp0 · next on $date';
  }

  @override
  String get emiName => 'Name';

  @override
  String get emiNameHint => 'Bike loan';

  @override
  String get lenderOptional => 'Lender (optional)';

  @override
  String get lenderShort => 'Lender';

  @override
  String get itemPrice => 'Item price';

  @override
  String get downPayment => 'Down payment';

  @override
  String get loanAmount => 'Loan amount';

  @override
  String get interestYearly => 'Interest (yearly)';

  @override
  String get firstEmiDate => 'First EMI';

  @override
  String get iKnowThe => 'I know the';

  @override
  String get months => 'Months';

  @override
  String get emiAmount => 'EMI amount';

  @override
  String get numberOfMonths => 'Number of months';

  @override
  String get yourEmi => 'Your EMI';

  @override
  String get perMonth => '/month';

  @override
  String get totalInterest => 'Total interest';

  @override
  String get totalToPay => 'Total to pay';

  @override
  String get lastEmi => 'Last EMI';

  @override
  String get endsOn => 'Ends';

  @override
  String get itWillTake => 'It will take';

  @override
  String monthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get notPossible => 'Not possible';

  @override
  String get notPossibleTitle => 'EMI is less than the monthly interest';

  @override
  String notPossibleBody(String interest, String loan, String rate) {
    return 'Interest alone is $interest a month on $loan at $rate%. Enter more than $interest, or choose months.';
  }

  @override
  String get saveEmi => 'Save EMI';

  @override
  String get emiNameMissing => 'Give this EMI a name';

  @override
  String get loanMissing => 'Enter the loan amount';

  @override
  String get emiTermMissing => 'Enter months or the EMI amount';

  @override
  String paidOfTotal(int paid, int total) {
    return '$paid of $total paid';
  }

  @override
  String leftCount(int count) {
    return '$count left';
  }

  @override
  String remainingAmount(String amount) {
    return '$amount remaining';
  }

  @override
  String get remainingToPay => 'Remaining to pay';

  @override
  String endsMonth(String month) {
    return 'Ends $month';
  }

  @override
  String get emiLabel => 'EMI';

  @override
  String get loanLabel => 'Loan';

  @override
  String get interestLabel => 'Interest';

  @override
  String get installments => 'Installments';

  @override
  String earlierPaid(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count earlier paid',
      one: '1 earlier paid',
    );
    return '$_temp0';
  }

  @override
  String get paidOnTime => 'Paid on time';

  @override
  String paidOnDate(String date) {
    return 'Paid on $date';
  }

  @override
  String inclInterest(String amount) {
    return 'incl. $amount interest';
  }

  @override
  String get markPaid => 'Mark paid';

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String get markUnpaid => 'Mark as unpaid';

  @override
  String installmentOf(int n, int total, String date) {
    return 'Installment $n of $total · due $date';
  }

  @override
  String get paidOn => 'Paid on';

  @override
  String expenseAddedIn(String amount, String category) {
    return 'An expense of $amount is added in $category category.';
  }

  @override
  String installmentPaid(int n) {
    return 'Installment $n paid';
  }

  @override
  String expenseAddedLeft(int count) {
    return 'Expense added · $count left';
  }

  @override
  String get emiDueToday => 'EMI due today';

  @override
  String get paidOrNot => 'Paid or not?';

  @override
  String get paid => 'Paid';

  @override
  String get paidAddsExpense => '\"Paid\" adds the expense and updates the EMI';

  @override
  String get closed => 'Closed';

  @override
  String get emiClosed => 'Loan closed';

  @override
  String get noEmisTitle => 'No EMIs yet';

  @override
  String get noEmisBody =>
      'Add a loan or phone EMI. We work out every installment and remind you.';

  @override
  String get emiLockTitle => 'Never miss an EMI or bill';

  @override
  String get emiLockBody =>
      'Track every installment, get a reminder before the due date, and add the payment in one tap.';

  @override
  String get deleteEmiTitle => 'Delete this EMI?';

  @override
  String get deleteEmiBody =>
      'All its installments are removed. Expenses already added stay.';

  @override
  String get billWhich => 'Which bill?';

  @override
  String get billWhichSub => 'Pick a type. You can change the name later.';

  @override
  String get billElectricity => 'Electricity';

  @override
  String get billGas => 'Gas';

  @override
  String get billMobile => 'Mobile';

  @override
  String get billInternet => 'Internet';

  @override
  String get billDth => 'DTH / Cable';

  @override
  String get billWater => 'Water';

  @override
  String get billInsurance => 'Insurance';

  @override
  String get billOther => 'Other';

  @override
  String billTypeBill(String type) {
    return '$type bill';
  }

  @override
  String get popular => 'Popular';

  @override
  String everyNMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'every $count months',
      one: 'every month',
    );
    return '$_temp0';
  }

  @override
  String get billName => 'Name';

  @override
  String get billNameHint => 'Company name';

  @override
  String get customerIdOptional => 'Customer ID (optional)';

  @override
  String get customerIdHint => 'Add for your reference';

  @override
  String get comesEvery => 'Comes every (months)';

  @override
  String get nextDueDate => 'Next due date';

  @override
  String get chooseNextDue => 'Choose the next due date';

  @override
  String thenDates(String dates) {
    return 'Then $dates…';
  }

  @override
  String get usualAmountOptional => 'Usual amount (optional)';

  @override
  String get saveBill => 'Save bill';

  @override
  String get editBill => 'Edit bill';

  @override
  String get billsThisMonth => 'Bills this month';

  @override
  String billsPaidLeft(int paid, int left) {
    return '$paid paid · $left left';
  }

  @override
  String get thisMonth => 'This month';

  @override
  String get later => 'Later';

  @override
  String lastBill(String amount) {
    return 'Last bill $amount';
  }

  @override
  String billTapPaid(String amount) {
    return 'Last bill $amount · tap Paid to confirm';
  }

  @override
  String get noBillsTitle => 'No bills yet';

  @override
  String get noBillsBody =>
      'Add electricity, gas, mobile and other bills. We remind you on the due day.';

  @override
  String get billDueToday => 'Bill due today';

  @override
  String billDueInfo(String date, String every) {
    return 'Due $date · $every';
  }

  @override
  String get didYouPayBill => 'Did you pay this bill?';

  @override
  String get yesPaid => 'Yes, paid';

  @override
  String get notYetTomorrow => 'Not yet = we ask again tomorrow';

  @override
  String get howMuchWasIt => 'How much was it?';

  @override
  String monthBill(String month) {
    return '$month bill';
  }

  @override
  String get usualLabel => 'Usual';

  @override
  String get otherAmount => 'Other amount';

  @override
  String addedToCategory(String category) {
    return 'Added to Expenses · $category';
  }

  @override
  String get pauseBill => 'Pause bill';

  @override
  String get resumeBill => 'Resume bill';

  @override
  String get pausedTag => 'Paused';

  @override
  String get deleteBill => 'Delete bill';

  @override
  String get deleteBillTitle => 'Delete this bill?';

  @override
  String get deleteBillBody =>
      'Its payment history is removed. Expenses already added stay.';

  @override
  String get payments => 'Payments';

  @override
  String get noPaymentsYet => 'No payments yet';

  @override
  String get nextDue => 'Next due';

  @override
  String get billPausedNote =>
      'Paused: no reminders or popups until you resume it.';

  @override
  String get spending => 'Spending';

  @override
  String get trends => 'Trends';

  @override
  String get budget => 'Budget';

  @override
  String budgetOfLimit(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String spentIn(String month) {
    return 'Spent in $month';
  }

  @override
  String vsMonthDown(int pct, String month) {
    return '↓ $pct% vs $month';
  }

  @override
  String vsMonthUp(int pct, String month) {
    return '↑ $pct% vs $month';
  }

  @override
  String get includeUdhar => 'Include udhar';

  @override
  String get noSpendingTitle => 'No spending this month';

  @override
  String get noSpendingBody => 'Add expenses to see where your money goes.';

  @override
  String get lastSixMonths => 'Last 6 months';

  @override
  String get avgIncome => 'Avg income';

  @override
  String get avgExpense => 'Avg expense';

  @override
  String get savedLabel => 'Saved';

  @override
  String get bestMonthSaving => 'Best month for saving';

  @override
  String get chartsLockTitle => 'See where your money goes';

  @override
  String get chartsLockBody =>
      'Spending by category, 6-month trends and monthly budget.';

  @override
  String get setMonthlyBudget => 'Set a monthly budget';

  @override
  String budgetSuggestion(String amount) {
    return 'Suggestion: $amount (average of the last 3 months)';
  }

  @override
  String get spentThisMonth => 'Spent this month';

  @override
  String leftDaysPerDay(String left, int days, String perDay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$left left · $_temp0 · $perDay/day';
  }

  @override
  String amountOver(String amount) {
    return '$amount over';
  }

  @override
  String get categoryLimits => 'Category limits';

  @override
  String get addCategoryLimit => 'Add category limit';

  @override
  String categoryLimitTitle(String name) {
    return '$name limit';
  }

  @override
  String get monthlyBudgetTitle => 'Monthly budget';

  @override
  String get everyMonth => 'Every month';

  @override
  String avgThreeMonths(String amount) {
    return 'Avg 3 months · $amount';
  }

  @override
  String get alertMe => 'Alert me';

  @override
  String get alertAt => 'At 80% and 100%';

  @override
  String get removeLabel => 'Remove';

  @override
  String get saveLimit => 'Save limit';

  @override
  String get pickCategory => 'Pick a category';

  @override
  String percentOf(int pct) {
    return '$pct%';
  }

  @override
  String ofLimit(String limit) {
    return 'of $limit';
  }

  @override
  String daysPerDay(int days, String perDay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 · $perDay/day';
  }

  @override
  String get searchHint => 'Search entries and people';

  @override
  String get filterPeople => 'People';

  @override
  String entriesCount(int count) {
    return 'Entries · $count';
  }

  @override
  String get allTime => 'All time';

  @override
  String get recentSearches => 'Recent';

  @override
  String get searchTips =>
      'Try a name, an amount like 2000, a category or a note.';

  @override
  String get trySearching => 'Try searching';

  @override
  String get tipName => 'A name · “Rahul”';

  @override
  String get tipNote => 'A note or title · “dinner”';

  @override
  String get tipAmount => 'An amount · “2000”';

  @override
  String noResultsFor(String q) {
    return 'No results for “$q”';
  }

  @override
  String get noResultsBody =>
      'No entry has this word in the title, note or category.';

  @override
  String get searchInAll => 'Search in All';

  @override
  String get searchPremiumTitle => 'Search is Premium';

  @override
  String get searchPremiumBody =>
      'Find any entry or person in a second, even offline.';

  @override
  String repaymentWith(String name) {
    return 'Repayment · $name';
  }

  @override
  String get exportTitle => 'Export';

  @override
  String get exportLockTitle => 'Export your money as PDF or CSV';

  @override
  String get exportLockBody =>
      'A neat report to keep, print or share. Made on your phone.';

  @override
  String get exportData => 'Export data';

  @override
  String get formatLabel => 'Format';

  @override
  String get pdfDesc => 'Easy to read & share';

  @override
  String get csvDesc => 'For Excel / Sheets';

  @override
  String get dateRange => 'Date range';

  @override
  String get rangeThisMonth => 'This month';

  @override
  String get rangeLastMonth => 'Last month';

  @override
  String get range3Months => '3 months';

  @override
  String get rangeThisYear => 'This year';

  @override
  String get rangeCustom => 'Custom';

  @override
  String get includeLabel => 'Include';

  @override
  String get incExpLabel => 'Income & expenses';

  @override
  String get udharLabel => 'Lent & borrowed';

  @override
  String get emiBillsLabel => 'EMI & bills';

  @override
  String entriesN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String paymentsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String get exportPrivacy =>
      'The file is made on your phone. Only you decide where to share it.';

  @override
  String exportButton(String format, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return 'Export $format · $_temp0';
  }

  @override
  String get chooseSomething => 'Choose at least one thing to include';

  @override
  String get reportReady => 'Report ready';

  @override
  String fileInfoPdf(String name, int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages pages',
      one: '1 page',
    );
    return '$name · $_temp0 · $size';
  }

  @override
  String fileInfoCsv(String name, String size) {
    return '$name · $size';
  }

  @override
  String get savedInDownloads => 'Saved in Downloads';

  @override
  String get openLabel => 'Open';

  @override
  String get shareLabel => 'Share';

  @override
  String get shareHint => 'Opens your phone\'s share menu';

  @override
  String get exportFailed => 'Could not save the file. Try again.';

  @override
  String get reportTitle => 'Report';

  @override
  String periodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get madeOnPhone => 'Made on your phone with CashFlow';

  @override
  String pageOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get colDate => 'Date';

  @override
  String get colType => 'Type';

  @override
  String get colDetails => 'Details';

  @override
  String get colPayment => 'Payment';

  @override
  String get colAmount => 'Amount';

  @override
  String get colNote => 'Note';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get billLabel => 'Bill';

  @override
  String get exportingLabel => 'Making the file…';

  @override
  String ratePerYear(String rate) {
    return '$rate% a year';
  }

  @override
  String get noCost => 'No-cost';

  @override
  String dueOnDate(String date) {
    return 'Due $date';
  }

  @override
  String get lastTag => 'Last';

  @override
  String paidCountLabel(int count) {
    return '$count paid';
  }

  @override
  String get editEmi => 'Edit EMI';

  @override
  String get deleteEmi => 'Delete EMI';

  @override
  String get totalsMayDiffer =>
      'Totals can differ a little from your lender\'s schedule.';

  @override
  String get emiTermsLocked =>
      'Loan details can\'t change after an installment is paid.';

  @override
  String get chooseIcon => 'Choose an icon';

  @override
  String get devPremiumToggle => 'Premium (dev only)';

  @override
  String get devGallery => 'Widget gallery (dev)';
}
