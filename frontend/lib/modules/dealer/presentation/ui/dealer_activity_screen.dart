import 'package:flutter/material.dart';
import '../../../notifications/presentation/ui/notifications_view.dart';

/// The dealer's Activity tab: their notification centre. A new-lead alert opens the
/// quote form for that request.
class DealerActivityScreen extends StatelessWidget {
  const DealerActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationsView(requestRoute: (id) => '/dealer/send-quote/$id');
  }
}
