import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ProjectRequestPage extends StatefulWidget {
  const ProjectRequestPage({super.key});

  @override
  State<ProjectRequestPage> createState() => _ProjectRequestPageState();
}

class _ProjectRequestPageState extends State<ProjectRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  String? _projectType;
  List<PlatformFile> _attachments = [];
  bool _isLoading = false;

  final List<String> projectTypes = [
    'نصب جدید',
    'نوسازی کامل',
    'مشاوره فنی',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت درخواست پروژه')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اطلاعات پروژه خود را وارد کنید',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _projectType,
                decoration: const InputDecoration(
                  labelText: 'نوع پروژه',
                  border: OutlineInputBorder(),
                ),
                items: projectTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _projectType = value),
                validator: (value) =>
                    value == null ? 'لطفاً نوع پروژه را انتخاب کنید' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان پروژه',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'لطفاً عنوان پروژه را وارد کنید' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'شرح کامل نیازها و انتظارات',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) =>
                    value!.isEmpty ? 'لطفاً شرح پروژه را وارد کنید' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'آدرس دقیق پروژه',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'لطفاً آدرس پروژه را وارد کنید' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'پیوست‌ها (اختیاری)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._attachments.map((file) => Chip(
                        label: Text(file.name),
                        onDeleted: () => setState(() => _attachments.remove(file)),
                      )),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('افزودن فایل'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('ارسال درخواست'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      
      if (result != null) {
        setState(() => _attachments.addAll(result.files));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در انتخاب فایل: $e')),
      );
    }
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // شبیه‌سازی ارسال درخواست
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RequestConfirmationPage(),
          ),
        );
      });
    }
  }
}

class RequestConfirmationPage extends StatelessWidget {
  const RequestConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'درخواست شما با موفقیت ثبت شد',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'کارشناسان ما جهت هماهنگی جلسه آنلاین اولیه، در چند ساعت آتی با شما تماس خواهند گرفت.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('بازگشت به صفحه اصلی'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}