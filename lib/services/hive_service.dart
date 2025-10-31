import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:monitor_viveiro/models/tanque_model.dart'; // Ajuste o 'monitor_viveiros'
import 'package:monitor_viveiro/models/leitura_model.dart'; // Ajuste o 'monitor_viveiros'
import 'package:uuid/uuid.dart';

class HiveService {
  static const String tanquesBoxName = "tanques";
  static const String leiturasBoxName = "leituras";

  HiveService._privateConstructor();
  static final HiveService _instance = HiveService._privateConstructor();
  static HiveService get instance => _instance;

  late Box<Tanque> tanquesBox;
  late Box<Leitura> leiturasBox;

  final _uuid = const Uuid();

  Future<void> init() async {
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(dir.path);
    } else {
      await Hive.initFlutter();
    }

    Hive.registerAdapter(TanqueAdapter());
    Hive.registerAdapter(LeituraAdapter());

    tanquesBox = await Hive.openBox<Tanque>(tanquesBoxName);
    leiturasBox = await Hive.openBox<Leitura>(leiturasBoxName);

    // Dados mocados
    if (tanquesBox.isEmpty) {
      if (kDebugMode) {
        print("Hive: Populando tanques mocados...");
      }
      await tanquesBox.put(
        'uuid_tanque_1',
        Tanque(id: 'uuid_tanque_1', nome: 'Tanque 1'),
      );
    }
  }

  // --- TANQUES ---

  ValueListenable<Box<Tanque>> getTanquesListenable() {
    return tanquesBox.listenable();
  }

  List<Tanque> getTodosTanques() {
    var tanques = tanquesBox.values.toList();
    // Ordena por nome (importante para o relatório)
    tanques.sort((a, b) => a.nome.compareTo(b.nome));
    return tanques;
  }

  Future<void> addTanque(String nome) async {
    final nomeExistente = tanquesBox.values.any(
      (t) => t.nome.trim().toLowerCase() == nome.trim().toLowerCase(),
    );

    if (nomeExistente) {
      throw Exception("Um tanque com este nome já existe.");
    }

    final novoId = _uuid.v4();
    final novoTanque = Tanque(id: novoId, nome: nome.trim());

    await tanquesBox.put(novoId, novoTanque);
  }

  Future<void> updateTank(Tanque tanque, String novoNome) async {
    final nomeExistente = tanquesBox.values.any(
      (t) => t.nome.trim().toLowerCase() == novoNome.trim().toLowerCase(),
    );

    if (nomeExistente) {
      throw Exception("Um tanque com este nome já existe.");
    }

    tanque.nome = novoNome;
    await tanque.save();
  }

  Future<void> deleteTank(Tanque tanque) async {
    final leiturasParaExcluir = leiturasBox.values
        .where((leitura) => leitura.idTanque == tanque.id)
        .toList();

    for (var leitura in leiturasParaExcluir) {
      await leiturasBox.delete(leitura.id);
    }

    await tanque.delete(); // Ou tanquesBox.delete(tanque.id);
  }

  // --- LEITURAS ---

  ValueListenable<Box<Leitura>> getLeiturasListenable() {
    return leiturasBox.listenable();
  }

  Future<void> addLeitura(Leitura leitura) async {
    await leiturasBox.put(leitura.id, leitura);
  }

  List<Leitura> getLeiturasDeHoje(String idTanque) {
    final hoje = DateTime.now();
    final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);

    return leiturasBox.values.where((leitura) {
      return leitura.idTanque == idTanque &&
          leitura.dataHora.isAfter(inicioDoDia);
    }).toList();
  }

  // (RF04) NOVA FUNÇÃO para buscar leituras por intervalo
  List<Leitura> getLeiturasPorIntervalo(DateTime inicio, DateTime fim) {
    // Garante que a data de início seja o começo do dia (00:00:00)
    final inicioDoDia = DateTime(inicio.year, inicio.month, inicio.day);

    return leiturasBox.values.where((leitura) {
      // A leitura deve ser DEPOIS ou NO MESMO MOMENTO que o início do dia
      return (leitura.dataHora.isAfter(inicioDoDia) ||
              leitura.dataHora.isAtSameMomentAs(inicioDoDia)) &&
          // E ANTES ou NO MESMO MOMENTO que o fim do intervalo (que já vem como 23:59:59)
          (leitura.dataHora.isBefore(fim) ||
              leitura.dataHora.isAtSameMomentAs(fim));
    }).toList();
  }
}
