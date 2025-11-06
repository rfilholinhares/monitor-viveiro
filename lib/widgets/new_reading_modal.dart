import 'package:flutter/material.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
import 'package:monitor_viveiro/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class NewReadingModal extends StatefulWidget {
  final Tanque viveiro;

  const NewReadingModal({super.key, required this.viveiro});

  @override
  State<NewReadingModal> createState() => _NewReadingModalState();
}

class _NewReadingModalState extends State<NewReadingModal> {
  final _oxygenController = TextEditingController();
  final _tempController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _oxygenController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // ATUALIZADO: Usa a lógica de turno automático 12h-a-12h
      final activeTurno = await HiveService.instance.getOrCreateTurnoAtual();

      // (Lógica do Ajuste #3 - Máscara)
      double? formatarValor(String rawValue) {
        if (rawValue.isEmpty) return null;
        final valorLimpo = rawValue.replaceAll(',', '.');
        if (valorLimpo.contains('.')) {
          return double.tryParse(valorLimpo);
        }
        final valorInt = double.tryParse(valorLimpo);
        if (valorInt != null) {
          return valorInt / 10.0;
        }
        return null;
      }

      final oxigenio = formatarValor(_oxygenController.text);
      final temperatura = formatarValor(_tempController.text);

      if (oxigenio == null || temperatura == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Valores de leitura inválidos."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final novaLeitura = Leitura(
        id: _uuid.v4(),
        idTanque: widget.viveiro.id,
        dataHora: DateTime.now(),
        oxigenio: oxigenio,
        temperatura: temperatura,
        idTurno: activeTurno.id,
      );

      try {
        await HiveService.instance.addLeitura(novaLeitura);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Leitura registrada com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao salvar: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Text(
        "Nova Leitura",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildViveiroInfo(),
              const SizedBox(height: 20),
              _buildOxygenInput(),
              const SizedBox(height: 20),
              _buildTemperatureInput(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      actionsPadding: EdgeInsets.zero,
    );
  }

  Widget _buildViveiroInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Viveiro Selecionado",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            widget.viveiro.nome,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOxygenInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Oxigênio (mg/L)",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _oxygenController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Ex: 65 (para 6.5) ou 285 (para 28.5)",
            prefixIcon: Icon(Icons.air_rounded, color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Valor inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTemperatureInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Temperatura (°C)",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tempController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Ex: 285 (para 28.5)",
            prefixIcon: Icon(
              Icons.thermostat_rounded,
              color: Colors.grey.shade600,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Valor inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: _submitForm,
      child: const Text("Registrar Leitura"),
    );
  }
}
