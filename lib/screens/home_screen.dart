// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
// import 'package:monitor_viveiro/models/turno_model.dart'; // Não é mais gerido aqui
import 'package:monitor_viveiro/services/hive_service.dart';
import 'package:monitor_viveiro/services/share_service.dart'; // 1. IMPORTAR SHARE_SERVICE
import 'package:monitor_viveiro/widgets/add_tank_modal.dart';
import 'package:monitor_viveiro/screens/history_screen.dart';
// import 'package:monitor_viveiro/widgets/share_modal.dart'; // 2. REMOVIDO (Não usamos mais o modal)
import 'package:monitor_viveiro/widgets/new_reading_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  // 3. REMOVIDO: Toda a lógica de turno manual
  // (_activeTurno, initState, _loadActiveTurno, _toggleTurno)

  // 4. ESTADO DE LOADING PARA PARTILHA
  bool _isSharing = false;

  void _abrirModalAdicionarTanque({Tanque? tanqueParaEditar}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTankModal(tanqueParaEditar: tanqueParaEditar);
      },
    );
  }

  void _abrirModalNovaLeitura(Tanque viveiro) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NewReadingModal(viveiro: viveiro);
      },
    );
  }

  // 5. ATUALIZADO: Lógica do botão "Compartilhar Turno Vigente"
  Future<void> _compartilharTurnoVigente() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // 1. Busca o turno atual (ou cria-o se for o 1º acesso)
      // (Ex: Se for 15:45, isto retorna o turno que começou às 12:00)
      final turnoAtual = await HiveService.instance.getOrCreateTurnoAtual();

      // 2. Chama o serviço de partilha
      await ShareService.instance.gerarECompartilharRelatorio(turnoAtual);
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
          _isSharing = false;
        });
      }
    }
  }

  void _navegarParaHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  // (Funções _showTankOptions e _confirmarExclusao permanecem idênticas)
  void _showTankOptions(BuildContext context, Tanque tanque) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(tanque.nome),
          content: const Text("O que você gostaria de fazer?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Editar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _abrirModalAdicionarTanque(tanqueParaEditar: tanque);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text("EXCLUIR"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmarExclusao(context, tanque);
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmarExclusao(BuildContext context, Tanque tanque) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: Text(
            "Deseja realmente excluir o viveiro \"${tanque.nome}\"?\n\nTodas as leituras de histórico associadas a ele serão perdidas permanentemente.",
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text("Sim, Excluir"),
              onPressed: () {
                try {
                  HiveService.instance.deleteTank(tanque);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("\"${tanque.nome}\" foi excluído."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro ao excluir: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 6. REMOVIDO: Lógica de 'isTurnoAtivo'

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 20), // Espaço ajustado
            // 7. REMOVIDO: Botão "Iniciar/Encerrar Turno"
            ValueListenableBuilder(
              valueListenable: HiveService.instance.getLeiturasListenable(),
              builder: (context, Box<Leitura> leiturasBox, _) {
                final hoje = DateTime.now();
                final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
                final leiturasDeHoje = leiturasBox.values
                    .where((l) => l.dataHora.isAfter(inicioDoDia))
                    .toList();

                return Column(
                  children: [
                    _buildActionButtons(), // Simplificado
                    const SizedBox(height: 32),
                    _buildTankList(leiturasDeHoje), // Simplificado
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.opacity,
              color: Theme.of(context).primaryColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              "Monitor de Viveiros",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              "Controle de oxigênio e temperatura",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: Theme.of(context).primaryColor,
          ),
          iconSize: 30,
          tooltip: "Adicionar Viveiro",
          onPressed: () => _abrirModalAdicionarTanque(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.history_rounded),
          label: const Text("Ver Histórico Geral"),
          onPressed: _navegarParaHistorico,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share_outlined),
          label: const Text("Compartilhar Turno Vigente"),
          onPressed: _isSharing ? null : _compartilharTurnoVigente,
        ),
      ],
    );
  }

  Widget _buildTankList(List<Leitura> leiturasDeHoje) {
    return ValueListenableBuilder(
      valueListenable: HiveService.instance.getTanquesListenable(),
      builder: (context, Box<Tanque> tanquesBox, _) {
        final tanques = HiveService.instance.getTodosTanques();

        if (tanques.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                "Nenhum viveiro cadastrado.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texto fixo
            const Text(
              "Clique no viveiro para registrar:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tanques.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final tanque = tanques[index];
                final leiturasTanqueHoje = leiturasDeHoje
                    .where((l) => l.idTanque == tanque.id)
                    .toList();

                Leitura? ultimaLeitura;
                if (leiturasTanqueHoje.isNotEmpty) {
                  leiturasTanqueHoje.sort(
                    (a, b) => b.dataHora.compareTo(a.dataHora),
                  );
                  ultimaLeitura = leiturasTanqueHoje.first;
                }

                return _buildTankCard(
                  tanque: tanque,
                  readingsToday: leiturasTanqueHoje.length,
                  lastReading: ultimaLeitura,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTankCard({
    required Tanque tanque,
    required int readingsToday,
    Leitura? lastReading,
  }) {
    return Card(
      child: InkWell(
        // Sempre ativo
        onTap: () => _abrirModalNovaLeitura(tanque),
        onLongPress: () => _showTankOptions(context, tanque),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tanque.nome,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: readingsToday > 0
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      readingsToday.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: readingsToday > 0
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              lastReading == null
                  ? _buildNoReadingsView()
                  : _buildLastReadingView(lastReading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoReadingsView() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.opacity_outlined, size: 32, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            "Sem leituras hoje",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildLastReadingView(Leitura reading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildReadingInfo(
          icon: Icons.access_time_filled_rounded,
          label: "Hora",
          value: _timeFormatter.format(reading.dataHora),
        ),
        _buildReadingInfo(
          icon: Icons.air_rounded,
          label: "O₂",
          value: "${reading.oxigenio.toStringAsFixed(1)} mg/L",
        ),
        _buildReadingInfo(
          icon: Icons.thermostat_rounded,
          label: "Temp",
          value: "${reading.temperatura.toStringAsFixed(1)} °C",
        ),
      ],
    );
  }

  Widget _buildReadingInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
