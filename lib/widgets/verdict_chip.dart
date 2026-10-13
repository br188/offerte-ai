import 'package:flutter/material.dart';

import '../services/price_analyzer.dart';

/// Etichetta colorata con il giudizio sul prezzo.
class VerdictChip extends StatelessWidget {
  final PriceVerdict verdict;
  const VerdictChip(this.verdict, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (verdict) {
      PriceVerdict.ottimo => (scheme.primary, scheme.onPrimary),
      PriceVerdict.buono => (scheme.primaryContainer, scheme.onPrimaryContainer),
      PriceVerdict.medio => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      PriceVerdict.caro => (scheme.errorContainer, scheme.onErrorContainer),
      PriceVerdict.pochiDati => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(verdict.label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
