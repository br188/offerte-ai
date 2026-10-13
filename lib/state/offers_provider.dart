import 'package:flutter/foundation.dart';

import '../models/offer.dart';
import '../services/offer_repository.dart';
import '../services/price_analyzer.dart';

/// Stato dell'app: offerte salvate, filtri e riepiloghi dei prezzi.
class OffersProvider extends ChangeNotifier {
  final OfferRepository _repository;
  final PriceAnalyzer _analyzer;

  OffersProvider(this._repository, {PriceAnalyzer? analyzer}) : _analyzer = analyzer ?? PriceAnalyzer();

  List<Offer> _offers = [];
  List<ProductSummary> _summaries = [];
  bool _loading = false;
  String _query = '';
  String? _store;
  bool _onlyActive = true;

  bool get loading => _loading;
  String get query => _query;
  String? get storeFilter => _store;
  bool get onlyActive => _onlyActive;

  List<String> get stores => (_offers.map((o) => o.store).toSet().toList()..sort());

  List<Offer> get offers {
    final now = DateTime.now();
    return _offers.where((o) {
      if (_onlyActive && !o.isActive(now)) return false;
      if (_store != null && o.store != _store) return false;
      return _matches(o.productName, o.canonicalName, o.brand);
    }).toList();
  }

  List<ProductSummary> get summaries => _summaries.where((s) {
        if (_onlyActive && s.activeOffers.isEmpty) return false;
        if (_store != null && !s.activeOffers.any((o) => o.store == _store)) return false;
        return _matches(s.name, s.history.first.productName, s.history.first.brand);
      }).toList();

  ProductSummary? summaryFor(String key) {
    for (final s in _summaries) {
      if (s.key == key) return s;
    }
    return null;
  }

  bool _matches(String a, String b, String? c) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return a.toLowerCase().contains(q) || b.toLowerCase().contains(q) || (c?.toLowerCase().contains(q) ?? false);
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _offers = await _repository.getAll();
      _summaries = _analyzer.summarize(_offers);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Ricarica senza mostrare il caricamento (per aggiornamenti dopo una modifica).
  Future<void> _refresh() async {
    _offers = await _repository.getAll();
    _summaries = _analyzer.summarize(_offers);
    notifyListeners();
  }

  Future<void> addOffers(List<Offer> offers) async {
    await _repository.insertAll(offers);
    await _refresh();
  }

  Future<void> deleteOffer(Offer offer) async {
    final id = offer.id;
    if (id == null) return;
    // Rimozione immediata dalla lista, richiesta da Dismissible.
    _offers = _offers.where((o) => o.id != id).toList();
    _summaries = _analyzer.summarize(_offers);
    notifyListeners();
    await _repository.delete(id);
  }

  Future<int> deleteExpired() async {
    final n = await _repository.deleteExpired();
    await _refresh();
    return n;
  }

  Future<void> deleteAll() async {
    await _repository.deleteAll();
    await _refresh();
  }

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  void setStore(String? value) {
    _store = value;
    notifyListeners();
  }

  void setOnlyActive(bool value) {
    _onlyActive = value;
    notifyListeners();
  }
}
