import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 's3_service.dart';
import 'api_service.dart';

/// হোম স্ক্রিনে রেকর্ডিং লিস্ট দেখানোর জন্য মডেল ক্লাস
class RecordingItem {
  final String phoneNumber;
  final DateTime timestamp;
  final Duration duration;
  final bool isUploaded;
  final String? s3Url;
  final String fileSize;

  RecordingItem({
    required this.phoneNumber,
    required this.timestamp,
    required this.duration,
    this.isUploaded = false,
    this.s3Url,
    this.fileSize = '0 KB',
  });
}

class AudioRecorderService extends ChangeNotifier {
  // অ্যান্ড্রয়েড নেটিভের সাথে কথা বলার জন্য চ্যানেল
  static const platform = MethodChannel('call_recorder/call_detection');

  final S3Service _s3service = S3Service();
  final ApiService _apiService = ApiService();

  // প্রাইভেট ভেরিয়েবল
  List<RecordingItem> _recordings = [];
  bool _isUploading = false;
  bool _isRecording = false;
  String _formattedDuration = "00:00";

  // গেটার্স (UI থেকে ডাটা এক্সেস করার জন্য)
  List<RecordingItem> get recordings => _recordings;
  bool get isUploading => _isUploading;
  bool get isRecording => _isRecording;
  String get formattedDuration => _formattedDuration;

  AudioRecorderService() {
    _initNativeListener();
  }

  /// নেটিভ অ্যান্ড্রয়েড (Kotlin) থেকে আসা কলব্যাকগুলো হ্যান্ডেল করা
  void _initNativeListener() {
    platform.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "onRecordingStarted":
          _isRecording = true;
          _formattedDuration = "00:00";
          notifyListeners();
          print("🎙️ রেকর্ডিং শুরু হয়েছে (নেটিভ থেকে জানানো হয়েছে)");
          break;

        case "onRecordingFinished":
          _isRecording = false;
          notifyListeners();
          String? filePath = call.arguments;
          if (filePath != null) {
            print("📦 কল শেষ! ফাইল পাথ: $filePath");
            await _autoUploadToCloud(filePath);
          }
          break;

        case "updateTimer":
          // যদি নেটিভ থেকে প্রতি সেকেন্ডে টাইম পাঠাতে চান (ঐচ্ছিক)
          _formattedDuration = call.arguments;
          notifyListeners();
          break;
      }
    });
  }

  /// কল শেষ হওয়ার পর অটোমেটিক S3 এবং API-তে ডাটা পাঠানো
  Future<void> _autoUploadToCloud(String filePath) async {
    File file = File(filePath);
    if (!await file.exists()) {
      print("❌ এরর: ফাইলটি খুঁজে পাওয়া যায়নি!");
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      print("📤 S3-তে ফাইল আপলোড প্রসেস শুরু হচ্ছে...");

      // ১. AWS S3 তে ফাইল আপলোড (আপনার দেওয়া S3Service ব্যবহার করে)
      final s3Result = await _s3service.uploadFileToS3(file);

      if (s3Result != null) {
        String s3Url = s3Result['document_url']!;
        print("✅ S3 আপলোড সফল: $s3Url");

        // ২. আপনার ব্যাকএন্ড API-তে ডাটা পাঠানো
        final apiResponse = await _apiService.sendRecordingData(
          phoneNumber:
              "Recorded Call", // নেটিভ থেকে ফোন নাম্বার পাঠালে এখানে সেটি বসবে
          s3Url: s3Url,
          duration: 0, // নেটিভ থেকে সেকেন্ড পাঠালে এখানে যোগ করতে পারেন
          fileName: s3Result['name']!,
          timestamp: DateTime.now().toIso8601String(),
        );

        // ৩. লোকাল লিস্ট আপডেট করা (যাতে হোম স্ক্রিনে সাথে সাথে দেখা যায়)
        _recordings.insert(
          0,
          RecordingItem(
            phoneNumber: "Incoming Call",
            timestamp: DateTime.now(),
            duration: Duration.zero,
            isUploaded: true,
            s3Url: s3Url,
            fileSize: "${(await file.length() / 1024).toStringAsFixed(2)} KB",
          ),
        );

        print("🎉 ডাটাবেসে সফলভাবে সেভ হয়েছে।");
      }
    } catch (e) {
      print("💥 আপলোড এরর: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// SharedPreferences বা ডাটাবেস থেকে পুরনো রেকর্ডিং লোড করা (যদি থাকে)
  Future<void> loadRecordings() async {
    // এখানে আপনার ডাটা লোড করার লজিক লিখতে পারেন
    notifyListeners();
  }

  /// ম্যানুয়ালি রেকর্ডিং বন্ধ করার কমান্ড (ফ্লার্টার থেকে)
  Future<void> stopServiceManually() async {
    try {
      await platform.invokeMethod('stopRecordingService');
      _isRecording = false;
      notifyListeners();
    } catch (e) {
      print("Error stopping service: $e");
    }
  }
}
