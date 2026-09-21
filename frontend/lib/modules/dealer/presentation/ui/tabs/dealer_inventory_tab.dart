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
          return SizedBox(
            height: 380,
            child: CarCard(
              imageUrl: car['imageUrl'] as String,
              title: '${car['year']} ${car['make']} ${car['model']}',
              location: 'Verified Dealership Stock',
              priceText: '₹${((car['price'] as num) / 100000).toStringAsFixed(2)} Lakh',
              badgeText: 'In Stock',
              badgeBgColor: const Color(0xFFDCFCE7),
              badgeTextColor: const Color(0xFF166534),
              specs: [
                CarSpecItem(
                  icon: Icons.calendar_today_outlined,
                  label: '${car['year']}',
                ),
                CarSpecItem(
                  icon: Icons.speed,
                  label: '${((car['kmDriven'] as num) / 1000).toStringAsFixed(0)}k km',
                ),
                CarSpecItem(
                  icon: Icons.local_gas_station_outlined,
                  label: car['fuelType'] as String,
                ),
                CarSpecItem(
                  icon: Icons.tune,
                  label: car['transmission'] as String,
                ),
              ],
              primaryAction: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Manage Listing',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              onTap: () {
                // Open edit inventory or details
              },
            ),
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
