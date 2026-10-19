import 'package:flutter/material.dart';

/// Paleta del diseño "Finanzas" (verde bosque + azul abono / óxido cargo).
abstract final class AppColors {
  static const primary = Color(0xFF0F5F4F);
  static const primaryDark = Color(0xFF0A4338);
  static const onPrimaryMuted = Color(0xFFD6E8E2);
  static const onPrimarySubtle = Color(0xFFBFDDD3);

  static const background = Color(0xFFF4F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF14201B);
  static const textSecondary = Color(0xFF3D4A44);
  static const textMuted = Color(0xFF56635D);
  static const iconMuted = Color(0xFF7A8782);

  static const border = Color(0xFFC9D2CD);
  static const divider = Color(0xFFDDE3DF);
  static const subtle = Color(0xFFEDF1EE);

  static const selected = Color(0xFFCFE5DD);
  static const tint = Color(0xFFE3EFEB);

  static const abono = Color(0xFF1C56A0);
  static const abonoMuted = Color(0xFFDCE7F6);
  static const cargo = Color(0xFFA6470F);

  static const warningBg = Color(0xFFFFF4E8);
  static const warningBorder = Color(0xFFF0D2B0);
  static const warningText = Color(0xFF6B3209);

  static const danger = Color(0xFF9A2F1F);

  /// Colores elegibles para identificar una cuenta.
  static const cuentaColores = <Color>[
    Color(0xFF0F5F4F),
    Color(0xFF1C56A0),
    Color(0xFF7A3E12),
    Color(0xFF56635D),
    Color(0xFF5B3A8C),
    Color(0xFF8C2F4B),
  ];
}
