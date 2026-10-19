import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (prefs, _) = await (
    SharedPreferences.getInstance(),
    initializeDateFormatting('es_MX'),
  ).wait;

  runApp(
    ProviderScope(
      // Sin reintentos automáticos: un 403/401 no debe repetirse en bucle.
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FinanzasApp(),
    ),
  );
}
