import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/offer.dart';
import '../services/ai_extractor.dart';
import '../services/settings_service.dart';
import '../state/offers_provider.dart';
import '../widgets/offer_tile.dart';

/// Fotografa o sceglie una pagina di volantino, la fa leggere all'AI
/// e permette di controllare le offerte prima di salvarle.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _storeController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _image;
  String _mediaType = 'image/jpeg';
  bool _working = false;
  String? _error;
  List<Offer> _found = [];
  final Set<int> _selected = {};

  @override
  void dispose() {
    _storeController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    // Ridimensiona per restare sotto i limiti dell'API e risparmiare dati.
    final file = await _picker.pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final name = file.name.toLowerCase();
    if (!mounted) return;
    setState(() {
      _image = bytes;
      _mediaType = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      _found = [];
      _selected.clear();
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _working = true;
      _error = null;
    });

    final settings = context.read<SettingsService>();
    try {
      final extractor = AiExtractor(apiKey: await settings.getApiKey(), model: await settings.getModel());
      final result = await extractor.extract(image, mediaType: _mediaType, storeHint: _storeController.text);
      if (!mounted) return;
      setState(() {
        _found = result.offers;
        _selected
          ..clear()
          ..addAll(List.generate(result.offers.length, (i) => i));
        if (_storeController.text.trim().isEmpty && result.store != null && result.store != 'Sconosciuto') {
          _storeController.text = result.store!;
        }
        if (result.offers.isEmpty) _error = 'Nessuna offerta trovata in questa immagine.';
      });
    } on AiExtractionException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Errore imprevisto: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _save() async {
    final store = _storeController.text.trim();
    final toSave = [
      for (var i = 0; i < _found.length; i++)
        // Il nome del supermercato nel campo (scritto o corretto dall'utente) ha la precedenza.
        if (_selected.contains(i)) store.isNotEmpty ? _found[i].copyWith(store: store) : _found[i],
    ];
    if (toSave.isEmpty) return;
    await context.read<OffersProvider>().addOffers(toSave);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${toSave.length} offerte salvate')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Leggi volantino')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _storeController,
            decoration: const InputDecoration(
              labelText: 'Supermercato (facoltativo)',
              helperText: "Se lo lasci vuoto, l'AI prova a riconoscerlo dal volantino",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Fotocamera'),
                  onPressed: _working ? null : () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galleria'),
                  onPressed: _working ? null : () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (_image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_image!, height: 220, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: _working
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_working ? 'Lettura in corso…' : 'Trova le offerte'),
              onPressed: _working ? null : _analyze,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_found.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('${_found.length} offerte trovate — togli la spunta a quelle sbagliate',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (var i = 0; i < _found.length; i++)
              OfferTile(
                offer: _found[i],
                onTap: () => _toggle(i),
                trailing: Checkbox(value: _selected.contains(i), onChanged: (_) => _toggle(i)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selected.isEmpty ? null : _save,
              child: Text('Salva ${_selected.length} offerte'),
            ),
          ],
        ],
      ),
    );
  }

  void _toggle(int i) {
    setState(() {
      if (!_selected.remove(i)) _selected.add(i);
    });
  }
}
