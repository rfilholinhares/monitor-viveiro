// ignore_for_file: unused_field, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
import 'package:monitor_viveiro/models/turno_model.dart'; // 1. IMPORTAR TURNO
import 'package:monitor_viveiro/services/hive_service.dart';
import 'package:monitor_viveiro/services/share_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Formatadores
  final DateFormat _dayFormatter = DateFormat(
    'dd \'de\' MMMM \'de\' yyyy',
    'pt_BR',
  );
  final DateFormat _timeFormatter = DateFormat('HH:mm');
  final DateFormat _filterDateFormatter = DateFormat('dd/MM/yy');
  // 2. NOVO FORMATADOR PARA CABEÇALHO DO TURNO
  final DateFormat _turnoHeaderFormatter = DateFormat('dd/MM HH:mm');

  // Estado do Filtro
  DateTime? _startDate;
  DateTime? _endDate;
  Tanque? _filtroViveiroSelecionado;
  List<Tanque> _listaDeViveiros = [];

  // 3. ATUALIZADO: Estado de loading por Turno
  bool _isSharingTurno = false;
  Turno? _turnoBeingShared;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setDefaultDateFilter();
  }

  void _loadData() {
    _listaDeViveiros = HiveService.instance.getTodosTanques();
  }

  void _setDefaultDateFilter() {
    final hoje = DateTime.now();
    _startDate = hoje.subtract(const Duration(days: 6));
    _endDate = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
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

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  // 4. ATUALIZADO: Partilha por Turno (Req #3)
  Future<void> _compartilharTurno(Turno turno) async {
    setState(() {
      _isSharingTurno = true;
      _turnoBeingShared = turno;
    });

    try {
      // Reutiliza a função principal do ShareService
      await ShareService.instance.gerarECompartilharRelatorio(turno);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro: ${e.toString().replaceAll("Exception: ", "")}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingTurno = false;
          _turnoBeingShared = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Histórico Geral")),
      body: Column(
        children: [
          _buildFilterBar(),

          Expanded(
            // 5. ATUALIZADO: Ouve a caixa de Turnos (e Leituras)
            child: ValueListenableBuilder(
              valueListenable: HiveService.instance.turnosBox.listenable(),
              builder: (context, Box<Turno> turnosBox, _) {
                // 6. FILTRA OS TURNOS pela data
                List<Turno> filteredTurnos = turnosBox.values.toList();

                if (_startDate != null && _endDate != null) {
                  filteredTurnos = filteredTurnos.where((turno) {
                    final data = turno.dataHoraInicio;
                    return (data.isAfter(_startDate!) ||
                            data.isAtSameMomentAs(_startDate!)) &&
                        (data.isBefore(_endDate!) ||
                            data.isAtSameMomentAs(_endDate!));
                  }).toList();
                }

                // Ordena (mais recente primeiro)
                filteredTurnos.sort(
                  (a, b) => b.dataHoraInicio.compareTo(a.dataHoraInicio),
                );

                final Map<String, String> nomesViveiros = {
                  for (var v in _listaDeViveiros) v.id: v.nome,
                };

                if (filteredTurnos.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum turno encontrado neste período.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // 7. CONSTRÓI A LISTA DE TURNOS
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTurnos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final turno = filteredTurnos[index];

                    return _buildTurnoGroup(context, turno, nomesViveiros);
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
    // ... (O código desta função permanece idêntico)
    final bool isDateFilterActive = _startDate != null;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: Text(
                    isDateFilterActive
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

              Visibility(
                visible: isDateFilterActive,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.cancel_rounded),
                    color: Theme.of(context).colorScheme.error, // Vermelho
                    tooltip: "Limpar filtro de data",
                    onPressed: _clearDateFilter,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildViveiroFilterDropdown(),
        ],
      ),
    );
  }

  Widget _buildViveiroFilterDropdown() {
    // ... (O código desta função permanece idêntico)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Tanque>(
          value: _filtroViveiroSelecionado,
          hint: const Text(
            "Filtrar por Viveiro (Todos)",
            style: TextStyle(color: Colors.black54),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            const DropdownMenuItem<Tanque>(
              value: null,
              child: Text(
                "Todos os Viveiros",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            ..._listaDeViveiros.map((Tanque tanque) {
              return DropdownMenuItem<Tanque>(
                value: tanque,
                child: Text(tanque.nome),
              );
            }).toList(),
          ],
          onChanged: (Tanque? newValue) {
            setState(() {
              _filtroViveiroSelecionado = newValue;
            });
          },
        ),
      ),
    );
  }

  // 8. REMOVIDO: _groupReadingsByDay

  // 9. REFEITO: _buildDayGroup -> _buildTurnoGroup
  Widget _buildTurnoGroup(
    BuildContext context,
    Turno turno,
    Map<String, String> nomesViveiros,
  ) {
    // 10. Busca leituras E aplica o filtro de viveiro
    List<Leitura> readingsForTurno = HiveService.instance.getLeiturasPorTurno(
      turno,
    );

    if (_filtroViveiroSelecionado != null) {
      readingsForTurno = readingsForTurno
          .where((l) => l.idTanque == _filtroViveiroSelecionado!.id)
          .toList();
    }

    // 11. Se o filtro de viveiro removeu todas as leituras, não mostra este turno
    if (readingsForTurno.isEmpty) {
      return const SizedBox.shrink(); // Não renderiza nada
    }

    final bool isThisTurnoLoading =
        _isSharingTurno && _turnoBeingShared == turno;

    // Cabeçalho do Turno
    final String inicioFormatado = _turnoHeaderFormatter.format(
      turno.dataHoraInicio,
    );
    final String fimFormatado = turno.dataHoraFim != null
        ? _turnoHeaderFormatter.format(turno.dataHoraFim!)
        : "Em Andamento";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Título do Turno
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Turno", // Título Fixo
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  "$inicioFormatado - $fimFormatado", // Datas
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),

            // Botão de Partilha do Turno
            isThisTurnoLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).primaryColor.withOpacity(0.8),
                    ),
                    tooltip: "Partilhar este turno",
                    // 12. ATUALIZADO: Chama _compartilharTurno
                    onPressed: _isSharingTurno
                        ? null
                        : () => _compartilharTurno(turno),
                  ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: readingsForTurno.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reading = readingsForTurno[index];
            return _buildHistoryCard(reading, nomesViveiros);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Leitura reading, Map<String, String> nomesViveiros) {
    // ... (O código desta função permanece idêntico)
    final nomeViveiro =
        nomesViveiros[reading.idTanque] ?? 'ID: ${reading.idTanque}';

    return Card(
      elevation: 1,
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_filled_rounded,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              _timeFormatter.format(reading.dataHora),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),

        title: Text(
          "O₂: ${reading.oxigenio.toStringAsFixed(1)} mg/L  |  Temp: ${reading.temperatura.toStringAsFixed(1)} °C",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 15,
          ),
        ),

        subtitle: Text(
          nomeViveiro,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
