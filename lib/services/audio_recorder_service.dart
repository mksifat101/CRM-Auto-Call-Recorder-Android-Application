import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 's3_service.dart';
import 'api_service.dart';

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
  static const platform = MethodChannel('call_recorder/call_detection');

  final S3Service _s3service = S3Service();
  final ApiService _apiService = ApiService();

  List<RecordingItem> _recordings = [];
  bool _isUploading = false;
  bool _isRecording = false;
  String _formattedDuration = "00:00";

  List<RecordingItem> get recordings => _recordings;
  bool get isUploading => _isUploading;
  bool get isRecording => _isRecording;
  String get formattedDuration => _formattedDuration;

  AudioRecorderService() {
    _initNativeListener();
  }

  void _initNativeListener() {
    platform.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "onRecordingStarted":
          _isRecording = true;
          _formattedDuration = "00:00";
          notifyListeners();
          print("Recording Started");
          break;

        case "onRecordingFinished":
          _isRecording = false;
          notifyListeners();
          String? filePath = call.arguments;
          if (filePath != null) {
            print("Call End & File Path: $filePath");
            await _autoUploadToCloud(filePath);
          }
          break;

        case "updateTimer":
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
      print("❌ এরর: ফাইলটি খুঁজে পাওয়া যায়নি! Error: File Not Found");
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      print("Start Upload in S3");

      final s3Result = await _s3service.uploadFileToS3(file);

      if (s3Result != null) {
        String s3Url = s3Result['document_url']!;
        print("Upload Done: $s3Url");

        final apiResponse = await _apiService.sendRecordingData(
          phoneNumber: "Recorded Call",
          s3Url: s3Url,
          duration: 0,
          fileName: s3Result['name']!,
          timestamp: DateTime.now().toIso8601String(),
        );

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

        print("Store in Database");
      }
    } catch (e) {
      print("Upload Error: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// SharedPreferences
  Future<void> loadRecordings() async {
    //
    notifyListeners();
  }

  ///
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
