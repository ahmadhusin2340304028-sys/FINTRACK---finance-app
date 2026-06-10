class AppConstants {
  static const String appName = 'FinTrack';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'fintrack.db';
  static const int dbVersion = 1;

  // Table Names
  static const String tableUsers = 'users';
  static const String tableTransactions = 'transactions';
  static const String tableBudgets = 'budgets';
  static const String tableDebts = 'debts';
  static const String tableSavings = 'savings';
  static const String tableAccounts = 'accounts';

  // SharedPreferences Keys
  static const String prefCurrentUser = 'current_user_id';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefBiometric = 'biometric_enabled';
  static const String prefCurrency = 'currency';
  static const String prefOnboarding = 'onboarding_done';

  // Transaction Types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // Debt Status
  static const String statusUnpaid = 'unpaid';
  static const String statusPaid = 'paid';

  // Debt Types
  static const String debtTypeOwed = 'owed'; // hutang (kita yang berhutang)
  static const String debtTypeReceivable = 'receivable'; // piutang (orang lain berhutang ke kita)

  // Budget Periods
  static const String periodDaily = 'daily';
  static const String periodWeekly = 'weekly';
  static const String periodMonthly = 'monthly';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Makan',
    'Minum',
    'Transportasi',
    'Pulsa',
    'Internet',
    'Kos',
    'Kuliah',
    'Buku',
    'Hiburan',
    'Kesehatan',
    'Belanja',
    'Lainnya',
  ];

  // Income Categories
  static const List<String> incomeCategories = [
    'Uang Saku',
    'Beasiswa',
    'Part Time',
    'Freelance',
    'Bonus',
    'Lainnya',
  ];

  // Category Icons
  static const Map<String, String> categoryIcons = {
    'Makan': '🍽️',
    'Minum': '☕',
    'Transportasi': '🚌',
    'Pulsa': '📱',
    'Internet': '🌐',
    'Kos': '🏠',
    'Kuliah': '🎓',
    'Buku': '📚',
    'Hiburan': '🎮',
    'Kesehatan': '💊',
    'Belanja': '🛍️',
    'Uang Saku': '💵',
    'Beasiswa': '🏆',
    'Part Time': '💼',
    'Freelance': '💻',
    'Bonus': '🎁',
    'Lainnya': '📌',
  };

  // Account Types
  static const List<String> accountTypes = [
    'Tunai',
    'E-Wallet',
    'Bank',
  ];

  // Notification IDs
  static const int notifBudgetWarning = 1001;
  static const int notifDebtReminder = 1002;
  static const int notifSavingsProgress = 1003;

  // File
  static const String reportPrefix = 'FinTrack_Report_';
  static const String reportExtPdf = '.pdf';
  static const String reportExtCsv = '.csv';

  // Budget Warning Threshold
  static const double budgetWarningThreshold = 0.2; // 20% remaining

  // Savings Milestones
  static const List<double> savingsMilestones = [0.25, 0.50, 0.75, 1.0];

  // Currency
  static const String currencySymbol = 'Rp';
  static const String currencyCode = 'IDR';
}
