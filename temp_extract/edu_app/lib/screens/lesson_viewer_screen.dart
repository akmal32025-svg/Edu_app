import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_model.dart';
import '../utils/app_theme.dart';

class LessonViewerScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonViewerScreen({super.key, required this.lesson});

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.type == LessonType.video) _initVideo();
  }

  Future<void> _initVideo() async {
    final path = widget.lesson.filePath;
    final url = widget.lesson.fileUrl;

    if (path != null) {
      _videoController = VideoPlayerController.file(File(path));
    } else if (url != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    if (_videoController != null) {
      await _videoController!.initialize();
      if (mounted) setState(() => _videoInitialized = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.lesson.title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (widget.lesson.type) {
      case LessonType.video:
        return _buildVideoPlayer();
      case LessonType.image:
        return _buildImageViewer();
      case LessonType.link:
        return _buildLinkViewer();
      default:
        return _buildFileViewer();
    }
  }

  Widget _buildVideoPlayer() {
    if (!_videoInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('جاري تحميل الفيديو...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        const SizedBox(height: 20),
        VideoProgressIndicator(_videoController!, allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: AppTheme.primary)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
              onPressed: () {
                final pos = _videoController!.value.position;
                _videoController!.seekTo(pos - const Duration(seconds: 10));
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white, size: 56),
              onPressed: () {
                setState(() => _isPlaying = !_isPlaying);
                _isPlaying ? _videoController!.play() : _videoController!.pause();
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
              onPressed: () {
                final pos = _videoController!.value.position;
                _videoController!.seekTo(pos + const Duration(seconds: 10));
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(widget.lesson.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl),
        ),
        if (widget.lesson.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.lesson.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textDirection: TextDirection.rtl),
          ),
      ],
    );
  }

  Widget _buildImageViewer() {
    final path = widget.lesson.filePath;
    final url = widget.lesson.fileUrl;
    return Center(
      child: path != null
          ? Image.file(File(path), fit: BoxFit.contain)
          : url != null
              ? Image.network(url, fit: BoxFit.contain)
              : const Text('لا يوجد ملف', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildLinkViewer() {
    final url = widget.lesson.fileUrl;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link, color: Colors.white, size: 60),
          const SizedBox(height: 16),
          Text(url ?? '', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: url != null ? () => launchUrl(Uri.parse(url)) : null,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('فتح الرابط'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewer() {
    final path = widget.lesson.filePath;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.lesson.type.icon, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(widget.lesson.fileName ?? widget.lesson.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(widget.lesson.type.label,
                style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 32),
          if (path != null)
            ElevatedButton.icon(
              onPressed: () => OpenFile.open(path),
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح الملف', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            )
          else if (widget.lesson.fileUrl != null)
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(widget.lesson.fileUrl!)),
              icon: const Icon(Icons.download),
              label: const Text('تحميل الملف', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            ),
        ],
      ),
    );
  }
}
