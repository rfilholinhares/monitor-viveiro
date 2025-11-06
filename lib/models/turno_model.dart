import 'package:hive/hive.dart';

part 'turno_model.g.dart'; // Ficheiro que será gerado

@HiveType(typeId: 2) // 0=Tanque, 1=Leitura, 2=Turno
class Turno extends HiveObject {
  @HiveField(0)
  late String id; // ID único do turno

  @HiveField(1)
  late DateTime dataHoraInicio;

  // dataHoraFim será nulo se o turno estiver ativo
  @HiveField(2)
  DateTime? dataHoraFim;

  // Construtor
  Turno({required this.id, required this.dataHoraInicio, this.dataHoraFim});
}
