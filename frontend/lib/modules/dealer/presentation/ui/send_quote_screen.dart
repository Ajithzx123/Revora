import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/car_card.dart';

class SendQuoteScreen extends StatefulWidget {
  final String leadId;

  const SendQuoteScreen({
    super.key,
    required this.leadId,
  });

  @override
  State<SendQuoteScreen> createState() => _SendQuoteScreenState();
}

class _SendQuoteScreenState extends State<SendQuoteScreen> {
  String? _selectedCarId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Quote'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a car from your inventory to quote:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedCarId = 'INV-001';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedCarId == 'INV-001' ? AppColors.accent : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const CarCard(
                  imageUrl: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&q=80&w=600',
                  make: 'Toyota',
                  model: 'Innova Crysta ZX 2.4',
                  year: 2021,
                  price: 1850000,
                  fuelType: 'Diesel',
                  transmission: 'Automatic',
                  kmDriven: 45000,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Final Quoted Price (₹)'),
              keyboardType: TextInputType.number,
              initialValue: '1850000',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Add a note to customer (Optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Send Quote to Customer',
              onPressed: _selectedCarId != null
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quote sent successfully!')),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
