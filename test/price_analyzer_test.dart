import 'package:flutter_test/flutter_test.dart';
import 'package:offerte_ai/models/offer.dart';
import 'package:offerte_ai/services/ai_extractor.dart';
import 'package:offerte_ai/services/price_analyzer.dart';

Offer _offer(String store, double price, {double qty = 0.5, DateTime? until, DateTime? created}) => Offer(
      productName: 'Pasta $store',
      canonicalName: 'pasta di semola',
      category: 'Pane e pasta',
      store: store,
      price: price,
      quantity: qty,
      unit: 'kg',
      validUntil: until,
      createdAt: created ?? DateTime(2026, 10, 1),
    );

void main() {
  final now = DateTime(2026, 10, 13);

  group('normalizeQuantity', () {
    test('converte grammi e millilitri', () {
      expect(normalizeQuantity(500, 'g'), (0.5, 'kg'));
      expect(normalizeQuantity(750, 'ml'), (0.75, 'l'));
      expect(normalizeQuantity(33, 'cl'), (0.33, 'l'));
      expect(normalizeQuantity(6, 'pz'), (6.0, 'pz'));
    });

    test('unità sconosciuta o quantità mancante', () {
      expect(normalizeQuantity(null, 'g'), (null, null));
      expect(normalizeQuantity(3, 'confezioni'), (null, null));
    });
  });

  group('percentile', () {
    test('mediana con numero pari e dispari di valori', () {
      expect(median([1, 2, 3]), 2);
      expect(median([1, 2, 3, 4]), 2.5);
    });
  });

  group('PriceAnalyzer', () {
    final analyzer = PriceAnalyzer();

    test('confronta per prezzo al kg tra formati diversi', () {
      final offers = [
        _offer('Conad', 0.89, qty: 0.5), // 1,78 €/kg
        _offer('Lidl', 1.59, qty: 1.0), // 1,59 €/kg → migliore
      ];
      final s = analyzer.summarize(offers, now: now).single;
      expect(s.best!.store, 'Lidl');
    });

    test('esclude le offerte scadute dai prezzi attuali ma le tiene nello storico', () {
      final offers = [
        _offer('Conad', 0.50, until: DateTime(2026, 9, 1)),
        _offer('Coop', 0.99, until: DateTime(2026, 10, 20)),
      ];
      final s = analyzer.summarize(offers, now: now).single;
      expect(s.activeOffers.map((o) => o.store), ['Coop']);
      expect(s.history.length, 2);
    });

    test('giudica ottimo un prezzo nel quartile più basso', () {
      final offers = [
        _offer('A', 1.20, until: DateTime(2026, 1, 1)),
        _offer('B', 1.10, until: DateTime(2026, 2, 1)),
        _offer('C', 1.00, until: DateTime(2026, 3, 1)),
        _offer('D', 0.70, until: DateTime(2026, 10, 31)),
      ];
      final s = analyzer.summarize(offers, now: now).single;
      expect(s.verdict, PriceVerdict.ottimo);
      expect(s.savingsPercent, greaterThan(0));
    });

    test('con poche rilevazioni non dà giudizi', () {
      final s = analyzer.summarize([_offer('A', 1.0)], now: now).single;
      expect(s.verdict, PriceVerdict.pochiDati);
    });
  });

  group('AiExtractor.parseResponse', () {
    test('legge il JSON anche se circondato da testo', () {
      const text = '''Ecco le offerte:
```json
{"store": "Esselunga", "valid_from": "2026-10-10", "valid_until": "2026-10-23",
 "offers": [
  {"product_name": "Passata Mutti 700 g", "canonical_name": "Passata di pomodoro", "brand": "Mutti",
   "category": "Dispensa", "price": "1,29", "original_price": 1.79, "quantity": 700, "unit": "g"},
  {"product_name": "Prodotto senza prezzo", "price": null}
 ]}
```''';
      final r = AiExtractor.parseResponse(text, now: now);
      expect(r.store, 'Esselunga');
      expect(r.offers.length, 1);
      final o = r.offers.single;
      expect(o.canonicalName, 'passata di pomodoro');
      expect(o.price, 1.29);
      expect(o.quantity, closeTo(0.7, 1e-9));
      expect(o.unit, 'kg');
      expect(o.validUntil, DateTime(2026, 10, 23));
      expect(o.discountPercent!.round(), 28);
    });

    test('usa il supermercato indicato se l\'AI non lo riconosce', () {
      final r = AiExtractor.parseResponse('{"store": null, "offers": []}', storeHint: 'Lidl');
      expect(r.store, 'Lidl');
    });

    test('errore se la risposta non contiene JSON', () {
      expect(() => AiExtractor.parseResponse('non riesco a leggere'), throwsA(isA<AiExtractionException>()));
    });
  });
}
