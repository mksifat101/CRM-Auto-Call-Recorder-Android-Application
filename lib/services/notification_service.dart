import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const platform = MethodChannel('call_recorder/call_detection');

  // নোটিফিকেশন সিস্টেম ইনিশিয়ালাইজ করা
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // লোগো আইকন (null থাকলে ডিফল্ট আইকন আসবে)
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

    // অ্যাকশন লিসেনার সেট করা (অবশ্যই স্ট্যাটিক মেথড হতে হবে)
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  // নোটিফিকেশন বাটনে ক্লিক করলে এই মেথডটি ব্যাকগ্রাউন্ডে কাজ করবে
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (receivedAction.buttonKeyPressed == 'record') {
      final String phoneNumber =
          receivedAction.payload?['phone_number'] ?? "Unknown";

      try {
        // নেটিভ অ্যান্ড্রয়েড সার্ভিসকে কল করা
        await platform.invokeMethod('startRecordingService', {
          "phone_number": phoneNumber,
        });
        print("✅ নেটিভ রেকর্ডিং সার্ভিস স্টার্ট হয়েছে");
      } on PlatformException catch (e) {
        print("❌ সার্ভিস স্টার্ট করতে সমস্যা: ${e.message}");
      }
    }
  }

  // ইনকামিং কলের নোটিফিকেশন দেখানো
  Future<void> showCallNotification(String phoneNumber) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'call_channel',
        title: 'Call from: $phoneNumber',
        body: 'ট্যাপ করুন "Record Now" কলটি রেকর্ড করার জন্য',
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
