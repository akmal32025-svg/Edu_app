import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'edu_app.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        instructor TEXT,
        category TEXT,
        thumbnailPath TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE lessons(
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT,
        filePath TEXT,
        fileUrl TEXT,
        fileName TEXT,
        durationMinutes INTEGER DEFAULT 0,
        orderIndex INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final courseId1 = 'course_sample_1';
    final courseId2 = 'course_sample_2';

    await db.insert('courses', {
      'id': courseId1,
      'title': 'أساسيات البرمجة بلغة Python',
      'description': 'تعلم البرمجة من الصفر مع لغة Python الشهيرة',
      'instructor': 'أ. محمد أحمد',
      'category': 'برمجة',
      'thumbnailPath': null,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await db.insert('courses', {
      'id': courseId2,
      'title': 'تصميم الجرافيك للمبتدئين',
      'description': 'أسس التصميم الجرافيكي واستخدام الأدوات الاحترافية',
      'instructor': 'أ. سارة علي',
      'category': 'تصميم',
      'thumbnailPath': null,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final lessons1 = [
      {'id': 'l1', 'courseId': courseId1, 'title': 'مقدمة في Python', 'description': 'التعرف على لغة Python وبيئة العمل', 'type': 'video', 'orderIndex': 0},
      {'id': 'l2', 'courseId': courseId1, 'title': 'المتغيرات وأنواع البيانات', 'description': 'شرح المتغيرات والأنواع المختلفة', 'type': 'video', 'orderIndex': 1},
      {'id': 'l3', 'courseId': courseId1, 'title': 'ملف الكود المصدري', 'description': 'تحميل ملفات الكود', 'type': 'document', 'orderIndex': 2},
    ];

    for (final l in lessons1) {
      await db.insert('lessons', {
        ...l,
        'filePath': null,
        'fileUrl': null,
        'fileName': null,
        'durationMinutes': 15,
        'isCompleted': 0,
      });
    }
  }

  // Courses CRUD
  Future<List<Course>> getCourses() async {
    final db = await database;
    final courses = await db.query('courses', orderBy: 'createdAt DESC');
    final List<Course> result = [];
    for (final c in courses) {
      final lessons = await getLessons(c['id'] as String);
      result.add(Course.fromMap(c, lessons: lessons));
    }
    return result;
  }

  Future<Course?> getCourse(String id) async {
    final db = await database;
    final rows = await db.query('courses', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final lessons = await getLessons(id);
    return Course.fromMap(rows.first, lessons: lessons);
  }

  Future<void> insertCourse(Course course) async {
    final db = await database;
    await db.insert('courses', course.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCourse(Course course) async {
    final db = await database;
    await db.update('courses', course.toMap(), where: 'id = ?', whereArgs: [course.id]);
  }

  Future<void> deleteCourse(String id) async {
    final db = await database;
    await db.delete('courses', where: 'id = ?', whereArgs: [id]);
    await db.delete('lessons', where: 'courseId = ?', whereArgs: [id]);
  }

  // Lessons CRUD
  Future<List<Lesson>> getLessons(String courseId) async {
    final db = await database;
    final rows = await db.query('lessons',
        where: 'courseId = ?', whereArgs: [courseId], orderBy: 'orderIndex ASC');
    return rows.map((r) => Lesson.fromMap(r)).toList();
  }

  Future<void> insertLesson(Lesson lesson) async {
    final db = await database;
    await db.insert('lessons', lesson.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLesson(Lesson lesson) async {
    final db = await database;
    await db.update('lessons', lesson.toMap(), where: 'id = ?', whereArgs: [lesson.id]);
  }

  Future<void> deleteLesson(String id) async {
    final db = await database;
    await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markLessonCompleted(String lessonId, bool completed) async {
    final db = await database;
    await db.update('lessons', {'isCompleted': completed ? 1 : 0},
        where: 'id = ?', whereArgs: [lessonId]);
  }
}
