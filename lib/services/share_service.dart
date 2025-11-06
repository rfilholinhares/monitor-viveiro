// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:intl/intl.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/turno_model.dart';
import 'package:monitor_viveiro/services/hive_service.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  // Singleton
  ShareService._privateConstructor();
  static final ShareService _instance = ShareService._privateConstructor();
  static ShareService get instance => _instance;

  final DateFormat _timeFormatter = DateFormat('HH:mm');
  final DateFormat _turnoHeaderFormatter = DateFormat('dd/MM HH:mm');

  // (Req #3) Partilha o turno (seja ele vigente ou finalizado)
  // Esta função agora é usada pela HomeScreen E pela HistoryScreen
  Future<void> gerarECompartilharRelatorio(Turno turno) async {
    final tanques = HiveService.instance.getTodosTanques();
    final Map<String, String> mapaNomesTanques = {
      for (var t in tanques) t.id: t.nome,
    };

    // Busca as leituras APENAS deste turno
    final leituras = HiveService.instance.getLeiturasPorTurno(turno);

    // Gera o texto do relatório
    final String relatorio = _formatarRelatorioDeTurno(
      turno,
      leituras,
      mapaNomesTanques,
    );

    if (relatorio.isEmpty) {
      throw Exception("Nenhuma leitura encontrada para este turno.");
    }

    final String inicioFormatado = _turnoHeaderFormatter.format(
      turno.dataHoraInicio,
    );
    await Share.share(
      relatorio,
      subject: "Relatório de Monitoramento - Turno $inicioFormatado",
    );
  }

  // 1. REMOVIDO: gerarECompartilharRelatorioPorDia(DateTime dia)

  // (Função privada para o Req #3)
  String _formatarRelatorioDeTurno(
    Turno turno,
    List<Leitura> leiturasDoTurno,
    Map<String, String> mapaNomesTanques,
  ) {
    final StringBuffer buffer = StringBuffer();

    // Cabeçalho do Turno
    final String inicioFormatado = _turnoHeaderFormatter.format(
      turno.dataHoraInicio,
    );
    final String fimFormatado = turno.dataHoraFim != null
        ? _turnoHeaderFormatter.format(turno.dataHoraFim!)
        : "Em Andamento (até ${_timeFormatter.format(DateTime.now())})";

    buffer.writeln("== Relatório do Turno ==\n");
    buffer.writeln("Início: $inicioFormatado");
    buffer.writeln("Fim:    $fimFormatado\n");

    if (leiturasDoTurno.isEmpty) {
      buffer.writeln("(Nenhuma leitura registrada neste turno)");
      return buffer.toString();
    }

    return _formatarCorpoRelatorio(buffer, leiturasDoTurno, mapaNomesTanques);
  }

  // 2. REMOVIDO: _formatarRelatorioDeDia(...)

  // (Função auxiliar reutilizada por ambas)
  String _formatarCorpoRelatorio(
    StringBuffer buffer,
    List<Leitura> leituras,
    Map<String, String> mapaNomesTanques,
  ) {
    // Agrupa por Viveiro
    final Map<String, List<Leitura>> leiturasPorTanque = {};
    for (final l in leituras) {
      if (leiturasPorTanque[l.idTanque] == null) {
        leiturasPorTanque[l.idTanque] = [];
      }
      leiturasPorTanque[l.idTanque]!.add(l);
    }

    // Ordena os viveiros pelo nome
    final tanquesIdsOrdenados = leiturasPorTanque.keys.toList()
      ..sort(
        (a, b) =>
            (mapaNomesTanques[a] ?? 'Z').compareTo(mapaNomesTanques[b] ?? 'Z'),
      );

    // Loop por viveiro
    for (final idTanque in tanquesIdsOrdenados) {
      buffer.writeln(
        "${mapaNomesTanques[idTanque] ?? 'Viveiro Desconhecido (ID: $idTanque)'}:",
      );

      // Formato de Tabela
      buffer.writeln("Hora   | Oxigenio  | Temperatura");

      final leiturasDoTanque = leiturasPorTanque[idTanque]!;
      // (As leituras já vêm ordenadas por hora do HiveService)

      for (final l in leiturasDoTanque) {
        String hora = "${_timeFormatter.format(l.dataHora)}  ".padRight(7);
        String oxigenio = "| ${l.oxigenio.toStringAsFixed(1)}mg/L  ".padRight(
          12,
        );
        String temp = "| ${l.temperatura.toStringAsFixed(1)}°C";

        buffer.writeln("${hora}${oxigenio}${temp}");
      }
      buffer.writeln(); // Linha em branco
    }

    return buffer.toString();
  }
}
