// lib/services/ocr_service.dart - VERSIÓN MEJORADA PARA RECARGA CLARO
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _textRecognizer = TextRecognizer();

  // Extrae todo el texto de la imagen
  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('Error extracting text: $e');
      return "Error al extraer texto: $e";
    }
  }

  // Analiza el texto para extraer SOLO los 5 campos básicos
  Future<Map<String, dynamic>> analyzeReceipt(String text) async {
    try {
      return {
        'fecha': _extractDate(text),
        'hora': _extractTime(text),
        'tipo': _determineReceiptType(text),
        'nro_transaccion': _extractTransactionNumber(text),
        'valor_total': _extractAmount(text),
        'full_text': text,
      };
    } catch (e) {
      print('Error analyzing receipt: $e');
      return {
        'fecha': '',
        'hora': '',
        'tipo': 'No Detectado',
        'nro_transaccion': '',
        'valor_total': 0.0,
        'full_text': text,
      };
    }
  }

  // MEJORADO: Determina el tipo de comprobante con mejor detección para RECARGA CLARO
  String _determineReceiptType(String text) {
    String upperText = text.toUpperCase();
    
    print('Analizando texto para determinar tipo: ${upperText.substring(0, upperText.length > 100 ? 100 : upperText.length)}...');

    // PRIORIDAD 1: RECARGA CLARO - Detectar múltiples variaciones
    if (upperText.contains("ILIM. CLARO") || 
        upperText.contains("ILIM CLARO") ||
        upperText.contains("ILIMCLARO") ||
        upperText.contains("RECARGA CLARO") ||
        (upperText.contains("RECARGA") && upperText.contains("CLARO")) ||
        (upperText.contains("CLARO") && upperText.contains("TELEFON")) ||
        upperText.contains("NUM. TELEFONICO")) {
      print('Tipo detectado: RECARGA CLARO');
      return "RECARGA CLARO";
    }

    // PRIORIDAD 2: EFECTIVO MOVIL
    if (upperText.contains("EFECTIVO MOVIL") ||
        upperText.contains("EFECTIVO MÓVIL") ||
        upperText.contains("EFECTIVOMOVIL")) {
      print('Tipo detectado: EFECTIVO MOVIL');
      return "EFECTIVO MOVIL";
    }

    // PRIORIDAD 3: DEPOSITO
    if (upperText.contains("DEPOSITO") ||
        upperText.contains("DEPÓSITO") ||
        upperText.contains("DEPOSITAR")) {
      print('Tipo detectado: DEPOSITO');
      return "DEPOSITO";
    }

    // PRIORIDAD 4: RETIRO
    if (upperText.contains("RETIRO") ||
        upperText.contains("RETIRAR")) {
      print('Tipo detectado: RETIRO');
      return "RETIRO";
    }

    // PRIORIDAD 5: GIROS
    if (upperText.contains("ENVÍO GIRO") || 
        upperText.contains("ENVIO GIRO") ||
        upperText.contains("ENVIAR GIRO")) {
      print('Tipo detectado: ENVIO GIRO');
      return "ENVIO GIRO";
    }

    if (upperText.contains("PAGO GIRO") ||
        upperText.contains("PAGOGIRO")) {
      print('Tipo detectado: PAGO GIRO');
      return "PAGO GIRO";
    }

    // PRIORIDAD 6: PAGO DE SERVICIO
    if (upperText.contains("PAGO DE SERVICIO") ||
        upperText.contains("SERVICIO") ||
        upperText.contains("PAGAR")) {
      print('Tipo detectado: PAGO DE SERVICIO');
      return "PAGO DE SERVICIO";
    }

    // CASOS ESPECIALES: Si contiene solo "GIRO" sin especificar tipo
    if (upperText.contains("GIRO")) {
      print('Tipo detectado: PAGO GIRO (por defecto cuando solo dice GIRO)');
      return "PAGO GIRO";
    }

    // CASOS ESPECIALES: Si contiene solo "RECARGA" sin "CLARO"
    if (upperText.contains("RECARGA")) {
      print('Tipo detectado: RECARGA CLARO (por defecto cuando solo dice RECARGA)');
      return "RECARGA CLARO";
    }

    // VALOR POR DEFECTO
    print('Tipo detectado: PAGO DE SERVICIO (por defecto)');
    return "PAGO DE SERVICIO";
  }

  // Extrae el número de transacción
  String _extractTransactionNumber(String text) {
    // Buscar por líneas primero
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.toUpperCase().contains('TRANSACC') && line.contains(':')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          final digitsOnly = RegExp(r'\d+').allMatches(parts[1]).map((m) => m.group(0)).join();
          if (digitsOnly.isNotEmpty) {
            print('Número de transacción encontrado: $digitsOnly');
            return digitsOnly;
          }
        }
      }
    }

    // Expresiones regulares como respaldo
    final regexes = [
      RegExp(r'NRO\.\s*TRANSACC\s*ION\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'NRO\.\s*TRANSACCI[OÓ]N\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'TRANSACCI[OÓ]N\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'TRANSACCION\s*:\s*(\d+)', caseSensitive: false),
      RegExp(r'TRANSACC\s*:\s*(\d+)', caseSensitive: false),
    ];

    for (var regex in regexes) {
      final match = regex.firstMatch(text);
      if (match != null && match.group(1) != null) {
        print('Número de transacción encontrado con regex: ${match.group(1)!.trim()}');
        return match.group(1)!.trim();
      }
    }

    print('No se pudo encontrar número de transacción');
    return '';
  }

  // Extrae la fecha en formato dd/mm/yyyy
  String _extractDate(String text) {
    final datePatternRegex = RegExp(
      r'(\d{1,2}\s*/\s*\d{1,2}\s*/\s*\d{4})',
      caseSensitive: false,
    );
    final match = datePatternRegex.firstMatch(text);

    if (match != null) {
      String date = match.group(1) ?? '';
      String cleanDate = date.replaceAll(RegExp(r'\s+'), '');
      print('Fecha encontrada: $cleanDate');
      return cleanDate;
    }

    // Buscar formato con guiones y convertir
    final dateWithDashRegex = RegExp(
      r'(\d{1,2}\s*-\s*\d{1,2}\s*-\s*\d{4})',
      caseSensitive: false,
    );
    final dashMatch = dateWithDashRegex.firstMatch(text);

    if (dashMatch != null) {
      String date = dashMatch.group(1) ?? '';
      String convertedDate = date.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '/');
      print('Fecha encontrada (convertida de guiones): $convertedDate');
      return convertedDate;
    }

    print('No se pudo encontrar fecha');
    return '';
  }

  // Extrae la hora en formato hh:mm:ss
  String _extractTime(String text) {
    final timePatternRegex = RegExp(
      r'HORA\s*:\s*(\d{1,2}\s*:\s*\d{1,2}\s*:\s*\d{1,2})',
      caseSensitive: false,
    );
    final match = timePatternRegex.firstMatch(text);

    if (match != null) {
      String time = match.group(1) ?? '';
      String cleanTime = time.replaceAll(RegExp(r'\s+'), '');
      print('Hora encontrada: $cleanTime');
      return cleanTime;
    }

    // Buscar directamente un patrón de hora
    final timeOnlyRegex = RegExp(
      r'(\d{1,2}\s*:\s*\d{1,2}\s*:\s*\d{1,2})',
      caseSensitive: false,
    );
    final timeMatch = timeOnlyRegex.firstMatch(text);

    if (timeMatch != null) {
      String time = timeMatch.group(1) ?? '';
      String cleanTime = time.replaceAll(RegExp(r'\s+'), '');
      print('Hora encontrada (patrón directo): $cleanTime');
      return cleanTime;
    }

    print('No se pudo encontrar hora');
    return '';
  }

  // MEJORADO: Extrae el monto/valor total con mejor detección
  double _extractAmount(String text) {
    // Buscar por líneas primero
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.toUpperCase().contains('VALOR') || 
          line.toUpperCase().contains('TOTAL') ||
          line.toUpperCase().contains('MONTO')) {
        
        final amountStr = line
            .replaceAll(RegExp(r'[^\d.,]'), '')
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'\s+'), '');

        if (amountStr.isNotEmpty) {
          try {
            double amount = double.parse(amountStr);
            print('Valor encontrado: $amount');
            return amount;
          } catch (e) {
            print('Error parsing amount: $e');
          }
        }
      }
    }

    // Expresiones regulares como respaldo
    List<RegExp> regexes = [
      RegExp(r'\$\s*(\d+\.\s*\d+)', caseSensitive: false),
      RegExp(r'TOTAL\s*:?\s*\$?\s*(\d+[\.,]?\d*)', caseSensitive: false),
      RegExp(r'VALOR\s*TOTAL\s*:?\s*\$?\s*(\d+[\.,]?\d*)', caseSensitive: false),
      RegExp(r'VALOR\s*:?\s*\$?\s*(\d+[\.,]?\d*)', caseSensitive: false),
      RegExp(r'MONTO\s*:?\s*\$?\s*(\d+[\.,]?\d*)', caseSensitive: false),
      // NUEVO: Para recargas específicamente
      RegExp(r'RECARGA\s*:?\s*\$?\s*(\d+[\.,]?\d*)', caseSensitive: false),
    ];

    for (var regex in regexes) {
      final match = regex.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1) ?? '0';
        amountStr = amountStr.replaceAll(' ', '').replaceAll(',', '.');
        try {
          double amount = double.parse(amountStr);
          print('Valor encontrado con regex: $amount');
          return amount;
        } catch (e) {
          print('Error parsing matched amount: $e');
        }
      }
    }

    print('No se pudo encontrar valor total');
    return 0.0;
  }

  // Cierra el recognizer
  void dispose() {
    _textRecognizer.close();
  }
}