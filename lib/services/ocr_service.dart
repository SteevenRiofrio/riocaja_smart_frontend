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

  // MEJORADO: Extrae el número de transacción con múltiples patrones
  String _extractTransactionNumber(String text) {
    print('Buscando número de transacción en: ${text.substring(0, text.length > 200 ? 200 : text.length)}');
    
    // PATRÓN 1: Buscar por líneas que contengan "TRANSACC" o similar
    final lines = text.split('\n');
    for (var line in lines) {
      String upperLine = line.toUpperCase();
      
      if ((upperLine.contains('TRANSACC') || upperLine.contains('NRO') || 
           upperLine.contains('NUMERO')) && line.contains(':')) {
        
        final parts = line.split(':');
        if (parts.length > 1) {
          // Extraer solo números del texto después de ":"
          final digitsOnly = RegExp(r'\d+').allMatches(parts[1]).map((m) => m.group(0)).join();
          if (digitsOnly.isNotEmpty && digitsOnly.length >= 4) {
            print('Número de transacción encontrado (método 1): $digitsOnly');
            return digitsOnly;
          }
        }
      }
    }
    
    // PATRÓN 2: Buscar secuencias largas de números (8+ dígitos)
    final longNumbers = RegExp(r'\b\d{8,}\b').allMatches(text);
    for (var match in longNumbers) {
      String number = match.group(0)!;
      // Evitar números que parezcan fechas o horas
      if (!_isLikelyDateOrTime(number)) {
        print('Número de transacción encontrado (método 2): $number');
        return number;
      }
    }
    
    // PATRÓN 3: Buscar cualquier secuencia de 6+ dígitos
    final mediumNumbers = RegExp(r'\b\d{6,}\b').allMatches(text);
    for (var match in mediumNumbers) {
      String number = match.group(0)!;
      if (!_isLikelyDateOrTime(number)) {
        print('Número de transacción encontrado (método 3): $number');
        return number;
      }
    }
    
    // PATRÓN 4: Buscar números después de palabras clave específicas
    final patterns = [
      RegExp(r'(?:TRANSACCI[OÓ]N|NRO|NUMERO|REFERENCIA)[\s:]*(\d+)', caseSensitive: false),
      RegExp(r'(\d+).*(?:TRANSACCI|NRO)', caseSensitive: false),
    ];
    
    for (var pattern in patterns) {
      var match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        String number = match.group(1)!;
        if (number.length >= 4) {
          print('Número de transacción encontrado (método 4): $number');
          return number;
        }
      }
    }
    
    // ÚLTIMO RECURSO: Generar número basado en fecha/hora si está disponible
    String fecha = _extractDate(text);
    String hora = _extractTime(text);
    
    if (fecha.isNotEmpty && hora.isNotEmpty) {
      // Crear número único basado en fecha y hora
      String cleanFecha = fecha.replaceAll('/', '').replaceAll('-', '');
      String cleanHora = hora.replaceAll(':', '');
      String generated = '$cleanFecha$cleanHora';
      
      if (generated.length >= 6) {
        print('Número de transacción generado desde fecha/hora: $generated');
        return generated;
      }
    }
    
    // SI NADA FUNCIONA: Generar número único con timestamp
    String fallback = DateTime.now().millisecondsSinceEpoch.toString();
    print('Número de transacción fallback generado: $fallback');
    return fallback;
  }

  // NUEVO: Método auxiliar para detectar si un número parece fecha/hora
  bool _isLikelyDateOrTime(String number) {
    // Detectar patrones de fecha (20250702, 20230101, etc.)
    if (number.length == 8 && number.startsWith('20')) {
      return true;
    }
    
    // Detectar patrones de hora (205240, 123045, etc.)
    if (number.length == 6) {
      int? hour = int.tryParse(number.substring(0, 2));
      int? minute = int.tryParse(number.substring(2, 4));
      if (hour != null && minute != null && hour <= 23 && minute <= 59) {
        return true;
      }
    }
    
    return false;
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