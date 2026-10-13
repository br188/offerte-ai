import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/price_analyzer.dart';
import '../state/offers_provider.dart';
import '../utils/format.dart';
import '../widgets/offer_tile.dart';
import '../widgets/verdict_chip.dart';

/// Confronto di un prodotto tra supermercati e storico dei prezzi.
class ProductScreen extends StatelessWidget {
  final String productKey;
  const ProductScreen({super.key, required this.productKey});

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<OffersProvider>().summaryFor(productKey);
    if (summary == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Prodotto non trovato')));
    }
    final now = DateTime.now();
    final expired = summary.history.where((o) => !o.isActive(now)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(summary.name)),
      body: ListView(
        children: [
          _EstimateCard(summary: summary),
          const _SectionTitle('Dove conviene ora'),
          if (summary.activeOffers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Nessuna offerta attiva al momento.'),
            ),
          for (var i = 0; i < summary.activeOffers.length; i++)
            OfferTile(offer: summary.activeOffers[i], highlight: i == 0),
          if (expired.isNotEmpty) ...[
            const _SectionTitle('Offerte passate'),
            for (final o in expired) OfferTile(offer: o),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final ProductSummary summary;
  const _EstimateCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = summary.best;
    final fair = summary.estimatedFairPrice;
    final min = summary.historicalMin;
    final savings = summary.savingsPercent;
    final samples = summary.history.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Stima del prezzo', style: theme.textTheme.titleMedium)),
                VerdictChip(summary.verdict),
              ],
            ),
            const SizedBox(height: 12),
            if (best != null)
              _Line('Miglior prezzo ora', '${comparableLabel(comparablePrice(best), summary.unit)} da ${best.store}'),
            if (fair != null) _Line('Prezzo abituale stimato', comparableLabel(fair, summary.unit)),
            if (min != null) _Line('Minimo registrato', comparableLabel(min, summary.unit)),
            if (savings != null)
              _Line(savings >= 0 ? 'Risparmio sul solito' : 'Sopra il solito', '${savings.abs().round()}%'),
            const SizedBox(height: 8),
            Text(
              samples < PriceAnalyzer.minSamples
                  ? 'Basato su $samples rilevazioni: la stima migliora man mano che leggi altri volantini.'
                  : 'Basato su $samples rilevazioni in ${summary.history.map((o) => o.store).toSet().length} negozi.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  const _Line(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
