import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Impostazioni salvate in modo cifrato sul dispositivo.
class SettingsService {
  static const defaultModel = 'claude-sonnet-5-5';
  static const _keyApi = 'anthropic_api_key';
  static const _keyModel = 'anthropic_model';

  final FlutterSecureStorage _storage;

  SettingsService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<String> getApiKey() async => await _storage.read(key: _keyApi) ?? '';

  Future<void> setApiKey(String value) => _storage.write(key: _keyApi, value: value.trim());

  Future<String> getModel() async {
    final m = await _storage.read(key: _keyModel);
    return (m == null || m.trim().isEmpty) ? defaultModel : m;
  }

  Future<void> setModel(String value) => _storage.write(key: _keyModel, value: value.trim());
}
