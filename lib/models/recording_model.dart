class RecordingModel {
  final String id;
  final String title;
  final String filePath;
  final String contentText;
  final int durationSeconds;
  final DateTime createdAt;

  RecordingModel({
    required this.id,
    required this.title,
    this.filePath = '',
    required this.contentText,
    required this.durationSeconds,
    required this.createdAt,
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes phút $seconds giây';
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (recDate == today) {
      return 'Hôm nay';
    } else if (recDate == yesterday) {
      return 'Hôm qua';
    } else {
      final weekdayNames = [
        'Thứ 2',
        'Thứ 3',
        'Thứ 4',
        'Thứ 5',
        'Thứ 6',
        'Thứ 7',
        'Chủ nhật'
      ];
      return weekdayNames[createdAt.weekday - 1];
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'contentText': contentText,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecordingModel.fromJson(Map<String, dynamic> json) => RecordingModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        filePath: json['filePath'] ?? '',
        contentText: json['contentText'] ?? json['title'] ?? '',
        durationSeconds: json['durationSeconds'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}
