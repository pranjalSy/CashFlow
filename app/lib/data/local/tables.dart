import 'package:drift/drift.dart';

/// Columns every synced table has (TRD 5): device-made UUID, owner, server-set `updatedAt`,
/// soft delete, and a local "not uploaded yet" flag. No foreign keys locally (TRD 6.1).
mixin SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Money columns are integer paise; rates are basis points; due dates are ISO `YYYY-MM-DD` text.

class Profiles extends Table with SyncColumns {
  TextColumn get name => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('en'))();
  IntColumn get openingCash => integer().withDefault(const Constant(0))();
  IntColumn get openingOnline => integer().withDefault(const Constant(0))();
  IntColumn get defaultReminderDays => integer().withDefault(const Constant(3))();
  BoolColumn get hideAmounts => boolean().withDefault(const Constant(false))();
  BoolColumn get analyticsOptIn => boolean().withDefault(const Constant(true))();
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
}

class Categories extends Table with SyncColumns {
  /// `income` or `expense`.
  TextColumn get kind => text()();
  TextColumn get name => text()();

  /// Key of a default category (for localized names); null for user-made ones.
  TextColumn get nameKey => text().nullable()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class People extends Table with SyncColumns {
  TextColumn get name => text()();

  /// E.164 (+919876543210); reuses the same person for the same number (FR-D7).
  TextColumn get phoneNormalized => text().nullable()();

  /// Phone contact id: a local cache only, never relied on across devices.
  TextColumn get contactCacheId => text().nullable()();
}

@DataClassName('Txn')
@TableIndex(name: 'txn_user_time', columns: {#userId, #occurredAt})
class Transactions extends Table with SyncColumns {
  /// `income` or `expense`.
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();

  /// `cash` or `online`.
  TextColumn get paymentMode => text()();

  /// `upi`, `card` or `bank` when online.
  TextColumn get onlineMethod => text().nullable()();
  TextColumn get note => text().nullable()();

  /// `manual`, `emi`, `bill` (linked entries created by atomic actions).
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get sourceId => text().nullable()();
}

@TableIndex(name: 'debt_person', columns: {#personId})
class Debts extends Table with SyncColumns {
  TextColumn get personId => text()();

  /// `lent` or `borrowed`.
  TextColumn get direction => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get paymentMode => text()();
  TextColumn get onlineMethod => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Premium (G3).
  TextColumn get dueDate => text().nullable()();

  /// Comma list of lead days, for example `0,3` (Premium).
  TextColumn get reminderDays => text().nullable()();

  /// `open`, `partial` or `settled`.
  TextColumn get status => text().withDefault(const Constant('open'))();

  /// Set when this debt was created from an overpayment of another debt (G7).
  TextColumn get extraFromDebtId => text().nullable()();

  /// Extra amount of an overpayment that the user did not add yet (G7 card line).
  IntColumn get extraNotAdded => integer().nullable()();
}

@TableIndex(name: 'payment_debt', columns: {#debtId})
class DebtPayments extends Table with SyncColumns {
  TextColumn get debtId => text()();

  /// Never more than the remaining amount (G8).
  IntColumn get amount => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get paymentMode => text()();
  TextColumn get onlineMethod => text().nullable()();
  TextColumn get note => text().nullable()();
}

class DebtExtensions extends Table with SyncColumns {
  TextColumn get debtId => text()();
  TextColumn get oldDueDate => text().nullable()();
  TextColumn get newDueDate => text()();
}

class Emis extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('bike'))();
  TextColumn get lender => text().nullable()();
  IntColumn get itemPrice => integer().nullable()();
  IntColumn get downPayment => integer().nullable()();
  IntColumn get loanAmount => integer()();
  IntColumn get rateBp => integer()();
  IntColumn get months => integer()();
  IntColumn get emiAmount => integer()();
  TextColumn get firstDueDate => text()();

  /// `active` or `closed`.
  TextColumn get status => text().withDefault(const Constant('active'))();
}

@TableIndex(name: 'installment_emi_due', columns: {#emiId, #dueDate})
class EmiInstallments extends Table with SyncColumns {
  TextColumn get emiId => text()();
  IntColumn get seq => integer()();
  TextColumn get dueDate => text()();
  IntColumn get amount => integer()();
  IntColumn get interestPart => integer()();
  IntColumn get principalPart => integer()();

  /// `due` or `paid`.
  TextColumn get status => text().withDefault(const Constant('due'))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  TextColumn get transactionId => text().nullable()();
}

class Bills extends Table with SyncColumns {
  /// electricity, gas, mobile, internet, dth, water, insurance, other.
  TextColumn get billType => text()();
  TextColumn get name => text()();

  /// For the user's reference only; never sent anywhere (I3).
  TextColumn get customerId => text().nullable()();

  /// 1, 2, 3, 6 or 12.
  IntColumn get everyMonths => integer()();
  TextColumn get nextDueDate => text()();
  IntColumn get usualAmount => integer().nullable()();
  TextColumn get reminderDays => text().nullable()();
  BoolColumn get paused => boolean().withDefault(const Constant(false))();
}

class BillPayments extends Table with SyncColumns {
  TextColumn get billId => text()();
  TextColumn get dueDate => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get paidAt => dateTime()();
  TextColumn get transactionId => text().nullable()();
}

class Budgets extends Table with SyncColumns {
  IntColumn get monthlyLimit => integer()();
  BoolColumn get alertEnabled => boolean().withDefault(const Constant(true))();
}

class BudgetCategoryLimits extends Table with SyncColumns {
  TextColumn get categoryId => text()();
  IntColumn get limitAmount => integer()();
  BoolColumn get alertEnabled => boolean().withDefault(const Constant(true))();
}

// ---- Phone-only tables (never uploaded) ----

/// Changes waiting to upload (TRD 8). Rows of one action share [batchId].
class SyncOutbox extends Table {
  IntColumn get seq => integer().autoIncrement()();

  /// `upsert` or `delete`.
  TextColumn get op => text()();
  TextColumn get entityTable => text()();
  TextColumn get rowId => text()();
  TextColumn get batchId => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Undo window: do not upload before this time (FR-H4, FR-E11).
  DateTimeColumn get notBefore => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Download position per table: last (updatedAt, id) seen (TRD 8).
class SyncCursors extends Table {
  TextColumn get entityTable => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get lastId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {entityTable};
}

/// Last known plan, mirrored from the server (TRD 13.2).
class PlanCache extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  TextColumn get basePlan => text().nullable()();
  DateTimeColumn get activeUntil => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Small local flags: first-run hints, last payment method, popup "ask again" dates, recent searches.
class AppFlags extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
