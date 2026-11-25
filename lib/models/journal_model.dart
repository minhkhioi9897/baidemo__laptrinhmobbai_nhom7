class JournalModel {
  final String id;
  final String content;
  final String emoji;
  final String moodText;
  final DateTime createdAt;

  JournalModel({
    required this.id,
    required this.content,
    this.emoji = '🙂',
    this.moodText = 'Ổn, bình thường',
    required this.createdAt,
  });

  String get formattedDate {
    return '${createdAt.day} tháng ${createdAt.month}';
  }

  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'emoji': emoji,
        'moodText': moodText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JournalModel.fromJson(Map<String, dynamic> json) => JournalModel(
        id: json['id'] ?? '',
        content: json['content'] ?? '',
        emoji: json['emoji'] ?? '🙂',
        moodText: json['moodText'] ?? 'Ổn, bình thường',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}
