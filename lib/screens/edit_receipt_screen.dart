import 'package:flutter/material.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';

class EditReceiptScreen extends StatefulWidget {
  final Receipt receipt;
  
  EditReceiptScreen({required this.receipt});

  @override
  _EditReceiptScreenState createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fechaController;
  late TextEditingController _horaController;
  late TextEditingController _transaccionController;
  late TextEditingController _valorController;
  
  String _selectedTipo = 'PAGO DE SERVICIO';
  bool _isLoading = false;
  
  final List<String> _tiposComprobante = [
    'PAGO DE SERVICIO',
    'DEPOSITO',
    'RETIRO',
    'EFECTIVO MOVIL',
    'RECARGA CLARO',
    'ENVIO GIRO',
    'PAGO GIRO',
  ];

  @override
  void initState() {
    super.initState();
    _fechaController = TextEditingController(text: widget.receipt.fecha);
    _horaController = TextEditingController(text: widget.receipt.hora);
    _transaccionController = TextEditingController(text: widget.receipt.nroTransaccion);
    _valorController = TextEditingController(text: widget.receipt.valorTotal.toString());
    _selectedTipo = widget.receipt.tipo;
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _horaController.dispose();
    _transaccionController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      
      final editData = {
        'fecha': _fechaController.text.trim(),
        'hora': _horaController.text.trim(),
        'tipo': _selectedTipo,
        'nro_transaccion': _transaccionController.text.trim(),
        'valor_total': double.parse(_valorController.text.trim()),
      };

      final success = await apiService.editReceipt(widget.receipt.nroTransaccion, editData);

      if (success) {
        // Recargar la lista de comprobantes
        final receiptsProvider = Provider.of<ReceiptsProvider>(context, listen: false);
        await receiptsProvider.loadReceipts();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Comprobante editado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al editar el comprobante'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('✏️ Editar Comprobante'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Título
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.edit_document, size: 48, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'Editar Información del Comprobante',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),

              // Fecha
              TextFormField(
                controller: _fechaController,
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  hintText: 'dd/mm/yyyy',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La fecha es requerida';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Hora
              TextFormField(
                controller: _horaController,
                decoration: InputDecoration(
                  labelText: 'Hora',
                  hintText: 'hh:mm:ss',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La hora es requerida';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Tipo (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: InputDecoration(
                  labelText: 'Tipo de Comprobante',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _tiposComprobante.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTipo = value!;
                  });
                },
              ),

              SizedBox(height: 16),

              // Número de Transacción
              TextFormField(
                controller: _transaccionController,
                decoration: InputDecoration(
                  labelText: 'Número de Transacción',
                  prefixIcon: Icon(Icons.receipt_long),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de transacción es requerido';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Valor Total
              TextFormField(
                controller: _valorController,
                decoration: InputDecoration(
                  labelText: 'Valor Total',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.monetization_on),
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El valor total es requerido';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Ingrese un valor numérico válido';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('💾 Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}