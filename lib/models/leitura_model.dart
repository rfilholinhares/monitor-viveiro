import 'package:hive/hive.dart';

part 'leitura_model.g.dart';

@HiveType(typeId: 1)
class Leitura extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String idTanque; // Chave estrangeira para o Tanque/Viveiro

  @HiveField(2)
  late DateTime dataHora;

  @HiveField(3)
  late double oxigenio;

  @HiveField(4)
  late double temperatura;

  // NOVO CAMPO: Chave estrangeira para o Turno
  @HiveField(5)
  late String idTurno;

  // Construtor ATUALIZADO
  Leitura({
    required this.id,
    required this.idTanque,
    required this.dataHora,
    required this.oxigenio,
    required this.temperatura,
    required this.idTurno, // Adicionado
  });
}
