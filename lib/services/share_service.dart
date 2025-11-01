// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:intl/intl.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/services/hive_service.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  // Singleton
  ShareService._privateConstructor();
  static final ShareService _instance = ShareService._privateConstructor();
  static ShareService get instance => _instance;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  // Função principal chamada pelo modal
  Future<void> gerarECompartilharRelatorio(
    DateTime inicio,
    DateTime fim,
  ) async {
    // 1. Buscar os dados do Hive
    // Ajustamos a data final para incluir o dia inteiro (até 23:59:59)
    final fimAjustada = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);
    final leituras = HiveService.instance.getLeiturasPorIntervalo(
      inicio,
      fimAjustada,
    );

    // 2. Buscar os tanques (para pegar os nomes)
    final tanques = HiveService.instance.getTodosTanques();
    // Criamos um mapa para facilitar a busca de nomes por ID
    final Map<String, String> mapaNomesTanques = {
      for (var t in tanques) t.id: t.nome,
    };

    // 3. Gerar o texto do relatório
    final String relatorio = _formatarRelatorio(
      leituras,
      mapaNomesTanques,
      inicio,
      fim,
    );

    if (relatorio.isEmpty) {
      // (RF04.2) Se não houver dados, informa o utilizador
      throw Exception("Nenhuma leitura encontrada no período selecionado.");
    }

    // 4. Chamar o Share.share (RF04.4)
    await Share.share(
      relatorio,
      // O 'subject' é usado por apps como email
      subject:
          "Relatório de Monitoramento - ${_dateFormatter.format(inicio)} a ${_dateFormatter.format(fim)}",
    );
  }

  // Agrupa as leituras por dia e depois por tanque (RF04.5)
  String _formatarRelatorio(
    List<Leitura> leituras,
    Map<String, String> mapaNomesTanques,
    DateTime inicio,
    DateTime fim,
  ) {
    if (leituras.isEmpty) {
      return "";
    }

    final StringBuffer buffer = StringBuffer();

    // Título
    buffer.writeln(
      "Relatório de Monitoramento - ${_dateFormatter.format(inicio)} a ${_dateFormatter.format(fim)}\n",
    );

    // Agrupa por Dia
    final Map<DateTime, List<Leitura>> leiturasPorDia = {};
    for (final l in leituras) {
      final diaKey = DateTime(
        l.dataHora.year,
        l.dataHora.month,
        l.dataHora.day,
      );
      if (leiturasPorDia[diaKey] == null) {
        leiturasPorDia[diaKey] = [];
      }
      leiturasPorDia[diaKey]!.add(l);
    }

    final diasOrdenados = leiturasPorDia.keys.toList()..sort();

    // Loop por dia
    for (final dia in diasOrdenados) {
      buffer.writeln("== Data: ${_dateFormatter.format(dia)} ==\n");

      // Agrupa por Viveiro (dentro do dia)
      final Map<String, List<Leitura>> leiturasPorTanque = {};
      for (final l in leiturasPorDia[dia]!) {
        if (leiturasPorTanque[l.idTanque] == null) {
          leiturasPorTanque[l.idTanque] = [];
        }
        leiturasPorTanque[l.idTanque]!.add(l);
      }

      // Ordena os viveiros pelo nome
      final tanquesIdsOrdenados = leiturasPorTanque.keys.toList()
        ..sort(
          (a, b) => (mapaNomesTanques[a] ?? 'Z').compareTo(
            mapaNomesTanques[b] ?? 'Z',
          ),
        );

      // Loop por viveiro
      for (final idTanque in tanquesIdsOrdenados) {
        buffer.writeln(
          // Usa a nomenclatura "Viveiro"
          "${mapaNomesTanques[idTanque] ?? 'Viveiro Desconhecido (ID: $idTanque)'}:",
        );

        // ---- INÍCIO DA MUDANÇA DE FORMATO (COM |) ----

        // 1. Escreve o Cabeçalho (com padding ajustado)
        // Col 1 (7) + Col 2 (12) + Col 3
        buffer.writeln(
          // "Oxigenio" sem ponto
          "Hora   | Oxigenio  | Temperatura",
        );

        // 2. Ordena as leituras do viveiro pela hora
        final leiturasDoTanque = leiturasPorTanque[idTanque]!
          ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

        // 3. Loop por leitura (formato de tabela)
        for (final l in leiturasDoTanque) {
          // Adiciona padding (espaços) à direita para alinhar as colunas

          // Coluna 1 (Hora): 7 caracteres de largura
          String hora = "${_timeFormatter.format(l.dataHora)}  ".padRight(7);

          // Coluna 2 (Oxigênio): 12 caracteres de largura
          // "mg/L" sem espaço
          String oxigenio = "| ${l.oxigenio.toStringAsFixed(1)}mg/L  ".padRight(
            12,
          );

          // Coluna 3 (Temperatura):
          String temp = "| ${l.temperatura.toStringAsFixed(1)}°C";

          buffer.writeln("${hora}${oxigenio}${temp}");
        }

        // 4. Adiciona linha em branco após cada tabela
        buffer.writeln();

        // ---- FIM DA MUDANÇA DE FORMATO ----
      }
    }

    return buffer.toString();
  }
}
