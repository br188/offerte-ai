import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/offer.dart';

class AiExtractionException implements Exception {
  final String message;
  AiExtractionException(this.message);
  @override
  String toString() => message;
}

/// Risultato della lettura di una pagina di volantino.
class ExtractionResult {
  final String? store;
  final List<Offer> offers;
  const ExtractionResult({this.store, required this.offers});
}

/// Legge la foto di un volantino con l'API di Claude ed estrae le offerte.
class AiExtractor {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  final String apiKey;
  final String model;
  final http.Client _client;

  AiExtractor({required this.apiKey, required this.model, http.Client? client})
      : _client = client ?? http.Client();

  static const _systemPrompt = '''
Sei un assistente che legge volantini di supermercati italiani.
Estrai TUTTE le offerte visibili nell'immagine e rispondi SOLO con un oggetto JSON valido, senza testo prima o dopo, con questa forma:
{
  "store": "nome del supermercato o null",
  "valid_from": "AAAA-MM-GG o null",
  "valid_until": "AAAA-MM-GG o null",
  "offers": [
    {
      "product_name": "nome come scritto sul volantino",
      "canonical_name": "nome generico del prodotto, minuscolo, senza marca né formato (es. 'passata di pomodoro')",
      "brand": "marca o null",
      "category": "una tra: Frutta e verdura, Carne e pesce, Latticini e uova, Pane e pasta, Dispensa, Surgelati, Bevande, Snack e dolci, Igiene e casa, Altro",
      "price": 1.99,
      "original_price": 2.49,
      "quantity": 500,
      "unit": "g"
    }
  ]
}
Regole:
- price è il prezzo in offerta della confezione, in euro, come numero.
- original_price è il prezzo pieno barrato, se presente, altrimenti null.
- quantity e unit descrivono il contenuto TOTALE della confezione (per una confezione 3x125 g scrivi 375 e "g"). unit è uno tra g, kg, ml, cl, l, pz. Se non è indicato, null.
- Se il prezzo è al kg (es. frutta sfusa), usa quantity 1 e unit "kg".
- Ignora le offerte di cui non leggi chiaramente il prezzo.
- Usa la stessa formulazione di canonical_name per prodotti equivalenti, così da poterli confrontare tra supermercati.
''';

  Future<ExtractionResult> extract(
    Uint8List imageBytes, {
    required String mediaType,
    String? storeHint,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw AiExtractionException('Inserisci la chiave API nelle impostazioni.');
    }

    final body = jsonEncode({
      'model': model,
      'max_tokens': 8000,
      'system': _systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Encode(imageBytes),
              },
            },
            {
              'type': 'text',
              'text': storeHint == null || storeHint.trim().isEmpty
                  ? 'Estrai le offerte da questo volantino.'
                  : 'Estrai le offerte da questo volantino di $storeHint.',
            },
          ],
        },
      ],
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'x-api-key': apiKey.trim(),
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 120));
    } catch (e) {
      throw AiExtractionException('Connessione non riuscita: $e');
    }

    if (response.statusCode != 200) {
      throw AiExtractionException(_describeError(response));
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content = (decoded['content'] as List?) ?? const [];
    final text = content
        .whereType<Map<String, dynamic>>()
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'] as String)
        .join('\n');

    return parseResponse(text, storeHint: storeHint);
  }

  /// Interpreta il testo JSON restituito dal modello.
  /// È statico e pubblico per poterlo testare senza rete.
  static ExtractionResult parseResponse(String text, {String? storeHint, DateTime? now}) {
    final json = _extractJsonObject(text);
    if (json == null) {
      throw AiExtractionException("L'AI non ha restituito dati leggibili. Riprova con una foto più nitida.");
    }

    final store = _clean(json['store']) ?? _clean(storeHint) ?? 'Sconosciuto';
    final validFrom = DateTime.tryParse(json['valid_from']?.toString() ?? '');
    final validUntil = DateTime.tryParse(json['valid_until']?.toString() ?? '');

    final offers = <Offer>[];
    for (final item in (json['offers'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      final offer = Offer.fromAiJson(
        item,
        store: store,
        validFrom: validFrom,
        validUntil: validUntil,
        now: now,
      );
      if (offer != null) offers.add(offer);
    }
    return ExtractionResult(store: store, offers: offers);
  }

  static Map<String, dynamic>? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final value = jsonDecode(text.substring(start, end + 1));
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String? _clean(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty || s.toLowerCase() == 'null') ? null : s;
  }

  static String _describeError(http.Response r) {
    switch (r.statusCode) {
      case 401:
        return 'Chiave API non valida.';
      case 429:
        return 'Troppe richieste: aspetta qualche secondo e riprova.';
      case 413:
        return "Immagine troppo grande.";
      default:
        try {
          final err = jsonDecode(r.body)['error']?['message'];
          if (err != null) return 'Errore API (${r.statusCode}): $err';
        } catch (_) {}
        return 'Errore API (${r.statusCode}).';
    }
  }
}
