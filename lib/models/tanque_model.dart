import 'package:hive/hive.dart';

part 'tanque_model.g.dart'; // Este arquivo será gerado pelo build_runner

@HiveType(typeId: 0) // typeId 0 para Tanque
class Tanque extends HiveObject {
  @HiveField(0)
  late String id; // Usaremos como chave (ex: tanque_1)

  @HiveField(1)
  late String nome; // Ex: "Tanque 1"

  // Construtor
  Tanque({required this.id, required this.nome});
}
