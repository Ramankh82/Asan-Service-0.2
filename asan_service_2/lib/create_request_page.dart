import 'package:asan_service_app/api_service.dart';
import 'package:asan_service_app/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return; // اگر فرم معتبر نیست، ادامه نده
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      await _apiService.createServiceRequest(
        token: token,
        title: _titleController.text,
        description: _descriptionController.text,
        address: _addressController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('درخواست شما با موفقیت ثبت شد.'), backgroundColor: Colors.green),
        );
        // با مقدار true به صفحه قبل برمی‌گردیم تا لیست رفرش شود
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت درخواست: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت درخواست جدید'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'عنوان درخواست', hintText: 'مثال: سرویس ماهانه آسانسور', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'عنوان نمی‌تواند خالی باشد' : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'توضیحات کامل مشکل', border: OutlineInputBorder()),
                  maxLines: 4,
                  validator: (value) => value!.isEmpty ? 'توضیحات نمی‌تواند خالی باشد' : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'آدرس دقیق', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (value) => value!.isEmpty ? 'آدرس نمی‌تواند خالی باشد' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ثبت نهایی درخواست'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}