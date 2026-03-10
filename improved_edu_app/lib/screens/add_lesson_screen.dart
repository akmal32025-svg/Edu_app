import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../models/course_model.dart';
import '../services/course_provider.dart';
import '../utils/app_theme.dart';

class AddLessonScreen extends StatefulWidget {
  final String courseId;
  final int orderIndex;
  const AddLessonScreen({super.key, required this.courseId, required this.orderIndex});

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '0');
  LessonType _type = LessonType.video;
  String? _filePath;
  String? _fileName;
  bool _saving = false;
  bool _useUrl = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة درس جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildField(_titleCtrl, 'عنوان الدرس', Icons.title, required: true),
              const SizedBox(height: 16),
              _buildField(_descCtrl, 'وصف الدرس', Icons.description, maxLines: 2),
              const SizedBox(height: 16),
              _buildField(_durationCtrl, 'المدة (بالدقائق)', Icons.timer,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildFileSection(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الدرس',
                    style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('نوع الدرس', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LessonType.values.map((t) {
            final selected = _type == t;
            return GestureDetector(
              onTap: () => setState(() {
                _type = t;
                _filePath = null;
                _fileName = null;
                _urlCtrl.clear();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(t.label,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFileSection() {
    if (_type == LessonType.link) {
      return _buildField(_urlCtrl, 'رابط المحتوى', Icons.link);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('المحتوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() { _useUrl = !_useUrl; _filePath = null; _fileName = null; _urlCtrl.clear(); }),
              icon: Icon(_useUrl ? Icons.upload_file : Icons.link, size: 18),
              label: Text(_useUrl ? 'رفع ملف' : 'استخدام رابط', style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_useUrl)
          _buildField(_urlCtrl, 'رابط الملف/الفيديو', Icons.link)
        else
          _buildFilePicker(),
      ],
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          color: _filePath != null ? AppTheme.primary.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _filePath != null ? AppTheme.primary : Colors.grey.shade300,
            width: _filePath != null ? 2 : 1,
          ),
        ),
        child: _filePath != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 32),
                  const SizedBox(height: 8),
                  Text(_fileName ?? '', style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  TextButton(onPressed: _pickFile, child: const Text('تغيير الملف')),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_typeIcon, size: 36, color: AppTheme.textSecondary),
                  const SizedBox(height: 8),
                  Text(_uploadHint, style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (_type) {
      case LessonType.video: return Icons.video_call_outlined;
      case LessonType.pdf: return Icons.picture_as_pdf_outlined;
      case LessonType.audio: return Icons.audio_file_outlined;
      case LessonType.image: return Icons.image_outlined;
      default: return Icons.upload_file;
    }
  }

  String get _uploadHint {
    switch (_type) {
      case LessonType.video: return 'اضغط لرفع فيديو (MP4, MOV, AVI)';
      case LessonType.pdf: return 'اضغط لرفع ملف PDF';
      case LessonType.audio: return 'اضغط لرفع ملف صوتي (MP3, WAV)';
      case LessonType.image: return 'اضغط لرفع صورة';
      case LessonType.document: return 'اضغط لرفع مستند (DOC, DOCX, TXT)';
      default: return 'اضغط لرفع الملف';
    }
  }

  Future<void> _pickFile() async {
    try {
      if (_type == LessonType.image) {
        final img = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (img != null) {
          setState(() {
            _filePath = img.path;
            _fileName = p.basename(img.path);
          });
        }
        return;
      }

      final types = <FileType, List<String>?>{
        LessonType.video: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
        LessonType.pdf: ['pdf'],
        LessonType.audio: ['mp3', 'wav', 'aac', 'm4a'],
        LessonType.document: ['doc', 'docx', 'txt', 'pptx', 'xlsx'],
      };

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: types[_type] ?? ['*'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الملف: $e')),
      );
    }
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      textDirection: TextDirection.rtl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.primary)),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fileUrl = _useUrl ? _urlCtrl.text.trim() : null;
      final linkUrl = _type == LessonType.link ? _urlCtrl.text.trim() : null;

      await context.read<CourseProvider>().addLesson(
            courseId: widget.courseId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            type: _type,
            filePath: _filePath,
            fileUrl: fileUrl ?? linkUrl,
            fileName: _fileName,
            durationMinutes: int.tryParse(_durationCtrl.text) ?? 0,
            orderIndex: widget.orderIndex,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
