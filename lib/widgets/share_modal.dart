import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monitor_viveiro/services/share_service.dart';
// Assegure-se que o nome do pacote 'monitor_viveiros' está correto

class ShareModal extends StatefulWidget {
  const ShareModal({super.key});

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  // Define o período padrão (hoje)
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  // Função para abrir o DatePicker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020), // Data mínima
      lastDate: DateTime.now(), // Data máxima (hoje)
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Garante que a data final não seja anterior à inicial
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          // Garante que a data inicial não seja posterior à final
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  // Função para gerar e partilhar
  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // 1. Chamar o serviço para gerar e partilhar o relatório
      await ShareService.instance.gerarECompartilharRelatorio(
        _startDate,
        _endDate,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Fecha o modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Remove "Exception: " da mensagem de erro
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
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Text(
        "Compartilhar Relatório",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Selecione o intervalo de datas para gerar o relatório."),
          const SizedBox(height: 24),
          // Seletor de Data Inicial
          _buildDatePicker(
            context: context,
            label: "Data Inicial",
            date: _startDate,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 16),
          // Seletor de Data Final
          _buildDatePicker(
            context: context,
            label: "Data Final",
            date: _endDate,
            onTap: () => _selectDate(context, false),
          ),
          const SizedBox(height: 24),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              // O botão de partilhar não deve ter o texto "Compartilhar" se estiver em loading
              : const Icon(Icons.share, size: 20),
          label: Text(_isGenerating ? "" : "Partilhar"),
          onPressed: _isGenerating ? null : _generateReport,
          style: ElevatedButton.styleFrom(
            // Garante que o botão não mude de tamanho
            minimumSize: const Size(110, 40),
            padding: _isGenerating ? const EdgeInsets.all(10) : null,
          ),
        ),
      ],
    );
  }

  // Widget auxiliar para o seletor de data
  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormatter.format(date),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
