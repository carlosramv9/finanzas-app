import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricDataSource {
  BiometricDataSource([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> disponible() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> autenticar() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Desbloquea Finanzas',
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
