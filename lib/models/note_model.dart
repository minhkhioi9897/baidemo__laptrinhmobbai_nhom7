class NoteModel {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);

    final hour = updatedAt.hour.toString().padLeft(2, '0');
    final minute = updatedAt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (noteDate == today) {
      return 'Hôm nay, $timeStr';
    } else if (noteDate == yesterday) {
      return 'Hôm qua, $timeStr';
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
      final dayName = weekdayNames[updatedAt.weekday - 1];
      return '$dayName, $timeStr';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
