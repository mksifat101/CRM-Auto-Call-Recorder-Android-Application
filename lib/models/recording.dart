class Recording {
  final String id;
  final String contactNumber;
  final DateTime dateTime;
  final String audioUrl;
  final String? aiSummary;
  final Duration duration;

  Recording({
    required this.id,
    required this.contactNumber,
    required this.dateTime,
    required this.audioUrl,
    this.aiSummary,
    required this.duration,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'],
      contactNumber: json['contact_number'],
      dateTime: DateTime.parse(json['date_time']),
      audioUrl: json['audio_url'],
      aiSummary: json['ai_summary'],
      duration: Duration(seconds: json['duration_seconds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_number': contactNumber,
      'date_time': dateTime.toIso8601String(),
      'audio_url': audioUrl,
      'ai_summary': aiSummary,
      'duration_seconds': duration.inSeconds,
    };
  }
}
