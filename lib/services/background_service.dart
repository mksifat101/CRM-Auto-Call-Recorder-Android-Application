import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:call_log/call_log.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'callDetectionTask') {
        print('🔄 Background task running');
        await _checkRecentCalls();
        return Future.value(true);
      }
    } catch (e) {
      print('❌ Background task error: $e');
    }
    return Future.value(false);
  });
}

Future<void> _checkRecentCalls() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (!isLoggedIn) return;

  try {
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

    final Iterable<CallLogEntry> entries = await CallLog.query(
      dateFrom: fiveMinutesAgo.millisecondsSinceEpoch,
    );

    for (final call in entries) {
      if (call.duration != null && call.duration! > 0) {
        final phoneNumber = call.number ?? 'Unknown';

        // Show notification for user to record
        await NotificationService().showCallNotification(phoneNumber);
        break; // Only show for the most recent call
      }
    }
  } catch (e) {
    print('❌ Error in background call check: $e');
  }
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Register periodic task (every 15 minutes)
    await Workmanager().registerPeriodicTask(
      '1',
      'callDetectionTask',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> stopBackgroundTask() async {
    await Workmanager().cancelByUniqueName('1');
  }
}
