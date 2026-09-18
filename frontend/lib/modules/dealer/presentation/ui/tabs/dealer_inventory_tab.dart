import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/car_card.dart';

class DealerInventoryTab extends StatelessWidget {
  const DealerInventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock dealer inventory
    final inventory = [
      {
        'id': 'INV-001',
        'imageUrl': 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&q=80&w=600',
        'make': 'Toyota',
        'model': 'Innova Crysta ZX 2.4',
        'year': 2021,
        'price': 1850000,
        'fuelType': 'Diesel',
        'transmission': 'Automatic',
        'kmDriven': 45000,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/dealer/add-car');
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: inventory.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final car = inventory[index];
          return CarCard(
            imageUrl: car['imageUrl'] as String,
            make: car['make'] as String,
            model: car['model'] as String,
            year: car['year'] as int,
            price: car['price'] as num,
            fuelType: car['fuelType'] as String,
            transmission: car['transmission'] as String,
            kmDriven: car['kmDriven'] as num,
            onTap: () {
              // Open edit inventory or details
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/dealer/add-car');
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
