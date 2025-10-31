import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monitor_viveiro/models/leitura_model.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
import 'package:monitor_viveiro/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class NewReadingModal extends StatefulWidget {
  const NewReadingModal({super.key});

  @override
  State<NewReadingModal> createState() => _NewReadingModalState();
}

class _NewReadingModalState extends State<NewReadingModal> {
  // Lista de tanques virá do Hive
  List<Tanque> _tanks = [];

  // Agora selecionamos o objeto Tanque inteiro
  Tanque? _selectedTank;
  final _oxygenController = TextEditingController();
  final _tempController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Gerador de UUID
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadTanks();
  }

  // Busca os tanques do HiveService
  void _loadTanks() {
    setState(() {
      _tanks = HiveService.instance.getTodosTanques();
    });
  }

  @override
  void dispose() {
    _oxygenController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  // ATUALIZADO: Salva no HIVE
  Future<void> _submitForm() async {
    // Valida o formulário
    if (_formKey.currentState!.validate()) {
      if (_selectedTank == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor, selecione um tanque."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Se tudo estiver OK, colete os dados (tratando vírgula e ponto)
      final oxigenio = double.tryParse(
        _oxygenController.text.replaceAll(',', '.'),
      );
      final temperatura = double.tryParse(
        _tempController.text.replaceAll(',', '.'),
      );

      if (oxigenio == null || temperatura == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Valores de leitura inválidos."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 1. Criar o objeto Leitura
      final novaLeitura = Leitura(
        id: _uuid.v4(), // Gera um ID único
        idTanque: _selectedTank!.id,
        dataHora: DateTime.now(),
        oxigenio: oxigenio,
        temperatura: temperatura,
      );

      // 2. Salvar no Hive
      try {
        await HiveService.instance.addLeitura(novaLeitura);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Leitura registrada com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
          // Fecha o modal
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Erro ao salvar no Hive: $e");
        }
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
              _buildDropdown(),
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

  // ATUALIZADO: Dropdown agora usa List<Tanque>
  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Selecione o Tanque",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Tanque>(
          // Usa o tipo Tanque
          value: _selectedTank,
          hint: Text(
            "Escolha um tanque",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          // Itens baseados na lista do Hive
          items: _tanks.map((Tanque tanque) {
            return DropdownMenuItem<Tanque>(
              value: tanque,
              child: Text(tanque.nome),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedTank = newValue;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) => value == null ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }

  // Bloco 2: Oxigênio (Validação melhorada)
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: "Exc: 6.5",
            prefixIcon: Icon(Icons.air_rounded, color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Valor inválido. Use ponto (ex: 6.5)';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Bloco 3: Temperatura (Validação melhorada)
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: "Exc: 28.5",
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
              return 'Valor inválido. Use ponto (ex: 28.5)';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Bloco 4: Botão de Registrar
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
