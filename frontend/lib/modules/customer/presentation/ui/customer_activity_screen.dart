import 'package:flutter/material.dart';
import '../../../notifications/presentation/ui/notifications_view.dart';

/// The customer's Activity tab: their notification centre.
class CustomerActivityScreen extends StatelessWidget {
  const CustomerActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationsView(requestRoute: (id) => '/customer/requirement/$id');
  }
}
