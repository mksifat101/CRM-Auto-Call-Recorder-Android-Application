class Recording {
  String id;
  String fileName;
  String filePath;
  String? phoneNumber;
  DateTime createdAt;
  Duration duration;
  String? s3Url;
  String? aiSummary;
  bool isUploaded;
  bool isProcessing;

  Recording({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.phoneNumber,
    required this.createdAt,
    required this.duration,
    this.s3Url,
    this.aiSummary,
    this.isUploaded = false,
    this.isProcessing = false,
  });

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}';
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
