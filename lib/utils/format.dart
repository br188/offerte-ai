import '../models/offer.dart';

/// 1.5 → "1,50 €"
String euro(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

/// Prezzo per unità leggibile, es. "3,98 €/kg".
String? unitPriceLabel(Offer o) {
  final up = o.unitPrice;
  if (up == null || o.unit == null) return null;
  return '${euro(up)}/${o.unit}';
}

/// Prezzo comparabile con unità, es. "3,98 €/kg" oppure "1,99 €".
String comparableLabel(double value, String? unit) => unit == null ? euro(value) : '${euro(value)}/$unit';

/// 2026-10-13 → "13/10"
String shortDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

String validityLabel(Offer o) {
  if (o.validUntil == null) return 'Validità non indicata';
  if (o.validFrom == null) return 'Fino al ${shortDate(o.validUntil!)}';
  return 'Dal ${shortDate(o.validFrom!)} al ${shortDate(o.validUntil!)}';
}
