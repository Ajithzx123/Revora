import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/car_card.dart';
import '../../domain/entities/quote.dart';

/// One dealer's quote. Everything the buyer needs to compare is on the card: total price,
/// whether the car is in stock, how long the price holds, delivery and warranty. Buttons
/// change with the quote's state (open, countered, closed).
class CustomerQuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onAccept;
  final VoidCallback? onCounter;
  final VoidCallback? onReject;
  final VoidCallback? onTakeCounter;
  final VoidCallback? onDeclineCounter;
  final bool isHomeScreen;
  final double? imageHeight;

  const CustomerQuoteCard({
    super.key,
    required this.quote,
    this.onAccept,
    this.onCounter,
    this.onReject,
    this.onTakeCounter,
    this.onDeclineCounter,
    this.isHomeScreen = false,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final open = quote.openRound;
    final dealerCountered = open != null && open.by == 'DEALER';
    final waitingOnDealer = open != null && open.by == 'CUSTOMER';

    final String badge;
    final Color badgeBg;
    final Color badgeFg;
    if (isHomeScreen) {
      badge = 'FEATURED';
      badgeBg = AppColors.accent;
      badgeFg = AppColors.onAccent;
    } else if (quote.isAccepted) {
      badge = 'ACCEPTED';
      badgeBg = AppColors.successBg;
      badgeFg = AppColors.success;
    } else if (!quote.isLive) {
      badge = quote.statusLabel.toUpperCase();
      badgeBg = AppColors.primarySubtle;
      badgeFg = AppColors.textSecondary;
    } else {
      badge = quote.kindLabel.toUpperCase();
      badgeBg = quote.kind == 'IN_STOCK' ? AppColors.successBg : AppColors.warningBg;
      badgeFg = quote.kind == 'IN_STOCK' ? AppColors.success : AppColors.warning;
    }

    String? note;
    if (dealerCountered) {
      note = 'Dealer countered at ${PriceFormatter.formatINR(open.price)}';
    } else if (waitingOnDealer) {
      note = 'Your offer of ${PriceFormatter.formatINR(open.price)} is waiting for the dealer';
    } else if (quote.status.toUpperCase() == 'REQUOTE_REQUESTED') {
      note = 'You changed the request, so the dealer is updating this price';
    } else if (quote.revision > 1 && quote.isLive) {
      note = 'Price revised ${quote.revision - 1} time${quote.revision > 2 ? 's' : ''}';
    }

    return CarCard(
      imageHeight: imageHeight,
      imageUrl: quote.carImageUrl,
      title: quote.carTitle,
      subtitle: note ?? (isHomeScreen ? 'Based on your search history' : null),
      location: quote.dealerCity.isEmpty ? quote.dealerName : '${quote.dealerName} • ${quote.dealerCity}',
      priceText: quote.formattedPrice,
      priceLabel: 'Total price',
      badgeText: badge,
      badgeBgColor: badgeBg,
      badgeTextColor: badgeFg,
      showFavorite: false,
      specs: [
        if (quote.carYear > 0) CarSpecItem(icon: Icons.calendar_today_outlined, label: '${quote.carYear}'),
        if (quote.carMileage > 0)
          CarSpecItem(icon: Icons.speed, label: '${(quote.carMileage / 1000).toStringAsFixed(0)}k km'),
        if (quote.carFuel.isNotEmpty) CarSpecItem(icon: Icons.local_gas_station_outlined, label: quote.carFuel),
        if (quote.dealerRating > 0)
          CarSpecItem(icon: Icons.star_rounded, label: quote.dealerRating.toStringAsFixed(1), color: AppColors.warning),
        if (quote.deliveryDays != null)
          CarSpecItem(icon: Icons.local_shipping_outlined, label: 'Delivery in ${quote.deliveryDays}d'),
        if (quote.warrantyMonths != null && quote.warrantyMonths! > 0)
          CarSpecItem(icon: Icons.verified_user_outlined, label: '${quote.warrantyMonths} mo warranty'),
        if (quote.validityLabel != null) CarSpecItem(icon: Icons.timer_outlined, label: quote.validityLabel!),
      ],
      secondaryAction: !quote.isLive
          ? null
          : dealerCountered
              ? OutlinedButton(onPressed: onDeclineCounter, child: const Text('Decline'))
              : OutlinedButton(onPressed: waitingOnDealer ? null : onCounter, child: Text(waitingOnDealer ? 'Sent' : 'Counter')),
      primaryAction: !quote.isLive
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: dealerCountered ? onTakeCounter : onAccept,
                    child: Text(dealerCountered ? 'Take ${PriceFormatter.formatINR(open.price)}' : 'Accept deal'),
                  ),
                ),
                if (onReject != null) TextButton(onPressed: onReject, child: const Text('Not interested')),
              ],
            ),
    );
  }
}
