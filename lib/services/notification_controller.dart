// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:provider/provider.dart';
// import '../main.dart';
// import 'audio_recorder_service.dart';

// class NotificationController {
//   @pragma("vm:entry-point")
//   static Future<void> onActionReceivedMethod(
//     ReceivedAction receivedAction,
//   ) async {
//     if (receivedAction.buttonKeyPressed == 'RECORD_START') {
//       final context = MyApp.navigatorKey.currentContext;
//       if (context != null) {
//         // ইউজার ক্লিক করার সাথে সাথে রেকর্ডিং ইঞ্জিন স্টার্ট হবে
//         Provider.of<AudioRecorderService>(
//           context,
//           listen: false,
//         ).startRecordingEngine();
//       }
//     }
//   }
// }
