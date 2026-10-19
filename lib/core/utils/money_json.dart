/// Postgres `numeric` llega como número o texto según la serialización.
int centavosFromJson(Object? v) => switch (v) {
      num n => (n * 100).round(),
      String s => ((double.tryParse(s) ?? 0) * 100).round(),
      _ => 0,
    };

double centavosToJson(int centavos) => centavos / 100;
