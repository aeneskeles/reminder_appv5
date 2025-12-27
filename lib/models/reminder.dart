class Reminder {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isRecurring;
  final String category;
  final bool isCompleted;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly', null for one-time

  Reminder({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.isRecurring = false,
    this.category = 'Genel',
    this.isCompleted = false,
    this.recurrencePattern,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
      'recurrencePattern': recurrencePattern,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      isRecurring: (map['isRecurring'] as int) == 1,
      category: map['category'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      recurrencePattern: map['recurrencePattern'] as String?,
    );
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isRecurring,
    String? category,
    bool? isCompleted,
    String? recurrencePattern,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isRecurring: isRecurring ?? this.isRecurring,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
    );
  }
}

