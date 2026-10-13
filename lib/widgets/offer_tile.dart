import 'package:flutter/material.dart';

import '../models/offer.dart';
import '../utils/format.dart';

/// Riga di una singola offerta.
class OfferTile extends StatelessWidget {
  final Offer offer;
  final bool highlight;
  final VoidCallback? onTap;
  final Widget? trailing;

  const OfferTile({super.key, required this.offer, this.highlight = false, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = unitPriceLabel(offer);
    final discount = offer.discountPercent;
    final details = [
      offer.store,
      if (offer.brand != null) offer.brand!,
      if (unit != null) unit,
      validityLabel(offer),
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      tileColor: highlight ? theme.colorScheme.primaryContainer.withAlpha(90) : null,
      title: Text(offer.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: trailing ??
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(euro(offer.price), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (discount != null)
                Text('-${discount.round()}%', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
            ],
          ),
    );
  }
}
