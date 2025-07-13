// package_selection_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:asan_service_app/api_service.dart';
import 'package:asan_service_app/auth_service.dart';
import 'package:provider/provider.dart';

class PackageSelectionPage extends StatefulWidget {
  final int buildingFloors;
  final String buildingType;
  final String elevatorAge;
  final int elevatorCount;

  const PackageSelectionPage({
    super.key,
    required this.buildingFloors,
    required this.buildingType,
    required this.elevatorAge,
    required this.elevatorCount,
  });

  @override
  State<PackageSelectionPage> createState() => _PackageSelectionPageState();
}

class _PackageSelectionPageState extends State<PackageSelectionPage> {
  final _discountController = TextEditingController();
  String? _selectedPackage;
  double? _discountAmount = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> packages = [
    {
      'id': 'basic',
      'name': 'پکیج پایه',
      'description': 'سرویس‌های ماهانه، پشتیبانی تلفنی، بازدید فصلی',
      'features': [
        'سرویس ماهانه توسط تکنسین',
        'پشتیبانی تلفنی 24/7',
        'بازدید فصلی از آسانسور',
        'گزارش عملکرد ماهانه',
      ],
      'basePrice': 1000000.0,
    },
    {
      'id': 'standard',
      'name': 'پکیج استاندارد',
      'description': 'سرویس‌های دو هفته‌یکبار، پشتیبانی فوری، بازدید ماهانه',
      'features': [
        'سرویس هر دو هفته',
        'پشتیبانی فوری در 4 ساعت',
        'بازدید ماهانه از آسانسور',
        'گزارش عملکرد هفتگی',
        'معاینه فنی سالانه',
      ],
      'basePrice': 1500000.0,
    },
    {
      'id': 'premium',
      'name': 'پکیج ویژه',
      'description': 'سرویس هفتگی، پشتیبانی اضطراری، نظارت دائمی',
      'features': [
        'سرویس هفتگی',
        'پشتیبانی اضطراری در 2 ساعت',
        'نظارت آنلاین بر عملکرد',
        'گزارش عملکرد روزانه',
        'معاینه فنی فصلی',
        'خدمات ویژه در تعطیلات',
      ],
      'basePrice': 2500000.0,
    },
  ];

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(locale: 'fa', symbol: 'تومان');

    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب پکیج اشتراک')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'پکیج مناسب خود را انتخاب کنید',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...packages.map((package) => _buildPackageCard(package, priceFormatter)),
            const SizedBox(height: 24),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(
                labelText: 'کد تخفیف (اختیاری)',
                border: const OutlineInputBorder(),
                suffixIcon: _discountController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _discountController.clear();
                          setState(() => _discountAmount = 0);
                        },
                      )
                    : null,
              ),
              onChanged: (value) => _applyDiscount(value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading || _selectedPackage == null ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('پرداخت و فعال‌سازی نهایی'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package, NumberFormat formatter) {
    final isSelected = _selectedPackage == package['id'];
    final price = _calculatePackagePrice(package['basePrice']);
    final discountedPrice = price - (_discountAmount ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.blue[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedPackage = package['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    package['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatter.format(discountedPrice),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(package['description']),
              const SizedBox(height: 16),
              const Text('امکانات پکیج:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...package['features'].map<Widget>((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(feature),
                      ],
                    ),
                  )),
              if (_discountAmount! > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'قیمت قبل از تخفیف: ${formatter.format(price)}',
                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _calculatePackagePrice(double basePrice) {
    double price = basePrice;

    // تبدیل int به double برای محاسبات
    double floors = widget.buildingFloors.toDouble();
    double elevatorCount = widget.elevatorCount.toDouble();

    // محاسبه بر اساس تعداد طبقات
    if (floors > 10) {
      price += (floors - 10) * 50000.0;
    }

    // محاسبه بر اساس نوع ساختمان
    if (widget.buildingType == 'تجاری') {
      price *= 1.2;
    } else if (widget.buildingType == 'پزشکی') {
      price *= 1.3;
    }

    // محاسبه بر اساس عمر آسانسور
    if (widget.elevatorAge == '۵ تا ۱۵ سال') {
      price *= 1.2;
    } else if (widget.elevatorAge == 'بیشتر از ۱۵ سال') {
      price *= 1.5;
    }

    // محاسبه بر اساس تعداد آسانسورها
    price *= elevatorCount;

    return price;
  }

  void _applyDiscount(String code) {
    if (code == 'DISCOUNT10') {
      setState(() => _discountAmount = 100000.0);
    } else if (code == 'DISCOUNT20') {
      setState(() => _discountAmount = 200000.0);
    } else {
      setState(() => _discountAmount = 0.0);
    }
  }

  Future<void> _submit() async {
    if (_selectedPackage == null) return;
    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthService>(context, listen: false).token!;
      await ApiService().createContract(token, {
        'package_id': _selectedPackage,
        'discount_code': _discountController.text.isEmpty ? null : _discountController.text,
        'building_floors': widget.buildingFloors,
        'building_type': widget.buildingType,
        'elevator_age': widget.elevatorAge,
        'elevator_count': widget.elevatorCount,
      });
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('قرارداد با موفقیت فعال شد.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}