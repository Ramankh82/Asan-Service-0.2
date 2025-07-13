// insurance_page.dart
import 'package:asan_service_app/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class InsurancePage extends StatefulWidget {
  const InsurancePage({super.key});

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  final _formKey = GlobalKey<FormState>();
  final _floorsController = TextEditingController();
  final _elevatorCountController = TextEditingController();
  String? _insuranceType;
  String? _coverageLevel;
  String? _buildingType;
  String? _elevatorAge;
  bool _isLoading = false;

  final List<String> buildingTypes = ['مسکونی', 'تجاری', 'اداری', 'پزشکی'];
  final List<String> elevatorAges = ['کمتر از ۵ سال', '۵ تا ۱۵ سال', 'بیشتر از ۱۵ سال'];
  final List<String> insuranceTypes = ['مسئولیت مدنی', 'حوادث', 'آتش‌سوزی'];
  final List<String> coverageLevels = ['پایه', 'متوسط', 'کامل'];

  @override
  void dispose() {
    _floorsController.dispose();
    _elevatorCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('درخواست بیمه آسانسور')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اطلاعات آسانسور خود را وارد کنید',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _floorsController,
                decoration: const InputDecoration(
                  labelText: 'تعداد طبقات ساختمان',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً تعداد طبقات را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _buildingType,
                decoration: const InputDecoration(
                  labelText: 'نوع ساختمان',
                  border: OutlineInputBorder(),
                ),
                items: buildingTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _buildingType = value),
                validator: (value) => value == null ? 'لطفاً نوع ساختمان را انتخاب کنید' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _elevatorAge,
                decoration: const InputDecoration(
                  labelText: 'عمر تقریبی آسانسور',
                  border: OutlineInputBorder(),
                ),
                items: elevatorAges
                    .map((age) => DropdownMenuItem(value: age, child: Text(age)))
                    .toList(),
                onChanged: (value) => setState(() => _elevatorAge = value),
                validator: (value) => value == null ? 'لطفاً عمر آسانسور را انتخاب کنید' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _insuranceType,
                decoration: const InputDecoration(
                  labelText: 'نوع بیمه',
                  border: OutlineInputBorder(),
                ),
                items: insuranceTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _insuranceType = value),
                validator: (value) => value == null ? 'لطفاً نوع بیمه را انتخاب کنید' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _coverageLevel,
                decoration: const InputDecoration(
                  labelText: 'سطح پوشش',
                  border: OutlineInputBorder(),
                ),
                items: coverageLevels
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) => setState(() => _coverageLevel = value),
                validator: (value) => value == null ? 'لطفاً سطح پوشش را انتخاب کنید' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _elevatorCountController,
                decoration: const InputDecoration(
                  labelText: 'تعداد آسانسورها',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً تعداد آسانسورها را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator() : const Text('محاسبه و درخواست بیمه'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token!;
      final response = await ApiService().createInsurance(token, {
        'insurance_type': _insuranceType,
        'building_floors': int.tryParse(_floorsController.text) ?? 0,
        'building_type': _buildingType,
        'elevator_age': _elevatorAge,
        'elevator_count': int.tryParse(_elevatorCountController.text) ?? 0,
        'coverage_level': _coverageLevel,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درخواست بیمه ثبت شد'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && e is ApiException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${e.message}'), backgroundColor: Colors.red),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}