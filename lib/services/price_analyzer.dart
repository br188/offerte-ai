import '../models/offer.dart';

/// Giudizio sul miglior prezzo attuale rispetto allo storico.
enum PriceVerdict {
  ottimo('Ottimo prezzo'),
  buono('Buon prezzo'),
  medio('Nella media'),
  caro('Sopra la media'),
  pochiDati('Pochi dati');

  final String label;
  const PriceVerdict(this.label);
}

/// Riepilogo di un prodotto confrontato tra supermercati e nel tempo.
class ProductSummary {
  final String key;
  final String name;
  final String category;
  final String? unit;

  /// Offerte attive ordinate dalla più conveniente.
  final List<Offer> activeOffers;

  /// Tutte le offerte registrate (anche scadute), dalla più recente.
  final List<Offer> history;

  /// Prezzo "normale" stimato: mediana dello storico (per unità se disponibile).
  final double? estimatedFairPrice;
  final double? historicalMin;
  final PriceVerdict verdict;

  const ProductSummary({
    required this.key,
    required this.name,
    required this.category,
    required this.unit,
    required this.activeOffers,
    required this.history,
    required this.estimatedFairPrice,
    required this.historicalMin,
    required this.verdict,
  });

  Offer? get best => activeOffers.isEmpty ? null : activeOffers.first;

  /// Risparmio percentuale del miglior prezzo attuale rispetto al prezzo stimato.
  double? get savingsPercent {
    final b = best;
    final fair = estimatedFairPrice;
    if (b == null || fair == null || fair <= 0) return null;
    final value = comparablePrice(b);
    return (fair - value) / fair * 100;
  }
}

/// Prezzo usato per i confronti: per unità quando possibile, altrimenti di confezione.
double comparablePrice(Offer o) => o.unitPrice ?? o.price;

/// Analizza le offerte e stima quali sono i prezzi migliori.
class PriceAnalyzer {
  /// Numero minimo di rilevazioni per dare un giudizio affidabile.
  static const int minSamples = 3;

  List<ProductSummary> summarize(List<Offer> offers, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final groups = <String, List<Offer>>{};
    for (final o in offers) {
      groups.putIfAbsent(o.groupKey, () => []).add(o);
    }

    final result = <ProductSummary>[];
    groups.forEach((key, list) {
      final history = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final active = list.where((o) => o.isActive(today)).toList()
        ..sort((a, b) => comparablePrice(a).compareTo(comparablePrice(b)));

      final prices = list.map(comparablePrice).toList()..sort();
      final fair = prices.isEmpty ? null : median(prices);
      final min = prices.isEmpty ? null : prices.first;

      result.add(ProductSummary(
        key: key,
        name: history.first.canonicalName,
        category: history.first.category,
        unit: history.first.unit,
        activeOffers: active,
        history: history,
        estimatedFairPrice: fair,
        historicalMin: min,
        verdict: active.isEmpty ? PriceVerdict.pochiDati : verdictFor(comparablePrice(active.first), prices),
      ));
    });

    // Prima i prodotti con offerte attive e risparmio maggiore.
    result.sort((a, b) {
      final sa = a.savingsPercent ?? double.negativeInfinity;
      final sb = b.savingsPercent ?? double.negativeInfinity;
      final byActive = (b.activeOffers.isNotEmpty ? 1 : 0) - (a.activeOffers.isNotEmpty ? 1 : 0);
      if (byActive != 0) return byActive;
      final bySavings = sb.compareTo(sa);
      if (bySavings != 0) return bySavings;
      return a.name.compareTo(b.name);
    });
    return result;
  }

  /// Confronta un prezzo con lo storico ordinato [sortedPrices].
  PriceVerdict verdictFor(double price, List<double> sortedPrices) {
    if (sortedPrices.length < minSamples) return PriceVerdict.pochiDati;
    final q1 = percentile(sortedPrices, 25);
    final med = median(sortedPrices);
    final q3 = percentile(sortedPrices, 75);
    if (price <= q1) return PriceVerdict.ottimo;
    if (price < med) return PriceVerdict.buono;
    if (price <= q3) return PriceVerdict.medio;
    return PriceVerdict.caro;
  }
}

double median(List<double> sorted) => percentile(sorted, 50);

/// Percentile con interpolazione lineare su una lista già ordinata.
double percentile(List<double> sorted, double p) {
  if (sorted.isEmpty) throw ArgumentError('Lista vuota');
  if (sorted.length == 1) return sorted.first;
  final rank = p / 100 * (sorted.length - 1);
  final lower = rank.floor();
  final upper = rank.ceil();
  final weight = rank - lower;
  return sorted[lower] + (sorted[upper] - sorted[lower]) * weight;
}
