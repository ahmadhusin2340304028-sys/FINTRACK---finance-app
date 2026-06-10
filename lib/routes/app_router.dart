import 'package:flutter/material.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/transaction/pages/transaction_page.dart';
import '../features/transaction/pages/add_transaction_page.dart';
import '../features/transaction/pages/transaction_detail_page.dart';
import '../features/budget/pages/budget_page.dart';
import '../features/budget/pages/add_budget_page.dart';
import '../features/debt/pages/debt_page.dart';
import '../features/debt/pages/add_debt_page.dart';
import '../features/savings/pages/savings_page.dart';
import '../features/savings/pages/add_savings_page.dart';
import '../features/savings/pages/savings_detail_page.dart';
import '../features/reports/pages/reports_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/settings/pages/profile_page.dart';
import '../data/models/transaction_model.dart';
import '../data/models/debt_model.dart';
import '../data/models/savings_model.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String transactionDetail = '/transactions/detail';
  static const String budget = '/budget';
  static const String addBudget = '/budget/add';
  static const String debt = '/debt';
  static const String addDebt = '/debt/add';
  static const String savings = '/savings';
  static const String addSavings = '/savings/add';
  static const String savingsDetail = '/savings/detail';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _fade(const LoginPage());
      case register:
        return _fade(const RegisterPage());
      case dashboard:
        return _fade(const DashboardPage());
      case transactions:
        return _slide(const TransactionPage());
      case addTransaction:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slide(AddTransactionPage(initialType: args?['type']));
      case transactionDetail:
        final tx = settings.arguments as TransactionModel;
        return _slide(TransactionDetailPage(transaction: tx));
      case budget:
        return _slide(const BudgetPage());
      case addBudget:
        return _slide(const AddBudgetPage());
      case debt:
        return _slide(const DebtPage());
      case addDebt:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slide(AddDebtPage(initialType: args?['type']));
      case savings:
        return _slide(const SavingsPage());
      case addSavings:
        return _slide(const AddSavingsPage());
      case savingsDetail:
        final s = settings.arguments as SavingsModel;
        return _slide(SavingsDetailPage(savings: s));
      case reports:
        return _slide(const ReportsPage());
      case AppRouter.settings:
        return _slide(const SettingsPage());
      case profile:
        return _slide(const ProfilePage());
      default:
        return _fade(const LoginPage());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: anim.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
