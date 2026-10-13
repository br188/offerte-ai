import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../state/offers_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKey = TextEditingController();
  final _model = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = context.read<SettingsService>();
    final key = await s.getApiKey();
    final model = await s.getModel();
    if (!mounted) return;
    setState(() {
      _apiKey.text = key;
      _model.text = model;
    });
  }

  @override
  void dispose() {
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<SettingsService>();
    await s.setApiKey(_apiKey.text);
    await s.setModel(_model.text.trim().isEmpty ? SettingsService.defaultModel : _model.text);
    _toast('Impostazioni salvate');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancellare tutte le offerte?'),
        content: const Text('Perderai anche lo storico usato per stimare i prezzi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancella')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<OffersProvider>().deleteAll();
    _toast('Tutte le offerte sono state cancellate');
  }

  @override
  Widget build(BuildContext context) {
    final offers = context.read<OffersProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Intelligenza artificiale', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKey,
            obscureText: _obscure,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Chiave API Anthropic',
              helperText: 'Si crea su console.anthropic.com. Resta salvata solo su questo telefono.',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _model,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Modello',
              helperText: 'Predefinito: ${SettingsService.defaultModel}',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Salva')),
          const SizedBox(height: 32),
          Text('Dati', style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Rimuovi offerte vecchie'),
            subtitle: const Text('Scadute da più di 6 mesi'),
            onTap: () async {
              final n = await offers.deleteExpired();
              _toast('$n offerte rimosse');
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: const Text('Cancella tutte le offerte'),
            onTap: _confirmDeleteAll,
          ),
        ],
      ),
    );
  }
}
