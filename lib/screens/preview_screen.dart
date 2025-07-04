// lib/screens/preview_screen.dart - VERSIÓN COMPLETA SIMPLIFICADA
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:riocaja_smart/services/ocr_service.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

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
    // Verificar autenticación
    _checkAuthentication();
    _processImage();
  }

  // Método para verificar autenticación
  void _checkAuthentication() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      // Si no está autenticado, redirigir a login
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }
  }

  Future<void> _processImage() async {
    try {
      setState(() => _isProcessing = true);

      // Usar el servicio OCR
      final ocrService = OcrService();

      // Extraer texto de la imagen
      final extractedText = await ocrService.extractText(widget.imagePath);

      // Analizar el texto para obtener datos estructurados (SIMPLIFICADO)
      final receiptData = await ocrService.analyzeReceipt(extractedText);

      // Validar que los datos básicos estén presentes
      bool isDataValid = _validateReceiptData(receiptData);

      setState(() {
        _extractedText = extractedText;

        if (isDataValid) {
          // Crear el objeto Receipt SIMPLIFICADO con solo los campos básicos
          _receipt = Receipt(
            fecha: receiptData['fecha'] ?? '',
            hora: receiptData['hora'] ?? '',
            tipo: receiptData['tipo'] ?? 'PAGO DE SERVICIO',
            nroTransaccion: receiptData['nro_transaccion'] ?? '',
            valorTotal: receiptData['valor_total'] ?? 0.0,
            fullText: extractedText,
          );
        } else {
          // No se crea el objeto Receipt si los datos no son válidos
          _receipt = null;
        }

        _isProcessing = false;
      });
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isProcessing = false;
        _extractedText = 'Error al procesar la imagen: $e';
        _receipt = null;
      });

      // Mostrar un mensaje de error genérico
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al procesar la imagen. Por favor, intente nuevamente.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método SIMPLIFICADO para validar los datos del comprobante
  bool _validateReceiptData(Map<String, dynamic> receiptData) {
    // Solo verificar campos básicos obligatorios
    if (receiptData['nro_transaccion'] == null ||
        receiptData['nro_transaccion'].isEmpty) {
      _showValidationError(
        'No se pudo detectar el número de transacción. Por favor, capture una imagen más clara.',
      );
      return false;
    }

    if (receiptData['fecha'] == null || receiptData['fecha'].isEmpty) {
      _showValidationError(
        'No se pudo detectar la fecha. Por favor, capture una imagen más clara.',
      );
      return false;
    }

    if (receiptData['valor_total'] == null ||
        receiptData['valor_total'] == 0.0) {
      _showValidationError(
        'No se pudo detectar el valor total. Por favor, capture una imagen más clara.',
      );
      return false;
    }

    // Ya no necesitamos validaciones específicas por tipo - ¡SIMPLIFICADO!
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verificar autenticación
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAuthenticated) {
      // Si no está autenticado, mostrar pantalla de error
      return Scaffold(
        appBar: AppBar(title: Text('Error de Autenticación')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Sesión no válida',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Por favor inicie sesión nuevamente'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Ir a Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Revisar Comprobante')),
      body: _isProcessing
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

                  // Datos extraídos SIMPLIFICADOS
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
                          onPressed: _saveReceipt, // Usar el nuevo método
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

  // Método SIMPLIFICADO para mostrar los resultados
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

    // Obtener icono y color según el tipo
    IconData bannerIcon = _getIconForType(_receipt!.tipo);
    Color bannerColor = _getColorForType(_receipt!.tipo);

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
                    _receipt!.tipo,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),

            // SOLO LOS 5 CAMPOS BÁSICOS - ¡SIMPLIFICADO!
            _buildInfoRow('Fecha', _receipt!.fecha),
            _buildInfoRow('Hora', _receipt!.hora),
            _buildInfoRow('Tipo', _receipt!.tipo),
            _buildInfoRow(
              'Nro. Transacción',
              _receipt!.nroTransaccion.isEmpty ? 'No detectado' : _receipt!.nroTransaccion,
            ),
            _buildInfoRow(
              'Valor Total',
              '\$${_receipt!.valorTotal.toStringAsFixed(2)}',
            ),

            SizedBox(height: 16),

            // Texto completo expandible
            ExpansionTile(
              title: Text(
                'Ver texto completo escaneado',
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
                  child: Text(
                    _receipt!.fullText,
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
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

  // Métodos auxiliares para iconos y colores
  IconData _getIconForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return Icons.money_off;
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return Icons.mobile_friendly;
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return Icons.savings;
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return Icons.send;
      case 'PAGO GIRO':
        return Icons.receipt;
      default: // PAGO DE SERVICIO y otros
        return Icons.payment;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return Colors.orange.shade100;
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return Colors.purple.shade100;
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return Colors.green.shade100;
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return Colors.indigo.shade100;
      case 'PAGO GIRO':
        return Colors.teal.shade100;
      default: // PAGO DE SERVICIO y otros
        return Colors.blue.shade100;
    }
  }

  // Reemplaza el botón de guardar actual con este método separado
  Future<void> _saveReceipt() async {
    if (_receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: No hay datos del comprobante para guardar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ NUEVA VALIDACIÓN CRÍTICA
    if (_receipt!.nroTransaccion.isEmpty) {
      // Mostrar diálogo para que el usuario ingrese manualmente
      String? manualNumber = await _showManualTransactionDialog();
      
      if (manualNumber == null || manualNumber.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Se requiere un número de transacción válido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Crear nuevo receipt con el número manual
      _receipt = Receipt(
        fecha: _receipt!.fecha,
        hora: _receipt!.hora,
        tipo: _receipt!.tipo,
        nroTransaccion: manualNumber.trim(),
        valorTotal: _receipt!.valorTotal,
        fullText: _receipt!.fullText,
      );
    }

    // ✅ VALIDACIÓN ADICIONAL: Evitar números sospechosos
    if (_receipt!.nroTransaccion.length > 12 || 
        _receipt!.nroTransaccion.startsWith('17') || 
        _receipt!.nroTransaccion.startsWith('16')) {
      
      bool? confirmSave = await _showConfirmSuspiciousNumberDialog(_receipt!.nroTransaccion);
      
      if (confirmSave != true) {
        return; // Usuario canceló
      }
    }

    // Debug log
    final receiptJson = _receipt!.toJson();
    print('💾 Datos a enviar: ${jsonEncode(receiptJson)}');

    // Usar el provider para guardar el comprobante en el backend
    final provider = Provider.of<ReceiptsProvider>(context, listen: false);
    provider.setContext(context);

    try {
      final success = await provider.addReceipt(_receipt!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comprobante guardado exitosamente')),
        );
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Volver a la pantalla de inicio
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el comprobante')),
        );
      }
    } catch (e) {
      // Verificar si es un error de autenticación
      if (e.toString().contains('Sesión expirada') ||
          e.toString().contains('Token')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión expirada. Inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );

        // Navegar a la pantalla de login
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // NUEVO: Diálogo para ingreso manual de número de transacción
  Future<String?> _showManualTransactionDialog() async {
    TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('⚠️ Número de Transacción Requerido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudo detectar automáticamente el número de transacción. '
                'Por favor, ingrésalo manualmente desde el comprobante físico.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número de Transacción',
                  hintText: 'Ej: 203901776',
                  border: OutlineInputBorder(),
                ),
                maxLength: 12,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                String number = controller.text.trim();
                if (number.isNotEmpty && number.length >= 4) {
                  Navigator.of(context).pop(number);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ingrese un número válido (mínimo 4 dígitos)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // NUEVO: Diálogo de confirmación para números sospechosos
  Future<bool?> _showConfirmSuspiciousNumberDialog(String number) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🤔 Número Sospechoso Detectado'),
          content: Text(
            'El número detectado "$number" parece ser generado automáticamente. '
            '¿Estás seguro de que este es el número correcto del comprobante?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(false);
                // Abrir diálogo para ingresar manualmente
                String? manualNumber = await _showManualTransactionDialog();
                if (manualNumber != null) {
                  // Actualizar el receipt con el número manual
                  _receipt = Receipt(
                    fecha: _receipt!.fecha,
                    hora: _receipt!.hora,
                    tipo: _receipt!.tipo,
                    nroTransaccion: manualNumber.trim(),
                    valorTotal: _receipt!.valorTotal,
                    fullText: _receipt!.fullText,
                  );
                  setState(() {}); // Refrescar UI
                }
              },
              child: Text('Corregir'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Usar Este Número'),
            ),
          ],
        );
      },
    );
  }
}