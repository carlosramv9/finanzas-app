/// Rango semiabierto [desde, hasta) en hora local.
class Periodo {
  const Periodo(this.desde, this.hasta);

  factory Periodo.mes(DateTime d) =>
      Periodo(DateTime(d.year, d.month), DateTime(d.year, d.month + 1));

  final DateTime desde;
  final DateTime hasta;

  String get desdeIso => desde.toUtc().toIso8601String();
  String get hastaIso => hasta.toUtc().toIso8601String();

  @override
  bool operator ==(Object other) =>
      other is Periodo && other.desde == desde && other.hasta == hasta;

  @override
  int get hashCode => Object.hash(desde, hasta);
}
