/// Un'offerta letta da un volantino.
///
/// I prezzi sono in euro. [quantity] è espressa nell'unità base [unit]
/// ('kg', 'l' oppure 'pz'), così si possono confrontare confezioni diverse
/// tramite [unitPrice] (€/kg, €/l, €/pz).
class Offer {
  final int? id;
  final String productName;
  final String canonicalName;
  final String? brand;
  final String category;
  final String store;
  final double price;
  final double? originalPrice;
  final double? quantity;
  final String? unit;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime createdAt;

  const Offer({
    this.id,
    required this.productName,
    required this.canonicalName,
    this.brand,
    required this.category,
    required this.store,
    required this.price,
    this.originalPrice,
    this.quantity,
    this.unit,
    this.validFrom,
    this.validUntil,
    required this.createdAt,
  });

  /// Prezzo per unità base (€/kg, €/l, €/pz). Null se la quantità è ignota.
  double? get unitPrice {
    final q = quantity;
    if (q == null || q <= 0) return null;
    return price / q;
  }

  /// Sconto percentuale rispetto al prezzo pieno, se indicato sul volantino.
  double? get discountPercent {
    final o = originalPrice;
    if (o == null || o <= 0 || o <= price) return null;
    return (o - price) / o * 100;
  }

  /// Un'offerta senza date di validità si considera attiva.
  bool isActive(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (validUntil != null && validUntil!.isBefore(today)) return false;
    if (validFrom != null && validFrom!.isAfter(today)) return false;
    return true;
  }

  /// Chiave per raggruppare la stessa referenza tra supermercati diversi.
  String get groupKey => '${canonicalName.trim().toLowerCase()}|${unit ?? '-'}';

  Offer copyWith({int? id, String? store}) => Offer(
        id: id ?? this.id,
        productName: productName,
        canonicalName: canonicalName,
        brand: brand,
        category: category,
        store: store ?? this.store,
        price: price,
        originalPrice: originalPrice,
        quantity: quantity,
        unit: unit,
        validFrom: validFrom,
        validUntil: validUntil,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'product_name': productName,
        'canonical_name': canonicalName,
        'brand': brand,
        'category': category,
        'store': store,
        'price': price,
        'original_price': originalPrice,
        'quantity': quantity,
        'unit': unit,
        'valid_from': validFrom?.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Offer.fromMap(Map<String, Object?> m) => Offer(
        id: m['id'] as int?,
        productName: m['product_name'] as String,
        canonicalName: m['canonical_name'] as String,
        brand: m['brand'] as String?,
        category: m['category'] as String,
        store: m['store'] as String,
        price: (m['price'] as num).toDouble(),
        originalPrice: (m['original_price'] as num?)?.toDouble(),
        quantity: (m['quantity'] as num?)?.toDouble(),
        unit: m['unit'] as String?,
        validFrom: _parseDate(m['valid_from']),
        validUntil: _parseDate(m['valid_until']),
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  /// Costruisce un'offerta dal JSON restituito dall'AI.
  /// Restituisce null se mancano i dati minimi (nome e prezzo).
  static Offer? fromAiJson(
    Map<String, dynamic> j, {
    required String store,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? now,
  }) {
    final name = (j['product_name'] ?? j['name'])?.toString().trim();
    final price = _toDouble(j['price']);
    if (name == null || name.isEmpty || price == null || price <= 0) {
      return null;
    }
    final normalized = normalizeQuantity(_toDouble(j['quantity']), j['unit']?.toString());
    final canonical = j['canonical_name']?.toString().trim();
    return Offer(
      productName: name,
      canonicalName: (canonical == null || canonical.isEmpty) ? name.toLowerCase() : canonical.toLowerCase(),
      brand: _emptyToNull(j['brand']?.toString()),
      category: _emptyToNull(j['category']?.toString()) ?? 'Altro',
      store: _emptyToNull(j['store']?.toString()) ?? store,
      price: price,
      originalPrice: _toDouble(j['original_price']),
      quantity: normalized.$1,
      unit: normalized.$2,
      validFrom: _parseDate(j['valid_from']) ?? validFrom,
      validUntil: _parseDate(j['valid_until']) ?? validUntil,
      createdAt: now ?? DateTime.now(),
    );
  }
}

/// Converte quantità e unità in unità base: g→kg, ml/cl→l, altrimenti pz.
(double?, String?) normalizeQuantity(double? quantity, String? unit) {
  if (quantity == null || quantity <= 0) return (null, null);
  switch ((unit ?? '').trim().toLowerCase()) {
    case 'kg':
      return (quantity, 'kg');
    case 'g':
    case 'gr':
      return (quantity / 1000, 'kg');
    case 'l':
    case 'lt':
      return (quantity, 'l');
    case 'cl':
      return (quantity / 100, 'l');
    case 'ml':
      return (quantity / 1000, 'l');
    case 'pz':
    case 'pezzi':
    case 'pezzo':
    case 'unità':
      return (quantity, 'pz');
    default:
      return (null, null);
  }
}

double? _toDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().replaceAll('€', '').replaceAll(',', '.').trim();
  return double.tryParse(s);
}

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String? _emptyToNull(String? s) {
  final t = s?.trim();
  return (t == null || t.isEmpty || t.toLowerCase() == 'null') ? null : t;
}
