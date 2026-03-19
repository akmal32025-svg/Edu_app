import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../utils/app_theme.dart';

class StatsWidget extends StatelessWidget {
  final List<Course> courses;

  const StatsWidget({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    final totalLessons = courses.fold(0, (s, c) => s + c.totalLessons);
    final completedLessons = courses.fold(
        0, (s, c) => s + c.lessons.where((l) => l.isCompleted).length);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _statItem(courses.length.toString(), 'كورس', Icons.menu_book),
          _divider(),
          _statItem(totalLessons.toString(), 'درس', Icons.play_circle_outline),
          _divider(),
          _statItem(completedLessons.toString(), 'مكتمل', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: Colors.white.withOpacity(0.3),
      );
}
