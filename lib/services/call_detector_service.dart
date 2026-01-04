import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

enum CallState { idle, ringing, offhook }

class CallDetectionService extends ChangeNotifier {
  CallState _currentState = CallState.idle;
  String? _phoneNumber;
  bool _isRunning = false;
  Timer? _callCheckTimer;
  CallLogEntry? _lastCall;
  DateTime? _lastCallTime;

  CallState get currentState => _currentState;
  String? get phoneNumber => _phoneNumber;
  bool get isRunning => _isRunning;

  Future<void> startDetection() async {
    if (_isRunning) return;

    // Request permissions
    if (!await Permission.phone.isGranted) {
      final status = await Permission.phone.request();
      if (!status.isGranted) {
        print('❌ Phone permission denied');
        return;
      }
    }

    // Request call log permission
    if (!await Permission.contacts.isGranted) {
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        print('⚠️ Contacts permission not granted');
      }
    }

    _isRunning = true;
    notifyListeners();

    print('📞 Call detection started');

    // Start checking for calls every 5 seconds
    _callCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForCalls();
    });
  }

  Future<void> _checkForCalls() async {
    try {
      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (!isLoggedIn) return;

      // Get call logs
      final Iterable<CallLogEntry> entries = await CallLog.query();

      if (entries.isNotEmpty) {
        // Sort by timestamp (newest first)
        final sortedEntries = entries.toList()
          ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

        final CallLogEntry latestCall = sortedEntries.first;

        // Check if this is a new call (within last 30 seconds)
        final callTime = DateTime.fromMillisecondsSinceEpoch(
          latestCall.timestamp ?? 0,
        );
        final now = DateTime.now();
        final timeDifference = now.difference(callTime);

        if (timeDifference.inSeconds < 30 &&
            (_lastCall == null ||
                _lastCall!.timestamp != latestCall.timestamp)) {
          _lastCall = latestCall;
          _lastCallTime = callTime;
          _phoneNumber = latestCall.number ?? 'Unknown';

          // Update call state based on call type
          _updateCallState(latestCall);
          notifyListeners();

          // Show notification for user to record (only for active calls)
          _handleCallNotification(latestCall);
        }
      }
    } catch (e) {
      print('❌ Error checking calls: $e');
    }
  }

  void _updateCallState(CallLogEntry call) {
    final phone = call.number ?? 'Unknown';

    // Check CallType based on your package version
    if (call.callType == CallType.incoming) {
      _currentState = CallState.ringing;
      print('📞 Incoming call from: $phone');
    } else if (call.callType == CallType.outgoing) {
      _currentState = CallState.offhook;
      print('📞 Outgoing call to: $phone');
    } else if (call.callType == CallType.missed) {
      _currentState = CallState.idle;
      print('📞 Missed call from: $phone');
    } else {
      // Handle other call types
      _currentState = CallState.idle;
      print('📞 Call from: $phone (type: ${call.callType})');
    }
  }

  Future<void> _handleCallNotification(CallLogEntry call) async {
    final phone = call.number ?? 'Unknown';

    // Check if it's an active call with duration
    final isActiveCall =
        (call.callType == CallType.incoming ||
        call.callType == CallType.outgoing);

    final hasDuration = call.duration != null && call.duration! > 0;

    if (isActiveCall && hasDuration && _phoneNumber != null) {
      print('🔔 Showing notification for call: $phone');
      await NotificationService().showCallNotification(phone);
    }
  }

  // Alternative: Check specific time range
  Future<void> _checkRecentCalls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (!isLoggedIn) return;

      // Get current time and time 30 seconds ago
      final now = DateTime.now();
      final thirtySecondsAgo = now.subtract(const Duration(seconds: 30));

      // Query call log with date range
      final queryResult = await CallLog.query(
        dateFrom: thirtySecondsAgo.millisecondsSinceEpoch,
        dateTo: now.millisecondsSinceEpoch,
      );

      if (queryResult.isNotEmpty) {
        // Get the latest call
        final latestCall = queryResult.first;

        // Check if it's a new call
        if (_lastCall == null || _lastCall!.timestamp != latestCall.timestamp) {
          _lastCall = latestCall;
          _lastCallTime = DateTime.fromMillisecondsSinceEpoch(
            latestCall.timestamp ?? 0,
          );
          _phoneNumber = latestCall.number ?? 'Unknown';

          // Process the call
          _updateCallState(latestCall);
          await _handleCallNotification(latestCall);

          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error checking recent calls: $e');
    }
  }

  void _resetState() {
    _currentState = CallState.idle;
    _phoneNumber = null;
    notifyListeners();
  }

  void stopDetection() {
    _callCheckTimer?.cancel();
    _callCheckTimer = null;
    _isRunning = false;
    _resetState();
    notifyListeners();
    print('📞 Call detection stopped');
  }

  @override
  void dispose() {
    stopDetection();
    super.dispose();
  }
}
