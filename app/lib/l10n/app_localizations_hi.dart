// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'CashFlow';

  @override
  String get tagline => 'हर रुपये का हिसाब';

  @override
  String get save => 'सेव करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'बदलें';

  @override
  String get done => 'हो गया';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get skip => 'छोड़ें';

  @override
  String get close => 'बंद करें';

  @override
  String get undo => 'वापस लें';

  @override
  String get yes => 'हाँ';

  @override
  String get add => 'जोड़ें';

  @override
  String get search => 'खोजें';

  @override
  String get required => 'ज़रूरी';

  @override
  String get optional => 'वैकल्पिक';

  @override
  String get now => 'अभी';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get back => 'वापस';

  @override
  String get more => 'और';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get navHome => 'होम';

  @override
  String get navContacts => 'संपर्क';

  @override
  String get navCharts => 'चार्ट';

  @override
  String get navEmi => 'EMI';

  @override
  String get expense => 'खर्च';

  @override
  String get income => 'आमदनी';

  @override
  String get lent => 'उधार दिया';

  @override
  String get borrowed => 'उधार लिया';

  @override
  String get udhar => 'उधार';

  @override
  String get addEntry => 'जोड़ें';

  @override
  String get addEmi => 'EMI जोड़ें';

  @override
  String get addBill => 'बिल जोड़ें';

  @override
  String get cash => 'नकद';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get upi => 'UPI';

  @override
  String get card => 'कार्ड';

  @override
  String get bank => 'बैंक';

  @override
  String get paidVia => 'कैसे दिया';

  @override
  String get receivedIn => 'कैसे मिला';

  @override
  String get choosePayment => 'चुनें कि कैसे भुगतान किया';

  @override
  String get chooseReceived => 'चुनें कि कैसे मिला';

  @override
  String get amount => 'रकम';

  @override
  String get enterAmount => 'रकम लिखें';

  @override
  String get titleOptional => 'नाम (वैकल्पिक)';

  @override
  String get addTitle => 'नाम लिखें';

  @override
  String get date => 'तारीख';

  @override
  String get time => 'समय';

  @override
  String get note => 'नोट';

  @override
  String get addNote => 'नोट लिखें';

  @override
  String get category => 'श्रेणी';

  @override
  String get premium => 'प्रीमियम';

  @override
  String get premiumTryButton => 'प्रीमियम आज़माएं · 3 महीने ₹1';

  @override
  String get premiumFineprint => 'फिर ₹20/महीना। कभी भी बंद करें।';

  @override
  String get premiumSheetDueTitle => 'ड्यू डेट प्रीमियम में है';

  @override
  String premiumSheetDueBody(String name) {
    return '$name कब लौटाएगा, यह तय करें और उस दिन से पहले रिमाइंडर पाएं।';
  }

  @override
  String get premiumSeeAll => 'सारी सुविधाएं देखें';

  @override
  String get premiumSavedWithout => 'आपकी एंट्री बिना ड्यू डेट के सेव हो गई।';

  @override
  String get premiumComingLater => 'प्रीमियम खरीदना अगले अपडेट में आएगा।';

  @override
  String get welcomeTitle => 'आपका पैसा,\nसाफ़ हिसाब में।';

  @override
  String get welcomeBody =>
      'आमदनी, खर्च, उधार और EMI। सब एक शांत, निजी जगह में।';

  @override
  String get welcomeLogin => 'लॉग इन';

  @override
  String get welcomeSignUp => 'अकाउंट बनाएं';

  @override
  String get welcomeOfflineNote =>
      'अकाउंट और सिंक अगले अपडेट में आएंगे। अभी आपका डेटा इसी फ़ोन में रहेगा।';

  @override
  String get welcomeF1 => 'कोई ड्यू डेट न छूटे';

  @override
  String get welcomeF1Sub => 'उधार, EMI और बिल की याद';

  @override
  String get welcomeF2 => 'बिना इंटरनेट चलता है';

  @override
  String get welcomeF2Sub => 'कभी भी एंट्री करें, बाद में सिंक';

  @override
  String get welcomeF3 => 'निजी और लॉक';

  @override
  String get welcomeF3Sub => 'PIN और फिंगरप्रिंट से सुरक्षित';

  @override
  String get languageTitle => 'अपनी भाषा चुनें';

  @override
  String get languageSubtitle => 'Choose your language · ભાષા પસંદ કરો';

  @override
  String get languageSearch => 'भाषा खोजें';

  @override
  String get languageLater => 'आप इसे कभी भी सेटिंग्स में बदल सकते हैं';

  @override
  String get pinCreateTitle => 'अपना PIN बनाएं';

  @override
  String get pinCreateBody =>
      'CashFlow खोलने के लिए आप ये 4 अंकों का PIN इस्तेमाल करेंगे।';

  @override
  String get pinAvoidEasy => '1234 या 0000 जैसे आसान PIN न रखें';

  @override
  String get pinStoredOnPhone =>
      'सिर्फ इसी फ़ोन में रहता है, कहीं नहीं भेजा जाता';

  @override
  String get pinConfirmTitle => 'PIN दोबारा डालें';

  @override
  String get pinConfirmBody => 'पक्का करने के लिए।';

  @override
  String get pinMismatch => 'PIN मेल नहीं खाया। फिर से कोशिश करें।';

  @override
  String get pinEnterTitle => 'अपना PIN डालें';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कोशिशें बाकी',
      one: '1 कोशिश बाकी',
    );
    return 'गलत PIN। $_temp0';
  }

  @override
  String pinLocked(int seconds) {
    return 'बहुत कोशिशें हो गईं। $seconds सेकंड बाद फिर करें';
  }

  @override
  String get pinForgot => 'PIN भूल गए?';

  @override
  String get pinForgotBody =>
      'नया PIN बनाने के लिए अपने अकाउंट से दोबारा लॉग इन करें। यह अकाउंट लॉगिन के साथ आएगा।';

  @override
  String get useFingerprint => 'फ़िंगरप्रिंट लगाएं';

  @override
  String get fingerprintTitle => 'फ़िंगरप्रिंट से खोलें?';

  @override
  String get fingerprintBody =>
      'उंगली लगाकर CashFlow खोलें। PIN भी चलता रहेगा।';

  @override
  String get fingerprintOnTitle => 'फिंगरप्रिंट चालू है';

  @override
  String get fingerprintOnBody =>
      'अगली बार CashFlow खोलने के लिए बस सेंसर छुएं।';

  @override
  String get fingerprintOnNote =>
      'इसे कभी भी Settings › App lock में बंद कर सकते हैं';

  @override
  String get fpFaster => 'तेज़';

  @override
  String get fpFasterSub => 'एक सेकंड से कम में ऐप खोलें';

  @override
  String get fpPinBackup => 'PIN बैकअप रहेगा';

  @override
  String get fpPinBackupSub => 'PIN कभी भी इस्तेमाल करें';

  @override
  String get fpNeverSee => 'हम आपका फिंगरप्रिंट कभी नहीं देखते';

  @override
  String get fpNeverSeeSub => 'वो आपके फ़ोन में ही रहता है';

  @override
  String get fingerprintEnable => 'फ़िंगरप्रिंट चालू करें';

  @override
  String get fingerprintNotSetTitle => 'पहले फ़िंगरप्रिंट सेट करें';

  @override
  String get fingerprintNotSetBody =>
      'फ़ोन की सेटिंग्स में फ़िंगरप्रिंट जोड़ें, फिर CashFlow सेटिंग्स में चालू करें।';

  @override
  String get fingerprintReason => 'CashFlow खोलें';

  @override
  String get fingerprintFailed => 'फ़िंगरप्रिंट नहीं पहचाना। PIN डालें।';

  @override
  String get openingTitle => 'आपका शुरुआती बैलेंस';

  @override
  String get openingBody => 'अभी आपके पास कितने पैसे हैं? अंदाज़ा भी चलेगा।';

  @override
  String get cashSub => 'आपके बटुए में';

  @override
  String get onlineSub => 'बैंक और UPI';

  @override
  String get totalBalance => 'कुल बैलेंस';

  @override
  String get openingNote =>
      'यह सिर्फ शुरुआत है। हम आपके बैंक से कभी नहीं जुड़ते। बाद में Settings में बदल सकते हैं।';

  @override
  String get next => 'आगे';

  @override
  String get openingCash => 'हाथ में नकद';

  @override
  String get openingOnline => 'बैंक / UPI में';

  @override
  String get openingTotal => 'कुल';

  @override
  String get skipForNow => 'अभी छोड़ें';

  @override
  String get contactsPermTitle => 'संपर्कों के साथ उधार का हिसाब';

  @override
  String get contactsPermBody =>
      'उधार देते या लेते समय एक टैप में व्यक्ति चुनें।';

  @override
  String get contactsPermPoint1 => 'लोग जल्दी मिलें';

  @override
  String get contactsPermPoint1Sub => 'नाम और नंबर टाइप नहीं करने पड़ेंगे';

  @override
  String get contactsPermPoint2 => 'संपर्क आपके फ़ोन में ही रहते हैं';

  @override
  String get contactsPermPoint2Sub => 'हम उन्हें सिर्फ़ इसी फ़ोन पर पढ़ते हैं';

  @override
  String get contactsPermPoint3 => 'सिर्फ़ जोड़े गए लोग सेव होते हैं';

  @override
  String get contactsPermPoint3Sub => 'सिर्फ़ नाम और नंबर';

  @override
  String get contactsPermAllow => 'संपर्क की अनुमति दें';

  @override
  String get greetingMorning => 'सुप्रभात';

  @override
  String get greetingAfternoon => 'नमस्ते';

  @override
  String get greetingEvening => 'शुभ संध्या';

  @override
  String balanceEndOf(String month) {
    return '$month के अंत में बैलेंस';
  }

  @override
  String cashBalance(String amount) {
    return 'नकद $amount';
  }

  @override
  String onlineBalance(String amount) {
    return 'ऑनलाइन $amount';
  }

  @override
  String get netThisMonth => 'इस महीने का कुल';

  @override
  String get transactions => 'लेन-देन';

  @override
  String get filterAll => 'सभी';

  @override
  String get noEntriesTitle => 'अभी कोई एंट्री नहीं';

  @override
  String get noEntriesBody =>
      'अपनी पहली आमदनी या खर्च जोड़ें। सिर्फ़ 5 सेकंड लगते हैं।';

  @override
  String get tapPlusToAdd => 'जोड़ने के लिए + दबाएं';

  @override
  String get deleteEntryTitle => 'यह एंट्री हटाएं?';

  @override
  String get deleteEntryBody => 'यह आपके बैलेंस और चार्ट से हट जाएगी।';

  @override
  String entryDeleted(String title) {
    return '\"$title\" हटा दिया';
  }

  @override
  String get hideAmounts => 'रकम छिपाएं';

  @override
  String get showAmounts => 'रकम दिखाएं';

  @override
  String get addExpenseTitle => 'खर्च जोड़ें';

  @override
  String get addIncomeTitle => 'आमदनी जोड़ें';

  @override
  String get editEntryTitle => 'एंट्री बदलें';

  @override
  String get saveExpense => 'खर्च सेव करें';

  @override
  String get saveIncome => 'आमदनी सेव करें';

  @override
  String get categoryExpenseTitle => 'खर्च की श्रेणी';

  @override
  String get categoryIncomeTitle => 'आमदनी की श्रेणी';

  @override
  String get categoryRecent => 'हाल की';

  @override
  String get categoryAll => 'सभी श्रेणियां';

  @override
  String get categorySearch => 'श्रेणी खोजें या बनाएं';

  @override
  String categoryCreate(String name) {
    return '\"$name\" बनाएं';
  }

  @override
  String get categoryCreateSub => 'नई श्रेणी, अगली बार के लिए सेव';

  @override
  String get catFood => 'खाना';

  @override
  String get catGroceries => 'राशन';

  @override
  String get catTravel => 'यात्रा';

  @override
  String get catFuel => 'पेट्रोल';

  @override
  String get catShopping => 'खरीदारी';

  @override
  String get catBills => 'बिल';

  @override
  String get catRent => 'किराया';

  @override
  String get catHealth => 'सेहत';

  @override
  String get catEducation => 'पढ़ाई';

  @override
  String get catFun => 'मनोरंजन';

  @override
  String get catRecharge => 'रिचार्ज';

  @override
  String get catGifts => 'तोहफ़े';

  @override
  String get catPersonal => 'निजी';

  @override
  String get catEmi => 'EMI';

  @override
  String get catOthers => 'अन्य';

  @override
  String get catSalary => 'तनख्वाह';

  @override
  String get catBusiness => 'व्यापार';

  @override
  String get catFreelance => 'फ़्रीलांस';

  @override
  String get catInterest => 'ब्याज';

  @override
  String get catGift => 'तोहफ़ा';

  @override
  String get catRefund => 'रिफ़ंड';

  @override
  String get contactsTitle => 'संपर्क';

  @override
  String get toReceive => 'लेने हैं';

  @override
  String get toPay => 'देने हैं';

  @override
  String peopleCount(int count) {
    return 'लोग · $count';
  }

  @override
  String get recentPeople => 'हाल के';

  @override
  String get searchPeople => 'लोग खोजें';

  @override
  String get allContacts => 'सभी संपर्क';

  @override
  String get contactsOffTitle => 'संपर्क बंद हैं';

  @override
  String get contactsOffBody =>
      'एक टैप में लोग चुनने के लिए चालू करें। या नाम और नंबर से व्यक्ति जोड़ें।';

  @override
  String get turnOn => 'चालू करें';

  @override
  String get addPerson => 'व्यक्ति जोड़ें';

  @override
  String get personName => 'नाम';

  @override
  String get personPhone => 'फ़ोन नंबर (वैकल्पिक)';

  @override
  String owesYou(String name) {
    return '$name को आपको देने हैं';
  }

  @override
  String youOwe(String name) {
    return 'आपको $name को देने हैं';
  }

  @override
  String get allClear => 'सब बराबर';

  @override
  String lentRepaid(String lent, String repaid) {
    return 'दिए $lent · लौटाए $repaid';
  }

  @override
  String get history => 'इतिहास';

  @override
  String get repayment => 'वापसी';

  @override
  String get repaymentReceived => 'वापसी मिली';

  @override
  String get repaymentPaid => 'वापसी दी';

  @override
  String repaidOf(String repaid, String total) {
    return '$total में से $repaid लौटाए';
  }

  @override
  String amountLeft(String amount) {
    return '$amount बाकी';
  }

  @override
  String get settled => 'चुकता';

  @override
  String dueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन में ड्यू',
      one: 'कल ड्यू',
      zero: 'आज ड्यू',
    );
    return '$_temp0';
  }

  @override
  String overdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन देर',
      one: '1 दिन देर',
    );
    return '$_temp0';
  }

  @override
  String get toReceiveLabel => 'लेने हैं';

  @override
  String get toPayLabel => 'देने हैं';

  @override
  String noUdharTitle(String name) {
    return '$name के साथ अभी कोई उधार नहीं';
  }

  @override
  String get noUdharBody => 'जोड़ने के लिए उधार दिया या उधार लिया दबाएं।';

  @override
  String get noPeopleTitle => 'अभी कोई व्यक्ति नहीं';

  @override
  String get noPeopleBody => 'उधार का हिसाब रखने के लिए व्यक्ति जोड़ें।';

  @override
  String get addLentTitle => 'उधार दिए पैसे';

  @override
  String get addBorrowedTitle => 'उधार लिए पैसे';

  @override
  String get person => 'व्यक्ति';

  @override
  String get choosePerson => 'व्यक्ति चुनें';

  @override
  String get dueDate => 'ड्यू डेट';

  @override
  String get noDueDate => 'कोई ड्यू डेट नहीं';

  @override
  String get remindMe => 'याद दिलाएं';

  @override
  String get onDueDay => 'ड्यू वाले दिन';

  @override
  String daysBefore(int days) {
    return '$days दिन पहले';
  }

  @override
  String get saveLent => 'उधार सेव करें';

  @override
  String get saveBorrowed => 'उधार सेव करें';

  @override
  String get change => 'बदलें';

  @override
  String get fromContactsOrNew => 'कॉन्टैक्ट से या नया जोड़ें';

  @override
  String get chooseWhoLent => 'किसे पैसे दिए, चुनें';

  @override
  String get chooseWhoBorrowed => 'किससे लिए, चुनें';

  @override
  String youGave(String name) {
    return 'आपने $name को दिए';
  }

  @override
  String youTook(String name) {
    return 'आपने $name से लिए';
  }

  @override
  String get youGaveSomeone => 'आपने किसी को दिए';

  @override
  String get youTookSomeone => 'आपने किसी से लिए';

  @override
  String get oneWeek => '1 हफ्ता';

  @override
  String get twoWeeks => '2 हफ्ते';

  @override
  String get oneMonth => '1 महीना';

  @override
  String get pickDate => 'तारीख चुनें';

  @override
  String get remindOff => 'बंद';

  @override
  String get repaymentTitle => 'वापसी';

  @override
  String repaymentFrom(String name) {
    return '$name से';
  }

  @override
  String repaymentTo(String name) {
    return '$name को';
  }

  @override
  String remainingNow(String amount) {
    return '$amount बाकी';
  }

  @override
  String get savePayment => 'भुगतान सेव करें';

  @override
  String get paymentSaved => 'भुगतान सेव हो गया';

  @override
  String get udharRepaid => 'उधार चुकाया';

  @override
  String get extraAmount => 'ज़्यादा';

  @override
  String get totalAmount => 'कुल';

  @override
  String extraAsBorrowed(String amount) {
    return '$amount ज़्यादा। इसे उधार लिया में जोड़ें?';
  }

  @override
  String extraAsLent(String amount) {
    return '$amount ज़्यादा। इसे उधार दिया में जोड़ें?';
  }

  @override
  String extraNotAddedLent(String amount) {
    return '$amount ज़्यादा नहीं जोड़ा · उधार दिया में जोड़ें';
  }

  @override
  String extraNotAddedBorrowed(String amount) {
    return '$amount ज़्यादा नहीं जोड़ा · उधार लिया में जोड़ें';
  }

  @override
  String get udharDueToday => 'उधार आज ड्यू है';

  @override
  String get didYouGetIt => 'क्या पैसे मिले?';

  @override
  String get didYouPayBack => 'क्या आपने लौटा दिए?';

  @override
  String gotFull(String amount) {
    return 'पूरे $amount मिले';
  }

  @override
  String paidFull(String amount) {
    return 'पूरे $amount दिए';
  }

  @override
  String get gotSome => 'कुछ मिले';

  @override
  String get paidSome => 'कुछ दिए';

  @override
  String get notYet => 'अभी नहीं';

  @override
  String get changeDueDate => 'ड्यू डेट बदलें';

  @override
  String get howMuchGot => 'कितने मिले?';

  @override
  String get howMuchPaid => 'कितने दिए?';

  @override
  String stillLeft(String amount) {
    return '$amount फिर भी बाकी रहेंगे';
  }

  @override
  String dueDateChanged(String from, String to) {
    return 'ड्यू डेट बदली: $from → $to';
  }

  @override
  String lentOnDate(String amount, String date) {
    return '$date को $amount दिए';
  }

  @override
  String borrowedOnDate(String amount, String date) {
    return '$date को $amount लिए';
  }

  @override
  String alreadyBack(String amount) {
    return '$amount वापस आ चुके';
  }

  @override
  String dueKeepOrChange(String date) {
    return 'ड्यू डेट: $date रखें या बदलें';
  }

  @override
  String saveAmount(String amount) {
    return '$amount सेव करें';
  }

  @override
  String get emiBillsTitle => 'EMI और बिल';

  @override
  String get emis => 'EMI';

  @override
  String get bills => 'बिल';

  @override
  String get dueThisMonth => 'इस महीने देने हैं';

  @override
  String emiCountNext(int count, String date) {
    return '$count EMI · अगली $date को';
  }

  @override
  String get emiName => 'नाम';

  @override
  String get emiNameHint => 'बाइक लोन';

  @override
  String get lenderOptional => 'देने वाला (वैकल्पिक)';

  @override
  String get lenderShort => 'लेंडर';

  @override
  String get itemPrice => 'सामान की कीमत';

  @override
  String get downPayment => 'डाउन पेमेंट';

  @override
  String get loanAmount => 'लोन की रकम';

  @override
  String get interestYearly => 'ब्याज (सालाना)';

  @override
  String get firstEmiDate => 'पहली EMI';

  @override
  String get iKnowThe => 'मुझे पता है';

  @override
  String get months => 'महीने';

  @override
  String get emiAmount => 'EMI रकम';

  @override
  String get numberOfMonths => 'कितने महीने';

  @override
  String get yourEmi => 'आपकी EMI';

  @override
  String get perMonth => '/महीना';

  @override
  String get totalInterest => 'कुल ब्याज';

  @override
  String get totalToPay => 'कुल देना';

  @override
  String get lastEmi => 'आखिरी EMI';

  @override
  String get endsOn => 'खत्म';

  @override
  String get itWillTake => 'इतना समय लगेगा';

  @override
  String monthsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count महीने',
      one: '1 महीना',
    );
    return '$_temp0';
  }

  @override
  String get notPossible => 'संभव नहीं';

  @override
  String get notPossibleTitle => 'EMI महीने के ब्याज से कम है';

  @override
  String notPossibleBody(String interest, String loan, String rate) {
    return 'सिर्फ ब्याज ही $loan पर $rate% से $interest महीना है। $interest से ज़्यादा डालें, या महीने चुनें।';
  }

  @override
  String get saveEmi => 'EMI सेव करें';

  @override
  String get emiNameMissing => 'इस EMI का नाम लिखें';

  @override
  String get loanMissing => 'लोन की रकम लिखें';

  @override
  String get emiTermMissing => 'महीने या EMI रकम लिखें';

  @override
  String paidOfTotal(int paid, int total) {
    return '$total में से $paid दी';
  }

  @override
  String leftCount(int count) {
    return '$count बाकी';
  }

  @override
  String remainingAmount(String amount) {
    return '$amount बाकी';
  }

  @override
  String get remainingToPay => 'देना बाकी';

  @override
  String endsMonth(String month) {
    return '$month में खत्म';
  }

  @override
  String get emiLabel => 'EMI';

  @override
  String get loanLabel => 'लोन';

  @override
  String get interestLabel => 'ब्याज';

  @override
  String get installments => 'किस्तें';

  @override
  String earlierPaid(int count) {
    return '$count पहले दी';
  }

  @override
  String get paidOnTime => 'समय पर दी';

  @override
  String paidOnDate(String date) {
    return '$date को दी';
  }

  @override
  String inclInterest(String amount) {
    return '$amount ब्याज सहित';
  }

  @override
  String get markPaid => 'दी गई';

  @override
  String get markAsPaid => 'दी गई मार्क करें';

  @override
  String get markUnpaid => 'नहीं दी मार्क करें';

  @override
  String installmentOf(int n, int total, String date) {
    return 'किस्त $n / $total · ड्यू $date';
  }

  @override
  String get paidOn => 'कब दी';

  @override
  String expenseAddedIn(String amount, String category) {
    return '$amount का खर्च $category श्रेणी में जुड़ जाएगा।';
  }

  @override
  String installmentPaid(int n) {
    return 'किस्त $n दी गई';
  }

  @override
  String expenseAddedLeft(int count) {
    return 'खर्च जुड़ा · $count बाकी';
  }

  @override
  String get emiDueToday => 'EMI आज ड्यू है';

  @override
  String get paidOrNot => 'दी या नहीं?';

  @override
  String get paid => 'दी';

  @override
  String get paidAddsExpense =>
      '\"दी\" दबाने पर खर्च जुड़ेगा और EMI अपडेट होगी';

  @override
  String get closed => 'बंद';

  @override
  String get emiClosed => 'लोन पूरा हुआ';

  @override
  String get noEmisTitle => 'अभी कोई EMI नहीं';

  @override
  String get noEmisBody =>
      'लोन या फ़ोन की EMI जोड़ें। हम हर किस्त का हिसाब लगाकर याद दिलाएंगे।';

  @override
  String get emiLockTitle => 'कोई EMI या बिल न भूलें';

  @override
  String get emiLockBody =>
      'हर किस्त का हिसाब, ड्यू डेट से पहले रिमाइंडर, और एक टैप में भुगतान दर्ज।';

  @override
  String get deleteEmiTitle => 'यह EMI हटाएं?';

  @override
  String get deleteEmiBody =>
      'इसकी सभी किस्तें हट जाएंगी। पहले जुड़े खर्च रहेंगे।';

  @override
  String get billWhich => 'कौन सा बिल?';

  @override
  String get billWhichSub => 'टाइप चुनें। नाम बाद में बदल सकते हैं।';

  @override
  String get billElectricity => 'बिजली';

  @override
  String get billGas => 'गैस';

  @override
  String get billMobile => 'मोबाइल';

  @override
  String get billInternet => 'इंटरनेट';

  @override
  String get billDth => 'DTH / केबल';

  @override
  String get billWater => 'पानी';

  @override
  String get billInsurance => 'बीमा';

  @override
  String get billOther => 'अन्य';

  @override
  String billTypeBill(String type) {
    return '$type बिल';
  }

  @override
  String get popular => 'लोकप्रिय';

  @override
  String everyNMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'हर $count महीने',
      one: 'हर महीने',
    );
    return '$_temp0';
  }

  @override
  String get billName => 'नाम';

  @override
  String get billNameHint => 'कंपनी का नाम';

  @override
  String get customerIdOptional => 'कस्टमर ID (वैकल्पिक)';

  @override
  String get customerIdHint => 'याद रखने के लिए';

  @override
  String get comesEvery => 'हर कितने महीने में आता है';

  @override
  String get nextDueDate => 'अगली ड्यू डेट';

  @override
  String get chooseNextDue => 'अगली ड्यू डेट चुनें';

  @override
  String thenDates(String dates) {
    return 'फिर $dates…';
  }

  @override
  String get usualAmountOptional => 'आम रकम (वैकल्पिक)';

  @override
  String get saveBill => 'बिल सेव करें';

  @override
  String get editBill => 'बिल बदलें';

  @override
  String get billsThisMonth => 'इस महीने के बिल';

  @override
  String billsPaidLeft(int paid, int left) {
    return '$paid भरे · $left बाकी';
  }

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get later => 'बाद में';

  @override
  String lastBill(String amount) {
    return 'पिछला बिल $amount';
  }

  @override
  String billTapPaid(String amount) {
    return 'पिछला बिल $amount · भरा हो तो टैप करें';
  }

  @override
  String get noBillsTitle => 'अभी कोई बिल नहीं';

  @override
  String get noBillsBody =>
      'बिजली, गैस, मोबाइल और दूसरे बिल जोड़ें। ड्यू के दिन याद दिलाएंगे।';

  @override
  String get billDueToday => 'आज बिल ड्यू है';

  @override
  String billDueInfo(String date, String every) {
    return 'ड्यू $date · $every';
  }

  @override
  String get didYouPayBill => 'क्या ये बिल भर दिया?';

  @override
  String get yesPaid => 'हाँ, भर दिया';

  @override
  String get notYetTomorrow => 'अभी नहीं = कल फिर पूछेंगे';

  @override
  String get howMuchWasIt => 'कितना आया?';

  @override
  String monthBill(String month) {
    return '$month बिल';
  }

  @override
  String get usualLabel => 'आम';

  @override
  String get otherAmount => 'दूसरी रकम';

  @override
  String addedToCategory(String category) {
    return 'खर्च · $category में जुड़ेगा';
  }

  @override
  String get pauseBill => 'बिल रोकें';

  @override
  String get resumeBill => 'बिल फिर शुरू करें';

  @override
  String get pausedTag => 'रुका हुआ';

  @override
  String get deleteBill => 'बिल हटाएं';

  @override
  String get deleteBillTitle => 'ये बिल हटाएं?';

  @override
  String get deleteBillBody =>
      'इसकी पेमेंट हिस्ट्री हट जाएगी। जो खर्च जुड़ चुके हैं वो रहेंगे।';

  @override
  String get payments => 'पेमेंट';

  @override
  String get noPaymentsYet => 'अभी कोई पेमेंट नहीं';

  @override
  String get nextDue => 'अगली ड्यू';

  @override
  String get billPausedNote =>
      'रुका हुआ: फिर शुरू करने तक कोई याद या पॉपअप नहीं।';

  @override
  String get spending => 'खर्च';

  @override
  String get trends => 'ट्रेंड';

  @override
  String get budget => 'बजट';

  @override
  String budgetOfLimit(String spent, String limit) {
    return '$limit में से $spent';
  }

  @override
  String spentIn(String month) {
    return '$month में खर्च';
  }

  @override
  String vsMonthDown(int pct, String month) {
    return '↓ $pct% $month से';
  }

  @override
  String vsMonthUp(int pct, String month) {
    return '↑ $pct% $month से';
  }

  @override
  String get includeUdhar => 'उधार भी जोड़ें';

  @override
  String get noSpendingTitle => 'इस महीने कोई खर्च नहीं';

  @override
  String get noSpendingBody => 'खर्च जोड़ें और देखें पैसा कहाँ जा रहा है।';

  @override
  String get lastSixMonths => 'पिछले 6 महीने';

  @override
  String get avgIncome => 'औसत आय';

  @override
  String get avgExpense => 'औसत खर्च';

  @override
  String get savedLabel => 'बचत';

  @override
  String get bestMonthSaving => 'बचत का सबसे अच्छा महीना';

  @override
  String get chartsLockTitle => 'देखें पैसा कहाँ जा रहा है';

  @override
  String get chartsLockBody =>
      'कैटेगरी के हिसाब से खर्च, 6 महीने का ट्रेंड और मासिक बजट।';

  @override
  String get setMonthlyBudget => 'मासिक बजट तय करें';

  @override
  String budgetSuggestion(String amount) {
    return 'सुझाव: $amount (पिछले 3 महीने का औसत)';
  }

  @override
  String get spentThisMonth => 'इस महीने खर्च';

  @override
  String leftDaysPerDay(String left, int days, String perDay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
    );
    return '$left बाकी · $_temp0 · $perDay/दिन';
  }

  @override
  String amountOver(String amount) {
    return '$amount ज़्यादा';
  }

  @override
  String get categoryLimits => 'कैटेगरी लिमिट';

  @override
  String get addCategoryLimit => 'कैटेगरी लिमिट जोड़ें';

  @override
  String categoryLimitTitle(String name) {
    return '$name लिमिट';
  }

  @override
  String get monthlyBudgetTitle => 'मासिक बजट';

  @override
  String get everyMonth => 'हर महीने';

  @override
  String avgThreeMonths(String amount) {
    return '3 महीने का औसत · $amount';
  }

  @override
  String get alertMe => 'मुझे बताएं';

  @override
  String get alertAt => '80% और 100% पर';

  @override
  String get removeLabel => 'हटाएं';

  @override
  String get saveLimit => 'लिमिट सेव करें';

  @override
  String get pickCategory => 'कैटेगरी चुनें';

  @override
  String percentOf(int pct) {
    return '$pct%';
  }

  @override
  String ofLimit(String limit) {
    return '$limit में से';
  }

  @override
  String daysPerDay(int days, String perDay) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन',
      one: '1 दिन',
    );
    return '$_temp0 · $perDay/दिन';
  }

  @override
  String get searchHint => 'एंट्री और लोग खोजें';

  @override
  String get filterPeople => 'लोग';

  @override
  String entriesCount(int count) {
    return 'एंट्री · $count';
  }

  @override
  String get allTime => 'सारा समय';

  @override
  String get recentSearches => 'हाल की';

  @override
  String get searchTips => 'नाम, 2000 जैसी रकम, कैटेगरी या नोट लिखकर देखें।';

  @override
  String noResultsFor(String q) {
    return '“$q” के लिए कुछ नहीं मिला';
  }

  @override
  String get noResultsBody =>
      'किसी एंट्री के टाइटल, नोट या कैटेगरी में ये शब्द नहीं है।';

  @override
  String get searchInAll => 'सब में खोजें';

  @override
  String get searchPremiumTitle => 'सर्च Premium में है';

  @override
  String get searchPremiumBody =>
      'कोई भी एंट्री या व्यक्ति एक सेकंड में ढूंढें, ऑफलाइन भी।';

  @override
  String repaymentWith(String name) {
    return 'वापसी · $name';
  }

  @override
  String get exportTitle => 'एक्सपोर्ट';

  @override
  String get exportData => 'डेटा एक्सपोर्ट करें';

  @override
  String get formatLabel => 'फॉर्मेट';

  @override
  String get pdfDesc => 'पढ़ने और भेजने में आसान';

  @override
  String get csvDesc => 'Excel / Sheets के लिए';

  @override
  String get dateRange => 'तारीख';

  @override
  String get rangeThisMonth => 'इस महीने';

  @override
  String get rangeLastMonth => 'पिछले महीने';

  @override
  String get range3Months => '3 महीने';

  @override
  String get rangeThisYear => 'इस साल';

  @override
  String get rangeCustom => 'अपनी तारीख';

  @override
  String get includeLabel => 'शामिल करें';

  @override
  String get incExpLabel => 'आय और खर्च';

  @override
  String get udharLabel => 'दिया और लिया';

  @override
  String get emiBillsLabel => 'EMI और बिल';

  @override
  String entriesN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एंट्री',
      one: '1 एंट्री',
    );
    return '$_temp0';
  }

  @override
  String paymentsN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पेमेंट',
      one: '1 पेमेंट',
    );
    return '$_temp0';
  }

  @override
  String get exportPrivacy =>
      'फाइल आपके फोन पर ही बनती है। कहाँ भेजनी है, आप तय करते हैं।';

  @override
  String exportButton(String format, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एंट्री',
      one: '1 एंट्री',
    );
    return '$format एक्सपोर्ट · $_temp0';
  }

  @override
  String get chooseSomething => 'कम से कम एक चीज़ चुनें';

  @override
  String get reportReady => 'रिपोर्ट तैयार';

  @override
  String fileInfoPdf(String name, int pages, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages पेज',
      one: '1 पेज',
    );
    return '$name · $_temp0 · $size';
  }

  @override
  String fileInfoCsv(String name, String size) {
    return '$name · $size';
  }

  @override
  String get savedInDownloads => 'Downloads में सेव हुई';

  @override
  String get openLabel => 'खोलें';

  @override
  String get shareLabel => 'शेयर करें';

  @override
  String get shareHint => 'फोन का शेयर मेनू खुलेगा';

  @override
  String get exportFailed => 'फाइल सेव नहीं हुई। फिर से कोशिश करें।';

  @override
  String get reportTitle => 'रिपोर्ट';

  @override
  String periodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get madeOnPhone => 'CashFlow से आपके फोन पर बनी';

  @override
  String pageOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get colDate => 'तारीख';

  @override
  String get colType => 'प्रकार';

  @override
  String get colDetails => 'विवरण';

  @override
  String get colPayment => 'पेमेंट';

  @override
  String get colAmount => 'रकम';

  @override
  String get colNote => 'नोट';

  @override
  String get spendingByCategory => 'कैटेगरी के हिसाब से खर्च';

  @override
  String get billLabel => 'बिल';

  @override
  String get exportingLabel => 'फाइल बन रही है…';

  @override
  String ratePerYear(String rate) {
    return '$rate% सालाना';
  }

  @override
  String get noCost => 'नो-कॉस्ट';

  @override
  String dueOnDate(String date) {
    return 'ड्यू $date';
  }

  @override
  String get lastTag => 'आखिरी';

  @override
  String paidCountLabel(int count) {
    return '$count भरी';
  }

  @override
  String get editEmi => 'EMI बदलें';

  @override
  String get deleteEmi => 'EMI हटाएं';

  @override
  String get totalsMayDiffer =>
      'कुल रकम लेंडर के हिसाब से थोड़ी अलग हो सकती है।';

  @override
  String get emiTermsLocked =>
      'किस्त भरने के बाद लोन की जानकारी नहीं बदल सकते।';

  @override
  String get chooseIcon => 'आइकन चुनें';

  @override
  String get devPremiumToggle => 'प्रीमियम (सिर्फ़ डेव)';

  @override
  String get devGallery => 'विजेट गैलरी (डेव)';
}
