// lib/screens/preview_screen.dart
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

      // Analizar el texto para obtener datos estructurados
      final receiptData = await ocrService.analyzeReceipt(extractedText);

      // Validar que los datos necesarios estén presentes
      bool isDataValid = _validateReceiptData(receiptData);

      setState(() {
        _extractedText = extractedText;

        if (isDataValid) {
          // Crear el objeto Receipt con los datos extraídos
          _receipt = Receipt(
            banco: 'Banco del Barrio | Banco Guayaquil',
            fecha: receiptData['fecha'] ?? '',
            hora: receiptData['hora'] ?? '',
            tipo: receiptData['tipo'] ?? 'Pago de Servicio',
            nroTransaccion: receiptData['nro_transaccion'] ?? '',
            nroControl: receiptData['nro_control'] ?? '',
            local: receiptData['local'] ?? '',
            fechaAlternativa: receiptData['fecha_alternativa'] ?? '',
            corresponsal: receiptData['corresponsal'] ?? '',
            tipoCuenta: receiptData['tipo_cuenta'] ?? '',
            valorTotal: receiptData['valor_total'] ?? 0.0,
            fullText: extractedText,
            nroAutorizacion: receiptData['nro_autorizacion'] ?? '',
            numTelefonico: receiptData['num_telefonico'] ?? '',
            ilimClaro: receiptData['ilim_claro'] ?? '',
          );
        } else {
          // No se crea el objeto Receipt si los datos no son válidos
          _receipt = null;
          // No mostrar mensaje aquí porque ya se muestra en _validateReceiptData
        }

        _isProcessing = false;
      });
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isProcessing = false;
        _extractedText = 'Error al procesar la imagen: $e';
        _receipt =
            null; // Asegurarse de que no haya un recibo parcial en caso de error
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

  // Método para validar los datos del comprobante
  bool _validateReceiptData(Map<String, dynamic> receiptData) {
    // Verificar campos obligatorios para todos los tipos
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

    // Validaciones específicas por tipo de comprobante
    String tipo = receiptData['tipo'] ?? '';

    switch (tipo) {
      case 'EFECTIVO MOVIL':
        if (receiptData['nro_autorizacion'] == null ||
            receiptData['nro_autorizacion'].isEmpty) {
          _showValidationError(
            'No se pudo detectar el número de autorización. Por favor, capture una imagen más clara.',
          );
          return false;
        }
        break;

      case 'RECARGA CLARO':
        if (receiptData['num_telefonico'] == null ||
            receiptData['num_telefonico'].isEmpty) {
          _showValidationError(
            'No se pudo detectar el número telefónico. Por favor, capture una imagen más clara.',
          );
          return false;
        }
        break;

      case 'DEPOSITO':
      case 'Pago de Servicio':
      case 'Retiro':
        // Aquí puedes agregar validaciones específicas para estos tipos
        break;
    }

    return true;
  }

  void _showValidationError(String message) {
    // Mostrar un mensaje de error al usuario
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
                                      'Error: No se pudo procesar el comprobante o los datos son incompletos.',
                                    ),
                                    backgroundColor: Colors.red,
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

                              // Establecer el contexto en el provider
                              provider.setContext(context);

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
                                // Verificar si es un error de autenticación
                                if (e.toString().contains('Sesión expirada') ||
                                    e.toString().contains('Token')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Sesión expirada. Inicie sesión nuevamente.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );

                                  // Navegar a la pantalla de login
                                  Future.delayed(Duration(seconds: 2), () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(),
                                      ),
                                    );
                                  });
                                } else {
                                  // Otro tipo de error
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                    ),
                                  );
                                }
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
    IconData bannerIcon;
    Color bannerColor;

    switch (_receipt!.tipo) {
      case 'Retiro':
        bannerIcon = Icons.money_off;
        bannerColor = Colors.orange.shade100;
        break;
      case 'EFECTIVO MOVIL':
        bannerIcon = Icons.mobile_friendly;
        bannerColor = Colors.purple.shade100;
        break;
      case 'DEPOSITO':
        bannerIcon = Icons.savings;
        bannerColor = Colors.green.shade100;
        break;
      case 'RECARGA CLARO':
        bannerIcon = Icons.phone_android;
        bannerColor = Colors.red.shade100;
        break;
      default: // Pago de Servicio u otros
        bannerIcon = Icons.payment;
        bannerColor = Colors.blue.shade100;
    }

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

            // Campos comunes para todos los comprobantes
            _buildInfoRow('Banco', _receipt!.banco),
            _buildInfoRow('Fecha', _receipt!.fecha),
            _buildInfoRow('Hora', _receipt!.hora),
            _buildInfoRow(
              'Nro. Transacción',
              _receipt!.nroTransaccion.isEmpty
                  ? 'No detectado'
                  : _receipt!.nroTransaccion,
            ),

            // Campos condicionales según el tipo de comprobante
            if (_receipt!.tipo == 'Pago de Servicio' ||
                _receipt!.tipo == 'Retiro' ||
                _receipt!.tipo == 'DEPOSITO')
              _buildInfoRow(
                'Nro. Control',
                _receipt!.nroControl.isEmpty
                    ? 'No detectado'
                    : _receipt!.nroControl,
              ),

            if (_receipt!.tipo == 'Pago de Servicio' ||
                _receipt!.tipo == 'Retiro')
              _buildInfoRow('Local', _receipt!.local),

            _buildInfoRow('Corresponsal', _receipt!.corresponsal),

            if (_receipt!.tipo == 'Pago de Servicio' ||
                _receipt!.tipo == 'Retiro')
              _buildInfoRow('Tipo de Cuenta', _receipt!.tipoCuenta),

            if (_receipt!.tipo == 'EFECTIVO MOVIL' &&
                _receipt!.nroAutorizacion.isNotEmpty)
              _buildInfoRow('Nro. Autorización', _receipt!.nroAutorizacion),

            // El bloque problemático - RECARGA CLARO
            if (_receipt!.tipo == 'RECARGA CLARO' &&
                _receipt!.ilimClaro.isNotEmpty)
              _buildInfoRow('Ilim. Claro', _receipt!.ilimClaro),

            if (_receipt!.tipo == 'RECARGA CLARO' &&
                _receipt!.numTelefonico.isNotEmpty)
              _buildInfoRow('Núm. Telefónico', _receipt!.numTelefonico),

            if (_receipt!.fechaAlternativa.isNotEmpty)
              _buildInfoRow('Fecha Alt.', _receipt!.fechaAlternativa),

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
