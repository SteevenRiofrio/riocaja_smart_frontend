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
  
  // Analiza el texto para extraer datos del comprobante de pago de servicio
  Future<Map<String, dynamic>> analyzeReceipt(String text) async {
    try {
    // Determinar el tipo de comprobante basado en el texto
    String tipo = '';
    
    // Solo detectar entre dos tipos: Retiro o Pago de Servicio
    if (text.toUpperCase().contains('RETIRO')) {
      tipo = 'Retiro';
    } else {
      // Si no se detecta explícitamente como Retiro, asignar Pago de Servicio
      tipo = 'Pago de Servicio';
    }

      // Extraer campos según el orden y formato del comprobante original
      Map<String, dynamic> result = {
        'banco': 'Banco del Barrio | Banco Guayaquil',
        'fecha': _extractDate(text),
        'hora': _extractTime(text),
        'tipo': 'tipo',
        'nro_transaccion': _extractTransactionNumber(text),
        'nro_control': _extractControlNumber(text),
        'local': _extractLocalName(text),
        'fecha_alternativa': _extractAlternativeDate(text),
        'corresponsal': _extractCorresponsal(text),
        'tipo_cuenta': _extractAccountType(text),
        'valor_total': _extractAmount(text),
        'fullText': text,
      };
      
      return result;
    } catch (e) {
      print('Error analyzing receipt: $e');
      return {
        'tipo': 'No Detectado',
        'fullText': text,
      };
    }
  }
  
// Extrae el número de transacción
String _extractTransactionNumber(String text) {
  // Primero, intentar buscar por líneas ya que la expresión regular puede fallar con espacios o formatos inusuales
  final lines = text.split('\n');
  for (var line in lines) {
    if (line.toUpperCase().contains('TRANSACC') && line.contains(':')) {
      // Extraer la parte después de los dos puntos
      final parts = line.split(':');
      if (parts.length > 1) {
        // Limpiar y extraer solo los dígitos
        final digitsOnly = RegExp(r'\d+').allMatches(parts[1])
          .map((m) => m.group(0))
          .join();
        
        if (digitsOnly.isNotEmpty) {
          return digitsOnly;
        }
      }
    }
  }
  
  // Si la búsqueda por líneas falla, intentar con las expresiones regulares
  final regexes = [
    RegExp(r'NRO\.\s*TRANSACC\s*ION\s*:\s*(\d+)', caseSensitive: false),
    RegExp(r'NRO\.\s*TRANSACCI[OÓ]N\s*:\s*(\d+)', caseSensitive: false),
    RegExp(r'TRANSACCI[OÓ]N\s*:\s*(\d+)', caseSensitive: false),
  ];
  
  for (var regex in regexes) {
    final match = regex.firstMatch(text);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
  }
  
  return '';
}
  
// Extrae la fecha en formato dd/mm/yyyy
String _extractDate(String text) {
  // Expresión regular más flexible que permite espacios entre los componentes
  final datePatternRegex = RegExp(r'(\d{1,2}\s*/\s*\d{1,2}\s*/\s*\d{4})', caseSensitive: false);
  final match = datePatternRegex.firstMatch(text);
  
  if (match != null) {
    // Limpiar los espacios de la fecha encontrada
    String date = match.group(1) ?? '';
    return date.replaceAll(RegExp(r'\s+'), '');
  }
  
  return '';
}

  
  // Extrae la fecha en formato alternativo (DD-MM-YYYY)
  String _extractAlternativeDate(String text) {
  // Expresión regular más flexible que permite espacios
  final datePatternRegex = RegExp(r'(\d{1,2}\s*-\s*\d{1,2}\s*-\s*\d{4})', caseSensitive: false);
  final match = datePatternRegex.firstMatch(text);
  
  if (match != null) {
    // Limpiar los espacios
    String date = match.group(1) ?? '';
    return date.replaceAll(RegExp(r'\s+'), '');
  }
  
  return '';
}
  
 // Extrae la hora en formato hh:mm:ss
String _extractTime(String text) {
  // Expresión regular más flexible que permite espacios
  final timePatternRegex = RegExp(r'HORA\s*:\s*(\d{1,2}\s*:\s*\d{1,2}\s*:\s*\d{1,2})', caseSensitive: false);
  final match = timePatternRegex.firstMatch(text);
  
  if (match != null) {
    // Limpiar los espacios
    String time = match.group(1) ?? '';
    return time.replaceAll(RegExp(r'\s+'), '');
  }
  
  // Buscar directamente un patrón de hora
  final timeOnlyRegex = RegExp(r'(\d{1,2}\s*:\s*\d{1,2}\s*:\s*\d{1,2})', caseSensitive: false);
  final timeMatch = timeOnlyRegex.firstMatch(text);
  
  if (timeMatch != null) {
    // Limpiar los espacios
    String time = timeMatch.group(1) ?? '';
    return time.replaceAll(RegExp(r'\s+'), '');
  }
  
  return '';
}
  
  // Extrae el corresponsal
  String _extractCorresponsal(String text) {
    final RegExp regex = RegExp(r'CORRESPONSAL\s*:?\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }
  
  // Extrae el nombre del local
  String _extractLocalName(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.contains('COMERCIAL') || line.trim().startsWith('COMERCIAL')) {
        return line.trim();
      }
    }
    return '';
  }
  
  // Extrae el tipo de cuenta
  String _extractAccountType(String text) {
    final RegExp regex = RegExp(r'TIPO DE CUENTA\s*:?\s*([A-Za-z]+)', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }
  
// Extrae el número de control
String _extractControlNumber(String text) {
  // Expresión mejorada para capturar correctamente después de NRO. DE CONTROL:
  final RegExp regex = RegExp(r'NRO\.?\s*DE\s*CONTROL\s*:?\s*(\d+)', caseSensitive: false);
  final match = regex.firstMatch(text);
  if (match != null && match.group(1) != null) {
    return match.group(1)!.trim();
  }
  
  // Búsqueda alternativa por líneas
  final lines = text.split('\n');
  for (var line in lines) {
    if (line.toUpperCase().contains('CONTROL')) {
      // Extraer solo los dígitos
      final digitsOnly = RegExp(r'\d+').firstMatch(line);
      if (digitsOnly != null) {
        return digitsOnly.group(0) ?? '';
      }
    }
  }
  return '';
}
  
// Extrae el monto
double _extractAmount(String text) {
  // Buscar por líneas para encontrar el valor total
  final lines = text.split('\n');
  for (var line in lines) {
    if (line.toUpperCase().contains('VALOR') || line.toUpperCase().contains('TOTAL')) {
      // Extraer todos los dígitos, puntos y comas, ignorando espacios
      final amountStr = line.replaceAll(RegExp(r'[^\d.,]'), '')
                            .replaceAll(',', '.')  // Convertir comas a puntos
                            .replaceAll(RegExp(r'\s+'), ''); // Eliminar espacios
      
      if (amountStr.isNotEmpty) {
        try {
          return double.parse(amountStr);
        } catch (e) {
          print('Error parsing amount: $e');
        }
      }
    }
  }
  
  // Si no encontramos el valor por líneas, intentar con expresiones regulares más flexibles
  List<RegExp> regexes = [
    // Patrones que manejan espacios después del punto
    RegExp(r'\$\s*(\d+\.\s*\d+)', caseSensitive: false),
    RegExp(r'TOTAL\s*:?\s*\$?\s*(\d+\.\s*\d+)', caseSensitive: false),
    RegExp(r'VALOR\s*TOTAL\s*:?\s*\$?\s*(\d+\.\s*\d+)', caseSensitive: false),
    
    // Patrones regulares sin considerar espacios
    RegExp(r'\$\s*(\d+[\.,]?\d*)', caseSensitive: false),
    RegExp(r'TOTAL\s*:?\s*\$?\s*(\d+[\.,]?\d*)', caseSensitive: false),
    RegExp(r'VALOR\s*TOTAL\s*:?\s*\$?\s*(\d+[\.,]?\d*)', caseSensitive: false),
  ];
  
  for (var regex in regexes) {
    final match = regex.firstMatch(text);
    if (match != null) {
      String amountStr = match.group(1) ?? '0';
      // Limpiar la cadena: eliminar espacios y convertir comas a puntos
      amountStr = amountStr.replaceAll(' ', '').replaceAll(',', '.');
      try {
        return double.parse(amountStr);
      } catch (e) {
        print('Error parsing matched amount: $e');
      }
    }
  }
  
  return 0.0;
}
  
  // Cierra el recognizer cuando ya no se necesite
  void dispose() {
    _textRecognizer.close();
  }
}