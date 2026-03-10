import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../services/course_provider.dart';
import '../utils/app_theme.dart';
import 'add_lesson_screen.dart';
import 'lesson_viewer_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    final course = await context.read<CourseProvider>().getCourse(widget.courseId);
    if (mounted) setState(() => _course = course);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final courses = provider.courses;
        final course = courses.firstWhere(
          (c) => c.id == widget.courseId,
          orElse: () => _course ?? Course(
            id: '', title: '', description: '', instructor: '', category: '',
            createdAt: DateTime.now(),
          ),
        );
        if (course.id.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final color = AppTheme.categoryColor(course.category);
        final completed = course.lessons.where((l) => l.isCompleted).length;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(course, color),
              SliverToBoxAdapter(child: _buildInfo(course, completed, color)),
              SliverToBoxAdapter(child: _buildLessonsHeader(course)),
              _buildLessonsList(course, provider),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddLessonScreen(courseId: course.id, orderIndex: course.totalLessons),
              ));
            },
            backgroundColor: color,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('إضافة درس'),
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(Course course, Color color) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: color,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(course.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Icon(Icons.menu_book, size: 80, color: Colors.white.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(Course course, int completed, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(course.category, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(course.instructor, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(course.description,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                textDirection: TextDirection.rtl),
          ],
          if (course.totalLessons > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$completed/${course.totalLessons} دروس مكتملة',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Text('${(completed / course.totalLessons * 100).toInt()}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completed / course.totalLessons,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonsHeader(Course course) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الدروس (${course.totalLessons})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLessonsList(Course course, CourseProvider provider) {
    if (course.lessons.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 56, color: AppTheme.textSecondary),
              SizedBox(height: 8),
              Text('لا توجد دروس بعد', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _lessonTile(course.lessons[i], provider, AppTheme.categoryColor(course.category)),
          childCount: course.lessons.length,
        ),
      ),
    );
  }

  Widget _lessonTile(Lesson lesson, CourseProvider provider, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: lesson.isCompleted ? AppTheme.success.withOpacity(0.1) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(lesson.type.icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: lesson.isCompleted ? TextDecoration.lineThrough : null,
            color: lesson.isCompleted ? Colors.grey : AppTheme.textPrimary,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(lesson.type.label, style: TextStyle(fontSize: 11, color: color)),
            ),
            if (lesson.durationMinutes > 0) ...[
              const SizedBox(width: 6),
              Text('${lesson.durationMinutes} دقيقة', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                lesson.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: lesson.isCompleted ? AppTheme.success : Colors.grey,
              ),
              onPressed: () => provider.toggleLessonCompleted(lesson),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
              onPressed: () => _deleteLesson(provider, lesson.id),
            ),
          ],
        ),
        onTap: () {
          if (lesson.filePath != null || lesson.fileUrl != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => LessonViewerScreen(lesson: lesson),
            ));
          }
        },
      ),
    );
  }

  void _deleteLesson(CourseProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الدرس', textDirection: TextDirection.rtl),
        content: const Text('هل تريد حذف هذا الدرس؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { provider.deleteLesson(id); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
