// lib/screens/improved_preview_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:riocaja_smart/services/enhanced_ocr_service.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';

class ImprovedPreviewScreen extends StatefulWidget {
  final String imagePath;

  ImprovedPreviewScreen({required this.imagePath});

  @override
  _ImprovedPreviewScreenState createState() => _ImprovedPreviewScreenState();
}

class _ImprovedPreviewScreenState extends State<ImprovedPreviewScreen> {
  bool _isProcessing = true;
  String _extractedText = '';
  Receipt? _receipt;
  int _confidence = 0;
  String _processingStatus = 'Iniciando análisis...';

  @override
  void initState() {
    super.initState();
    _processImageEnhanced();
  }

  Future<void> _processImageEnhanced() async {
    try {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Mejorando calidad de imagen...';
      });

      final enhancedOcrService = EnhancedOcrService();

      setState(() {
        _processingStatus = 'Extrayendo texto con IA...';
      });

      // Usar el servicio OCR mejorado
      final receiptData = await enhancedOcrService.analyzeReceiptEnhanced(widget.imagePath);

      setState(() {
        _processingStatus = 'Validando información...';
      });

      // Validar calidad de los datos
      _confidence = receiptData['confidence'] ?? 0;
      bool isDataValid = _confidence >= 50; // Umbral de confianza

      setState(() {
        _extractedText = receiptData['full_text'] ?? '';

        if (isDataValid) {
          _receipt = Receipt(
            fecha: receiptData['fecha'] ?? '',
            hora: receiptData['hora'] ?? '',
            tipo: receiptData['tipo'] ?? 'PAGO DE SERVICIO',
            nroTransaccion: receiptData['nro_transaccion'] ?? '',
            valorTotal: receiptData['valor_total'] ?? 0.0,
            fullText: _extractedText,
          );
        } else {
          _receipt = null;
        }

        _isProcessing = false;
        _processingStatus = 'Completado';
      });

      // Limpiar recursos
      enhancedOcrService.dispose();

    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Error en el procesamiento';
        _extractedText = 'Error al procesar la imagen: $e';
        _receipt = null;
        _confidence = 0;
      });

      _showErrorMessage('Error al procesar la imagen. Intenta de nuevo.');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Precisión Baja'),
        content: Text(
          'La precisión del escaneo es baja (${_confidence}%). '
          '¿Deseas reintentar el escaneo o continuar de todos modos?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processImageEnhanced(); // Reintentar
            },
            child: Text('Reintentar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveReceipt(); // Continuar de todos modos
            },
            child: Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReceipt() async {
    if (_receipt == null) {
      _showErrorMessage('No hay datos válidos para guardar');
      return;
    }

    try {
      final receiptsProvider = Provider.of<ReceiptsProvider>(context, listen: false);
      await receiptsProvider.addReceipt(_receipt!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comprobante guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage('Error al guardar: $e');
    }
  }

  Color _getConfidenceColor() {
    if (_confidence >= 80) return Colors.green;
    if (_confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceText() {
    if (_confidence >= 80) return 'Excelente';
    if (_confidence >= 60) return 'Bueno';
    if (_confidence >= 40) return 'Regular';
    return 'Bajo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisar Comprobante'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? _buildProcessingView()
          : _buildResultView(),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 20),
          Text(
            _processingStatus,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Mejorando precisión con IA...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del comprobante
          _buildImagePreview(),
          SizedBox(height: 16),
          
          // Indicador de confianza
          _buildConfidenceIndicator(),
          SizedBox(height: 16),

          // Información extraída
          if (_receipt != null) _buildExtractedInfo(),
          
          // Texto completo (plegable)
          _buildFullTextSection(),
          
          SizedBox(height: 24),
          
          // Botones de acción
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getConfidenceColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getConfidenceColor()),
      ),
      child: Row(
        children: [
          Icon(
            _confidence >= 60 ? Icons.check_circle : Icons.warning,
            color: _getConfidenceColor(),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precisión del Escaneo: ${_getConfidenceText()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(),
                  ),
                ),
                Text(
                  '$_confidence% de confianza',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getConfidenceColor(),
                  ),
                ),
              ],
            ),
          ),
          if (_confidence < 60)
            TextButton(
              onPressed: _processImageEnhanced,
              child: Text('Reintentar'),
            ),
        ],
      ),
    );
  }

  Widget _buildExtractedInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Extraída',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Fecha:', _receipt!.fecha),
            _buildInfoRow('Hora:', _receipt!.hora),
            _buildInfoRow('Tipo:', _receipt!.tipo),
            _buildInfoRow('Nro. Transacción:', _receipt!.nroTransaccion),
            _buildInfoRow('Valor Total:', '\${_receipt!.valorTotal.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    bool isEmpty = value.isEmpty || value == '0.00';
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              isEmpty ? 'No detectado' : value,
              style: TextStyle(
                color: isEmpty ? Colors.red : Colors.black,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (isEmpty)
            Icon(
              Icons.warning_amber,
              size: 16,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildFullTextSection() {
    return Card(
      child: ExpansionTile(
        title: Text('Texto Completo Detectado'),
        subtitle: Text('${_extractedText.length} caracteres'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _extractedText.isEmpty ? 'No se pudo extraer texto' : _extractedText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_receipt != null && _confidence < 60)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: _showRetryDialog,
              icon: Icon(Icons.refresh),
              label: Text('Mejorar Precisión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _receipt != null ? _saveReceipt : null,
                child: Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        
        if (_receipt == null)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No se pudieron extraer datos suficientes para crear el comprobante',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}