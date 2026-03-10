import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class CourseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Course> _courses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  List<Course> get courses => _filteredCourses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = {'الكل'};
    for (final c in _courses) cats.add(c.category);
    return cats.toList();
  }

  List<Course> get _filteredCourses {
    return _courses.where((c) {
      final matchSearch = _searchQuery.isEmpty ||
          c.title.contains(_searchQuery) ||
          c.instructor.contains(_searchQuery);
      final matchCat = _selectedCategory == 'الكل' || c.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  Future<void> loadCourses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _courses = await _db.getCourses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Course?> getCourse(String id) => _db.getCourse(id);

  Future<void> addCourse({
    required String title,
    required String description,
    required String instructor,
    required String category,
    String? thumbnailPath,
  }) async {
    final course = Course(
      id: const Uuid().v4(),
      title: title,
      description: description,
      instructor: instructor,
      category: category,
      thumbnailPath: thumbnailPath,
      createdAt: DateTime.now(),
    );
    await _db.insertCourse(course);
    await loadCourses();
  }

  Future<void> updateCourse(Course course) async {
    await _db.updateCourse(course);
    await loadCourses();
  }

  Future<void> deleteCourse(String id) async {
    await _db.deleteCourse(id);
    await loadCourses();
  }

  Future<void> addLesson({
    required String courseId,
    required String title,
    required String description,
    required LessonType type,
    String? filePath,
    String? fileUrl,
    String? fileName,
    int durationMinutes = 0,
    required int orderIndex,
  }) async {
    final lesson = Lesson(
      id: const Uuid().v4(),
      courseId: courseId,
      title: title,
      description: description,
      type: type,
      filePath: filePath,
      fileUrl: fileUrl,
      fileName: fileName,
      durationMinutes: durationMinutes,
      orderIndex: orderIndex,
    );
    await _db.insertLesson(lesson);
    await loadCourses();
  }

  Future<void> deleteLesson(String id) async {
    await _db.deleteLesson(id);
    await loadCourses();
  }

  Future<void> toggleLessonCompleted(Lesson lesson) async {
    await _db.markLessonCompleted(lesson.id, !lesson.isCompleted);
    await loadCourses();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }
}
