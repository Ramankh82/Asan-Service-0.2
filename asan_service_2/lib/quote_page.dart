import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'package_selection_page.dart';

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  final _formKey = GlobalKey<FormState>();
  final _floorsController = TextEditingController();
  final _elevatorCountController = TextEditingController();
  String? _buildingType;
  String? _elevatorAge;
  bool _isLoading = false;

  final List<String> buildingTypes = ['مسکونی', 'تجاری', 'اداری', 'پزشکی'];
  final List<String> elevatorAges = ['کمتر از ۵ سال', '۵ تا ۱۵ سال', 'بیشتر از ۱۵ سال'];

  @override
  void dispose() {
    _floorsController.dispose();
    _elevatorCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعلام قیمت اشتراک')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'لطفاً اطلاعات ساختمان خود را وارد کنید',
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
                  labelText: 'نوع کاربری ساختمان',
                  border: OutlineInputBorder(),
                ),
                items: buildingTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _buildingType = value),
                validator: (value) =>
                    value == null ? 'لطفاً نوع کاربری را انتخاب کنید' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _elevatorAge,
                decoration: const InputDecoration(
                  labelText: 'عمر تقریبی آسانسور',
                  border: OutlineInputBorder(),
                ),
                items: elevatorAges
                    .map((age) => DropdownMenuItem(
                          value: age,
                          child: Text(age),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _elevatorAge = value),
                validator: (value) =>
                    value == null ? 'لطفاً عمر آسانسور را انتخاب کنید' : null,
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('محاسبه قیمت'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PackageSelectionPage(
            buildingFloors: int.parse(_floorsController.text),
            buildingType: _buildingType!,
            elevatorAge: _elevatorAge!,
            elevatorCount: int.parse(_elevatorCountController.text),
          ),
        ),
      );
    }
  }
}