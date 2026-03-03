class Lesson {
  final String id;
  final String subject;
  final String teacher;
  final String room;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int dayOfWeek; // 1=Monday, 7=Sunday (DateTime.weekday convention)

  const Lesson({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.dayOfWeek,
  });

  String get startTimeStr =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endTimeStr =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'teacher': teacher,
        'room': room,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'dayOfWeek': dayOfWeek,
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        subject: json['subject'] as String,
        teacher: json['teacher'] as String? ?? '',
        room: json['room'] as String? ?? '',
        startHour: json['startHour'] as int,
        startMinute: json['startMinute'] as int,
        endHour: json['endHour'] as int,
        endMinute: json['endMinute'] as int,
        dayOfWeek: json['dayOfWeek'] as int,
      );

  Lesson copyWith({
    String? id,
    String? subject,
    String? teacher,
    String? room,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    int? dayOfWeek,
  }) =>
      Lesson(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        teacher: teacher ?? this.teacher,
        room: room ?? this.room,
        startHour: startHour ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour: endHour ?? this.endHour,
        endMinute: endMinute ?? this.endMinute,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      );
}
