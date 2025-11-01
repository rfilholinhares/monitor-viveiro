import 'package:flutter/material.dart';
import 'package:monitor_viveiro/models/tanque_model.dart';
import 'package:monitor_viveiro/services/hive_service.dart';
// Assegure-se que o nome do pacote 'monitor_viveiros' está correto

class AddTankModal extends StatefulWidget {
  final Tanque? tanqueParaEditar;

  const AddTankModal({super.key, this.tanqueParaEditar});

  @override
  State<AddTankModal> createState() => _AddTankModalState();
}

class _AddTankModalState extends State<AddTankModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false; // Para controlar o estado de loading do botão

  @override
  void initState() {
    super.initState();
    if (widget.tanqueParaEditar != null) {
      _nameController.text = widget.tanqueParaEditar!.nome;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final nome = _nameController.text;

      try {
        // Lógica de Edição
        if (widget.tanqueParaEditar != null) {
          await HiveService.instance.updateTank(widget.tanqueParaEditar!, nome);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Viveiro atualizado com sucesso!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        // Lógica de Adição
        else {
          await HiveService.instance.addTanque(nome);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Viveiro adicionado com sucesso!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Se o HiveService der um erro (ex: nome duplicado)
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Erro ao salvar: ${e.toString().replaceAll("Exception: ", "")}",
              ),
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
        "Adicionar Novo Viveiro",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      // Usamos o Form para validação
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Para o modal se ajustar
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Nome do Viveiro",
                hintText: "Ex: Viveiro 6",
                prefixIcon: Icon(Icons.label_important_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'O nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 24), // Espaço antes dos botões
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      // Botões de ação
      actions: [
        // Botão de Cancelar
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        // Botão de Salvar
        ElevatedButton(
          onPressed: _isSaving ? null : _submitForm,
          child: _isSaving
              // Mostra um loading enquanto salva
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Salvar"),
        ),
      ],
    );
  }
}
