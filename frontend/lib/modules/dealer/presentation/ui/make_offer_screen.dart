import 'package:flutter/material.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../core/theme/app_colors.dart';

class MakeOfferScreen extends StatelessWidget {
  final String listingId;

  const MakeOfferScreen({
    super.key,
    required this.listingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Purchase Offer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Listing: 2019 Hyundai Creta SX(O)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Customer Asking Price: ₹10,00,000', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Your Purchase Offer (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Terms / Notes for Customer',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Submit Offer',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offer submitted successfully!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
