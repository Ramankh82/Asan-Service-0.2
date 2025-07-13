import 'package:asan_service_app/api_service.dart';
import 'package:asan_service_app/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfilePage({super.key, required this.initialData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initialData['first_name']);
    _lastNameController = TextEditingController(text: widget.initialData['last_name']);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token!;
      await _apiService.updateUserProfile(
        token: token,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پروفایل با موفقیت به‌روزرسانی شد.'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true); // با مقدار true برمی‌گردیم تا صفحه پروفایل رفرش شود
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش پروفایل')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'نام'),
                validator: (value) => value!.isEmpty ? 'نام نمی‌تواند خالی باشد' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'نام خانوادگی'),
                validator: (value) => value!.isEmpty ? 'نام خانوادگی نمی‌تواند خالی باشد' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const CircularProgressIndicator() : const Text('ذخیره تغییرات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}