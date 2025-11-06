import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/turno_model.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static const String tanquesBoxName = "tanques";
  static const String leiturasBoxName = "leituras";
  static const String turnosBoxName = "turnos";

  HiveService._privateConstructor();
  static final HiveService _instance = HiveService._privateConstructor();
  static HiveService get instance => _instance;

  late Box<Tanque> tanquesBox;
  late Box<Leitura> leiturasBox;
  late Box<Turno> turnosBox;

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
    Hive.registerAdapter(TurnoAdapter());

    tanquesBox = await Hive.openBox<Tanque>(tanquesBoxName);
    leiturasBox = await Hive.openBox<Leitura>(leiturasBoxName);
    turnosBox = await Hive.openBox<Turno>(turnosBoxName);

    if (tanquesBox.isEmpty) {
      final idTanque1 = _uuid.v4();
      await tanquesBox.put(idTanque1, Tanque(id: idTanque1, nome: 'Viveiro 1'));
    }
  }

  // --- VIVEIROS (CRUD) ---
  ValueListenable<Box<Tanque>> getTanquesListenable() {
    return tanquesBox.listenable();
  }

  List<Tanque> getTodosTanques() {
    var tanques = tanquesBox.values.toList();
    tanques.sort((a, b) => a.nome.compareTo(b.nome));
    return tanques;
  }

  Future<void> addTanque(String nome) async {
    final novoId = _uuid.v4();
    final novoTanque = Tanque(id: novoId, nome: nome);
    await tanquesBox.put(novoId, novoTanque);
  }

  Future<void> updateTank(Tanque tanque, String novoNome) async {
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
    await tanque.delete();
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

  List<Leitura> getLeiturasPorTurno(Turno turno) {
    final leituras = leiturasBox.values
        .where((l) => l.idTurno == turno.id)
        .toList();
    leituras.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return leituras;
  }

  // 1. REMOVIDA: getLeiturasPorDia(DateTime dia)

  // --- SECÇÃO DE TURNOS (Automática 12h-a-12h) ---

  Future<Turno> getOrCreateTurnoAtual() async {
    final now = DateTime.now();
    DateTime inicioTurnoAtual;

    final meioDiaDeHoje = DateTime(now.year, now.month, now.day, 12, 0, 0);

    if (now.isBefore(meioDiaDeHoje)) {
      inicioTurnoAtual = meioDiaDeHoje.subtract(const Duration(days: 1));
    } else {
      inicioTurnoAtual = meioDiaDeHoje;
    }

    for (var turno in turnosBox.values) {
      if (turno.dataHoraInicio == inicioTurnoAtual) {
        return turno;
      }
    }

    Turno? turnoAnterior;
    for (var turno in turnosBox.values) {
      if (turno.dataHoraFim == null &&
          turno.dataHoraInicio != inicioTurnoAtual) {
        turnoAnterior = turno;
        break;
      }
    }

    if (turnoAnterior != null) {
      turnoAnterior.dataHoraFim = inicioTurnoAtual.subtract(
        const Duration(seconds: 1),
      );
      await turnoAnterior.save();
    }

    final novoTurno = Turno(
      id: _uuid.v4(),
      dataHoraInicio: inicioTurnoAtual,
      dataHoraFim: null,
    );
    await turnosBox.put(novoTurno.id, novoTurno);

    return novoTurno;
  }

  List<Turno> getTurnosPorIntervalo(DateTime startDate, DateTime endDate) {
    // Assegura que o startDate começa no início do dia
    final inicio = DateTime(startDate.year, startDate.month, startDate.day);

    final turnos = turnosBox.values.where((turno) {
      // Queremos turnos que INICIARAM dentro do intervalo
      return (turno.dataHoraInicio.isAfter(inicio) ||
              turno.dataHoraInicio.isAtSameMomentAs(inicio)) &&
          (turno.dataHoraInicio.isBefore(endDate) ||
              turno.dataHoraInicio.isAtSameMomentAs(endDate));
    }).toList();

    turnos.sort((a, b) => a.dataHoraInicio.compareTo(b.dataHoraInicio));
    return turnos;
  }
}
