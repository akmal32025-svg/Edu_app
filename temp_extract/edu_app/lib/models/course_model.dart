class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final String category;
  final String? thumbnailPath;
  final DateTime createdAt;
  final List<Lesson> lessons;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.category,
    this.thumbnailPath,
    required this.createdAt,
    this.lessons = const [],
  });

  int get totalLessons => lessons.length;

  int get totalDurationMinutes =>
      lessons.fold(0, (sum, l) => sum + l.durationMinutes);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'instructor': instructor,
        'category': category,
        'thumbnailPath': thumbnailPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Course.fromMap(Map<String, dynamic> map, {List<Lesson> lessons = const []}) =>
      Course(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        instructor: map['instructor'],
        category: map['category'],
        thumbnailPath: map['thumbnailPath'],
        createdAt: DateTime.parse(map['createdAt']),
        lessons: lessons,
      );
}

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final LessonType type;
  final String? filePath;
  final String? fileUrl;
  final String? fileName;
  final int durationMinutes;
  final int orderIndex;
  bool isCompleted;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    this.filePath,
    this.fileUrl,
    this.fileName,
    this.durationMinutes = 0,
    required this.orderIndex,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'description': description,
        'type': type.name,
        'filePath': filePath,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'durationMinutes': durationMinutes,
        'orderIndex': orderIndex,
        'isCompleted': isCompleted ? 1 : 0,
      };

  factory Lesson.fromMap(Map<String, dynamic> map) => Lesson(
        id: map['id'],
        courseId: map['courseId'],
        title: map['title'],
        description: map['description'],
        type: LessonType.values.firstWhere((e) => e.name == map['type']),
        filePath: map['filePath'],
        fileUrl: map['fileUrl'],
        fileName: map['fileName'],
        durationMinutes: map['durationMinutes'] ?? 0,
        orderIndex: map['orderIndex'] ?? 0,
        isCompleted: map['isCompleted'] == 1,
      );
}

enum LessonType { video, pdf, document, audio, image, link }

extension LessonTypeExt on LessonType {
  String get label {
    switch (this) {
      case LessonType.video: return 'فيديو';
      case LessonType.pdf: return 'PDF';
      case LessonType.document: return 'مستند';
      case LessonType.audio: return 'صوت';
      case LessonType.image: return 'صورة';
      case LessonType.link: return 'رابط';
    }
  }

  String get icon {
    switch (this) {
      case LessonType.video: return '🎬';
      case LessonType.pdf: return '📄';
      case LessonType.document: return '📝';
      case LessonType.audio: return '🎵';
      case LessonType.image: return '🖼️';
      case LessonType.link: return '🔗';
    }
  }
}
