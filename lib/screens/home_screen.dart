import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/price_analyzer.dart';
import '../state/offers_provider.dart';
import '../utils/format.dart';
import '../widgets/offer_tile.dart';
import '../widgets/verdict_chip.dart';
import 'product_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Offerte AI'),
          actions: [
            IconButton(
              tooltip: 'Impostazioni',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Prezzi migliori'), Tab(text: 'Tutte le offerte')]),
        ),
        body: const Column(
          children: [
            _Filters(),
            Expanded(child: TabBarView(children: [_BestPricesTab(), _AllOffersTab()])),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Text('Leggi volantino'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OffersProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cerca un prodotto',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: state.setQuery,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Solo attive'),
                  selected: state.onlyActive,
                  onSelected: state.setOnlyActive,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Tutti i negozi'),
                  selected: state.storeFilter == null,
                  onSelected: (_) => state.setStore(null),
                ),
                for (final s in state.stores) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(s),
                    selected: state.storeFilter == s,
                    onSelected: (sel) => state.setStore(sel ? s : null),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BestPricesTab extends StatelessWidget {
  const _BestPricesTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OffersProvider>();
    if (state.loading) return const Center(child: CircularProgressIndicator());
    final items = state.summaries;
    if (items.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _SummaryTile(summary: items[i]),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final ProductSummary summary;
  const _SummaryTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = summary.best;
    final savings = summary.savingsPercent;
    final others = summary.activeOffers.length - 1;

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductScreen(productKey: summary.key)),
      ),
      title: Text(_capitalize(summary.name), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            VerdictChip(summary.verdict),
            if (best != null) Text(best.store),
            if (others > 0) Text('+$others negozi', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      trailing: best == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(euro(best.price), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (savings != null && savings > 0)
                  Text('-${savings.round()}% sul solito',
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
              ],
            ),
    );
  }
}

class _AllOffersTab extends StatelessWidget {
  const _AllOffersTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OffersProvider>();
    if (state.loading) return const Center(child: CircularProgressIndicator());
    final items = state.offers;
    if (items.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final offer = items[i];
        return Dismissible(
          key: ValueKey(offer.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline),
          ),
          onDismissed: (_) => state.deleteOffer(offer),
          child: OfferTile(
            offer: offer,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductScreen(productKey: offer.groupKey)),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'Nessuna offerta.\nFotografa una pagina di volantino per iniziare.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
