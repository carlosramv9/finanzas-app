class Preferencias {
  const Preferencias({
    this.moneda = 'MXN',
    this.avisosMovimientos = true,
    this.desbloqueoBiometrico = false,
  });

  final String moneda;
  final bool avisosMovimientos;
  final bool desbloqueoBiometrico;

  Preferencias copyWith({
    String? moneda,
    bool? avisosMovimientos,
    bool? desbloqueoBiometrico,
  }) =>
      Preferencias(
        moneda: moneda ?? this.moneda,
        avisosMovimientos: avisosMovimientos ?? this.avisosMovimientos,
        desbloqueoBiometrico: desbloqueoBiometrico ?? this.desbloqueoBiometrico,
      );
}
