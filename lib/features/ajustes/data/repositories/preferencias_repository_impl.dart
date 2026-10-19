import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/preferencias.dart';
import '../../domain/repositories/preferencias_repository.dart';

class PreferenciasRepositoryImpl implements PreferenciasRepository {
  PreferenciasRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _moneda = 'pref_moneda';
  static const _avisos = 'pref_avisos';
  static const _bio = 'pref_biometria';

  @override
  Preferencias leer() => Preferencias(
        moneda: _prefs.getString(_moneda) ?? 'MXN',
        avisosMovimientos: _prefs.getBool(_avisos) ?? true,
        desbloqueoBiometrico: _prefs.getBool(_bio) ?? false,
      );

  @override
  Future<void> guardar(Preferencias p) async {
    await Future.wait([
      _prefs.setString(_moneda, p.moneda),
      _prefs.setBool(_avisos, p.avisosMovimientos),
      _prefs.setBool(_bio, p.desbloqueoBiometrico),
    ]);
  }
}
