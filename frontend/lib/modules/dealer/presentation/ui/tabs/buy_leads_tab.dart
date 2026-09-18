import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/custom_card.dart';
import '../../../../../shared/widgets/custom_button.dart';

class BuyLeadsTab extends StatelessWidget {
  const BuyLeadsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock customer requirements in dealer's city
    final buyLeads = [
      {
        'id': 'REQ-123',
        'title': '2020+ Toyota Innova Crysta Diesel',
        'budget': '₹15 - ₹20 Lakh',
        'location': 'Bengaluru',
        'time': '2 hours ago',
      },
      {
        'id': 'REQ-124',
        'title': '2022 Hyundai Creta Petrol Automatic',
        'budget': '₹12 - ₹16 Lakh',
        'location': 'Bengaluru',
        'time': '5 hours ago',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Leads (Customer Requirements)'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: buyLeads.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final lead = buyLeads[index];
          return CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lead['location'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      lead['time'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lead['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer Budget: ${lead['budget']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Send Quote',
                  onPressed: () {
                    context.push('/dealer/send-quote/${lead['id']}');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
