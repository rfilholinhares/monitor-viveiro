import 'package:hive/hive.dart';

part 'leitura_model.g.dart'; // Este arquivo será gerado pelo build_runner

@HiveType(typeId: 1) // typeId 1 para Leitura
class Leitura extends HiveObject {
  @HiveField(0)
  late String id; // ID único da leitura (pode ser um timestamp ou UUID)

  @HiveField(1)
  late String idTanque; // Chave estrangeira para o Tanque

  @HiveField(2)
  late DateTime dataHora;

  @HiveField(3)
  late double oxigenio;

  @HiveField(4)
  late double temperatura;

  // Construtor
  Leitura({
    required this.id,
    required this.idTanque,
    required this.dataHora,
    required this.oxigenio,
    required this.temperatura,
  });
}
