import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request permission Android 13+
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {}

    _initialized = true;
  }

  Future<void> showBudgetWarning({
    required String budgetName,
    required double percentage,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      AppConstants.notifBudgetWarning,
      '⚠️ Budget Hampir Habis',
      'Budget $budgetName tersisa ${(percentage * 100).toStringAsFixed(0)}%',
      _buildDetails(channelId: 'budget_warning', channelName: 'Budget Warning'),
    );
  }

  Future<void> showDailyBudgetWarning(String message) async {
    if (!_initialized) return;
    await _plugin.show(
      AppConstants.notifBudgetWarning + 1,
      '⚠️ Batas Pengeluaran Harian',
      message,
      _buildDetails(channelId: 'budget_warning', channelName: 'Budget Warning'),
    );
  }

  Future<void> showDebtReminder({
    required String personName,
    required String amount,
    required String type,
  }) async {
    if (!_initialized) return;
    final title =
        type == 'owed' ? '💸 Jatuh Tempo Hutang' : '📬 Tagih Piutang';
    final body = type == 'owed'
        ? 'Hutang ke $personName sebesar $amount jatuh tempo besok!'
        : 'Piutang dari $personName sebesar $amount jatuh tempo besok!';

    await _plugin.show(
      AppConstants.notifDebtReminder,
      title,
      body,
      _buildDetails(channelId: 'debt_reminder', channelName: 'Debt Reminder'),
    );
  }

  Future<void> scheduleDebtReminder({
    required int id,
    required String personName,
    required String amount,
    required String type,
    required DateTime dueDate,
  }) async {
    if (!_initialized) return;
    final reminderDate = dueDate.subtract(const Duration(days: 1));
    if (reminderDate.isBefore(DateTime.now())) return;

    final title =
        type == 'owed' ? '💸 Jatuh Tempo Hutang' : '📬 Tagih Piutang';
    final body = type == 'owed'
        ? 'Hutang ke $personName sebesar $amount jatuh tempo besok!'
        : 'Piutang dari $personName sebesar $amount jatuh tempo besok!';

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(reminderDate, tz.local),
      _buildDetails(channelId: 'debt_reminder', channelName: 'Debt Reminder'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showSavingsMilestone({
    required String goalName,
    required int milestone,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      AppConstants.notifSavingsProgress + milestone,
      '🎉 Milestone Tabungan!',
      'Keren! Tabungan "$goalName" sudah mencapai $milestone%!',
      _buildDetails(
          channelId: 'savings_milestone',
          channelName: 'Savings Milestone'),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFFF4D94),
        styleInformation: const DefaultStyleInformation(true, true),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
