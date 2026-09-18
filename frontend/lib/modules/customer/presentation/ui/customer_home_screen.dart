import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import 'widgets/hero_banner.dart';
import 'widgets/action_card.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revora', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // Navigate to profile
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Text('Dev Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Customer Flow'),
              onTap: () {
                Navigator.pop(context); // close drawer
                context.go('/customer/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Dealer Flow'),
              onTap: () {
                Navigator.pop(context);
                context.go('/dealer/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/dashboard');
              },
            ),
          ],
        ),
      ),
      body: ResponsiveLayout(
        mobile: _buildBody(context, isDesktop: false),
        desktop: _buildBody(context, isDesktop: true),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isDesktop}) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroBanner(),
              SizedBox(height: isDesktop ? 32 : 24),
              Text(
                'What would you like to do?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  children: [
                    Expanded(child: _buildBuyCard(context)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildSellCard(context)),
                  ],
                )
              else ...[
                _buildBuyCard(context),
                const SizedBox(height: 16),
                _buildSellCard(context),
              ],
              SizedBox(height: isDesktop ? 48 : 32),
              Text(
                'My Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // Placeholder for Activity Cards
              InkWell(
                onTap: () {
                  context.push('/customer/my-requirements');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'View all active requirements and listings.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyCard(BuildContext context) {
    return ActionCard(
      title: 'I Want to Buy a Car',
      subtitle: 'Post your requirements and dealers will send you their best quotes.',
      icon: Icons.directions_car,
      color: AppColors.primary,
      onTap: () {
        context.push('/customer/post-buy');
      },
    );
  }

  Widget _buildSellCard(BuildContext context) {
    return ActionCard(
      title: 'I Want to Sell My Car',
      subtitle: 'List your car and get competitive purchase offers from dealers.',
      icon: Icons.sell,
      color: AppColors.accent,
      onTap: () {
        context.push('/customer/post-sell');
      },
    );
  }
}
