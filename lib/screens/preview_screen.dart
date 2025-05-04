// lib/screens/preview_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:riocaja_smart/services/ocr_service.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  PreviewScreen({required this.imagePath});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isProcessing = true;
  String _extractedText = '';
  Receipt? _receipt;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() => _isProcessing = true);

      // Usar el servicio OCR
      final ocrService = OcrService();

      // Extraer texto de la imagen
      final extractedText = await ocrService.extractText(widget.imagePath);

      // Detectar el tipo directamente en el texto
      String tipoComprobante = 'Pago de Servicio'; // valor por defecto
      
      // Comprobar si contiene la palabra RETIRO
      if (extractedText.toUpperCase().contains('RETIRO')) {
        tipoComprobante = 'Retiro';
      }

      // Analizar el texto para obtener datos estructurados
      final receiptData = await ocrService.analyzeReceipt(extractedText);

      setState(() {
        _extractedText = extractedText;

        // Crear el objeto Receipt con los datos extraídos y el tipo detectado
        _receipt = Receipt(
          banco: 'Banco del Barrio | Banco Guayaquil',
          fecha: receiptData['fecha'] ?? '',
          hora: receiptData['hora'] ?? '',
          tipo: tipoComprobante, // Usar el tipo detectado directamente
          nroTransaccion: receiptData['nro_transaccion'] ?? '',
          nroControl: receiptData['nro_control'] ?? '',
          local: receiptData['local'] ?? '',
          fechaAlternativa: receiptData['fecha_alternativa'] ?? '',
          corresponsal: receiptData['corresponsal'] ?? '',
          tipoCuenta: receiptData['tipo_cuenta'] ?? '',
          valorTotal: receiptData['valor_total'] ?? 0.0,
          fullText: extractedText,
        );

        _isProcessing = false;
      });
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isProcessing = false;
        _extractedText = 'Error al procesar la imagen: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Revisar Comprobante')),
      body:
          _isProcessing
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Procesando imagen...'),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen capturada
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(widget.imagePath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Datos extraídos
                    Text(
                      'Información Extraída',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildExtractionResult(),

                    SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Volver a Capturar'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_receipt == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error: No se pudo procesar el comprobante',
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Agregar código de depuración aquí
                              final receiptJson = _receipt!.toJson();
                              print(
                                'Datos a enviar: ${jsonEncode(receiptJson)}',
                              );

                              // Usar el provider para guardar el comprobante en el backend
                              final provider = Provider.of<ReceiptsProvider>(
                                context,
                                listen: false,
                              );

                              try {
                                final success = await provider.addReceipt(
                                  _receipt!,
                                );

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Comprobante guardado exitosamente',
                                      ),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                  Navigator.of(
                                    context,
                                  ).pop(); // Volver a la pantalla de inicio
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al guardar el comprobante',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                  ),
                                );
                              }
                            },
                            child: Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildExtractionResult() {
    if (_receipt == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(_extractedText),
      );
    }

    // Determinar color e icono según el tipo de comprobante
    final bool isRetiro = _receipt!.tipo == 'Retiro';
    final Color bannerColor = isRetiro ? Colors.orange.shade100 : Colors.blue.shade100;
    final IconData bannerIcon = isRetiro ? Icons.money_off : Icons.payment;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner principal con el tipo detectado
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(bannerIcon, size: 24),
                  SizedBox(width: 12),
                  Text(
                    _receipt!.tipo, // Mostrar directamente el tipo detectado
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            
            _buildInfoRow('Banco', _receipt!.banco),
            _buildInfoRow('Fecha', _receipt!.fecha),
            _buildInfoRow('Hora', _receipt!.hora),
            _buildInfoRow(
              'Nro. Transacción',
              _receipt!.nroTransaccion.isEmpty
                  ? 'No detectado'
                  : _receipt!.nroTransaccion,
            ),
            _buildInfoRow(
              'Nro. Control',
              _receipt!.nroControl.isEmpty
                  ? 'No detectado'
                  : _receipt!.nroControl,
            ),
            _buildInfoRow('Local', _receipt!.local),
            if (_receipt!.fechaAlternativa.isNotEmpty)
              _buildInfoRow('Fecha Alt.', _receipt!.fechaAlternativa),
            _buildInfoRow('Corresponsal', _receipt!.corresponsal),
            _buildInfoRow('Tipo de Cuenta', _receipt!.tipoCuenta),
            _buildInfoRow(
              'Valor Total',
              '\$${_receipt!.valorTotal.toStringAsFixed(2)}',
            ),

            // Mostrar información extraída y texto original para depuración
            SizedBox(height: 16),
            ExpansionTile(
              title: Text(
                'Ver texto completo',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_receipt!.fullText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}