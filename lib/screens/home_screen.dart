// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
import 'package:monitor_viveiro/screens/history_screen.dart';
import 'package:monitor_viveiro/services/hive_service.dart';
import 'package:monitor_viveiro/widgets/add_tank_modal.dart';
import 'package:monitor_viveiro/widgets/new_reading_modal.dart';
import 'package:monitor_viveiro/widgets/share_modal.dart';

// Assegure-se que o nome do pacote 'monitor_viveiros' está correto

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Formatador de hora
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  void _abrirModalAdicionarTanque({Tanque? tanqueParaEditar}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Passa o tanque (se houver) para o modal
        return AddTankModal(tanqueParaEditar: tanqueParaEditar);
      },
    );
  }

  void _abrirModalNovaLeitura() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const NewReadingModal();
      },
    );
  }

  // (RF04) ATUALIZADO: Função para abrir o modal de compartilhamento
  void _abrirModalCompartilhar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Chama o novo modal que criamos
        return const ShareModal();
      },
    );
  }

  // (RF03.4) Função para navegar para o histórico
  void _navegarParaHistorico(Tanque tanque) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Passa o objeto 'tanque' selecionado para a nova tela
        builder: (context) => HistoryScreen(tanque: tanque),
      ),
    );
  }

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
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Editar"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha este diálogo
                _abrirModalAdicionarTanque(
                  tanqueParaEditar: tanque,
                ); // Abre o modal de edição
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.error, // Cor vermelha
              ),
              child: const Text("EXCLUIR"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha este diálogo
                _confirmarExclusao(
                  context,
                  tanque,
                ); // Abre o diálogo de confirmação
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
          title: Text("Confirmar Exclusão"),
          content: Text(
            "Deseja realmente excluir o tanque \"${tanque.nome}\"?\n\nTodas as leituras de histórico associadas a ele serão perdidas permanentemente.",
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.error, // Vermelho
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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

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
                    _buildActionButtons(leiturasDeHoje.length),
                    const SizedBox(height: 32),
                    _buildTankList(leiturasDeHoje),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ATUALIZADO: _buildHeader agora tem um botão de adicionar
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna do Título e Ícone
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
              ],
            ),
            // Botão Adicionar Tanque (RF01.1)
            IconButton(
              icon: Icon(
                Icons.add_box_rounded,
                color: Theme.of(context).primaryColor,
              ),
              iconSize: 32,
              tooltip: "Adicionar Novo Tanque",
              onPressed: _abrirModalAdicionarTanque, // Chama a nova função
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Controle de oxigênio e temperatura",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildActionButtons(int totalReadingsToday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text("Nova Leitura"),
          onPressed: _abrirModalNovaLeitura,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.share_outlined),
          label: Text("Compartilhar ($totalReadingsToday)"),
          onPressed: () => _abrirModalCompartilhar(),
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
                "Nenhum tanque cadastrado.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
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
        onTap: () => _navegarParaHistorico(tanque),
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
