import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ContractCard extends StatelessWidget {
  final bool hasActiveContract;
  final int? daysRemaining;
  final String? packageName;
  final VoidCallback? onSubscribePressed;

  const ContractCard({
    super.key,
    required this.hasActiveContract,
    this.daysRemaining,
    this.packageName,
    this.onSubscribePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: hasActiveContract
            ? _buildActiveContract(context)
            : _buildSubscribeButton(context),
      ),
    );
  }

  Widget _buildActiveContract(BuildContext context) {
    final progress = daysRemaining! / 365;
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 10,
          percent: progress,
          center: Text(
            '$daysRemaining\nروز',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          progressColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اشتراک $packageName',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'مدت زمان باقی‌مانده از اشتراک شما',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.verified_user_outlined, size: 50, color: Colors.blue),
        const SizedBox(height: 16),
        Text(
          'آسانسور خود را بیمه کنید!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onSubscribePressed,
          icon: const Icon(Icons.add),
          label: const Text('خرید اشتراک سالانه'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
}
