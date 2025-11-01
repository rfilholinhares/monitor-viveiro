// ignore_for_file: prefer_const_constructors_in_immutables, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
import 'package:monitor_viveiro/services/hive_service.dart';

class HistoryScreen extends StatefulWidget {
  final Tanque tanque;

  HistoryScreen({super.key, required this.tanque});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Formatadores de data e hora
  final DateFormat _dayFormatter = DateFormat(
    'dd \'de\' MMMM \'de\' yyyy',
    'pt_BR',
  );
  final DateFormat _timeFormatter = DateFormat('HH:mm');
  // Novo formatador para os botões de filtro
  final DateFormat _filterDateFormatter = DateFormat('dd/MM/yy');

  // 2. Variáveis de estado para o filtro
  DateTime? _startDate;
  DateTime? _endDate;

  // Função para agrupar leituras por dia
  Map<DateTime, List<Leitura>> _groupReadingsByDay(List<Leitura> readings) {
    final Map<DateTime, List<Leitura>> grouped = {};

    for (final leitura in readings) {
      // Cria uma chave de data (ignorando a hora)
      final dayKey = DateTime(
        leitura.dataHora.year,
        leitura.dataHora.month,
        leitura.dataHora.day,
      );

      if (grouped[dayKey] == null) {
        grouped[dayKey] = [];
      }

      // Adiciona a leitura ao grupo daquele dia
      grouped[dayKey]!.add(leitura);
    }
    return grouped;
  }

  // 3. Função para abrir o seletor de intervalo de datas (RF03.5)
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      // Define as datas iniciais (se já houver filtro)
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020), // Data mínima
      lastDate: DateTime.now(), // Data máxima
      locale: const Locale('pt', 'BR'), // Define o local para o picker
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        // Adiciona 23:59:59 ao endDate para incluir o dia inteiro
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  // Função para limpar o filtro
  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Histórico - ${widget.tanque.nome}")),
      body: Column(
        children: [
          // 4. Widget da Barra de Filtro
          _buildFilterBar(),

          // 5. Lista de Leituras (agora expandida)
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveService.instance.getLeiturasListenable(),
              builder: (context, Box<Leitura> leiturasBox, _) {
                // 1. Filtra as leituras APENAS para este viveiro
                final tankReadings = leiturasBox.values
                    .where(
                      (leitura) =>
                          leitura.idTanque ==
                          widget.tanque.id, // Usa widget.tanque
                    )
                    .toList();

                // 2. APLICA O FILTRO DE DATA (RF03.5)
                final List<Leitura> filteredReadings;
                if (_startDate != null && _endDate != null) {
                  filteredReadings = tankReadings.where((leitura) {
                    final inicioDoDia = DateTime(
                      _startDate!.year,
                      _startDate!.month,
                      _startDate!.day,
                    );
                    return (leitura.dataHora.isAfter(inicioDoDia) ||
                            leitura.dataHora.isAtSameMomentAs(inicioDoDia)) &&
                        (leitura.dataHora.isBefore(_endDate!) ||
                            leitura.dataHora.isAtSameMomentAs(_endDate!));
                  }).toList();
                } else {
                  // Se não houver filtro, mostra tudo
                  filteredReadings = tankReadings;
                }

                // 3. Ordena pela data/hora (mais recente primeiro)
                filteredReadings.sort(
                  (a, b) => b.dataHora.compareTo(a.dataHora),
                );

                // 4. Agrupa as leituras (já filtradas) por dia
                final groupedReadings = _groupReadingsByDay(filteredReadings);
                final days = groupedReadings.keys.toList();

                // 5. Verifica se a lista FILTRADA está vazia
                if (filteredReadings.isEmpty) {
                  return Center(
                    child: Text(
                      _startDate == null
                          ? "Nenhum registro encontrado para este viveiro."
                          : "Nenhum registro encontrado neste período.",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // 6. Constrói a lista de dias
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: days.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final readingsForDay = groupedReadings[day]!;

                    return _buildDayGroup(context, day, readingsForDay);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final bool isFilterActive = _startDate != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Botão de Data (agora expandido)
          Expanded(
            // 3. Adicionado Expanded
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_rounded, size: 20),
              label: Text(
                isFilterActive
                    ? "${_filterDateFormatter.format(_startDate!)} - ${_filterDateFormatter.format(_endDate!)}"
                    : "Filtrar por Data",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.9),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _selectDateRange,
            ),
          ),

          // Botão de Limpar (agora usa Visibility)
          Visibility(
            // 4. Substituído 'if' por 'Visibility'
            visible: isFilterActive,
            maintainSize: true, // <-- A CHAVE: Reserva o espaço
            maintainAnimation: true,
            maintainState: true,
            child: IconButton(
              // Usamos a cor vermelha do tema que definimos no main.dart
              icon: Icon(
                Icons.clear_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: "Limpar filtro",
              onPressed: _clearFilter,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para o grupo de um dia
  Widget _buildDayGroup(
    BuildContext context,
    DateTime day,
    List<Leitura> readings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho do Dia (ex: "30 de outubro de 2025")
        Text(
          _dayFormatter.format(day),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),

        // Lista de leituras daquele dia
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: readings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reading = readings[index];
            return _buildHistoryCard(reading);
          },
        ),
      ],
    );
  }

  // Widget para o Card de uma leitura individual
  Widget _buildHistoryCard(Leitura reading) {
    return Card(
      elevation: 1, // Sutil
      child: ListTile(
        // Hora da leitura
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.access_time_filled_rounded,
              size: 18,
              color: Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              _timeFormatter.format(reading.dataHora),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        // Dados de Oxigênio
        title: Text(
          "O₂: ${reading.oxigenio.toStringAsFixed(1)} mg/L",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        // Dados de Temperatura
        subtitle: Text(
          "Temp: ${reading.temperatura.toStringAsFixed(1)} °C",
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
