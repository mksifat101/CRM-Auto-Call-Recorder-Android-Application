import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const platform = MethodChannel('call_recorder/call_detection');

  //
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, //
      [
        NotificationChannel(
          channelKey: 'call_channel',
          channelName: 'Call Notifications',
          channelDescription: 'Notification channel for call recording',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          onlyAlertOnce: true,
          criticalAlerts: true,
        ),
      ],
      debug: false,
    );

    //
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  //
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (receivedAction.buttonKeyPressed == 'record') {
      final String phoneNumber =
          receivedAction.payload?['phone_number'] ?? "Unknown";

      try {
        //
        await platform.invokeMethod('startRecordingService', {
          "phone_number": phoneNumber,
        });
        print("Native Recording Started");
      } on PlatformException catch (e) {
        print("Service Error: ${e.message}");
      }
    }
  }

  //
  Future<void> showCallNotification(String phoneNumber) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'call_channel',
        title: 'Call from: $phoneNumber',
        body: 'Tap "Record Now" for call record',
        payload: {'phone_number': phoneNumber},
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Call,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'record',
          label: 'Record Now',
          color: Colors.blue,
          autoDismissible: true,
        ),
      ],
    );
  }
}
