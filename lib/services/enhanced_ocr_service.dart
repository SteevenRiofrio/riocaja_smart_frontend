// lib/services/enhanced_ocr_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:riocaja_smart/services/image_preprocessing_service.dart';

class EnhancedOcrService {
  late final TextRecognizer _textRecognizer;
  
  EnhancedOcrService() {
    // Configurar el reconocedor con opciones específicas para español
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin, // Específico para caracteres latinos
    );
  }

  /// Extrae texto con preprocesamiento automático
  Future<String> extractTextWithPreprocessing(String imagePath) async {
    try {
      print('🔄 Iniciando extracción con preprocesamiento...');
      
      // PASO 1: Preprocesar la imagen
      final String processedImagePath = await ImagePreprocessingService.preprocessImage(imagePath);
      
      // PASO 2: Extraer texto de la imagen procesada
      final String extractedText = await _extractRawText(processedImagePath);
      
      // PASO 3: Si el resultado no es bueno, intentar con optimización para texto
      if (_isTextQualityPoor(extractedText)) {
        print('⚠️ Calidad de texto pobre, intentando optimización adicional...');
        final String optimizedImagePath = await ImagePreprocessingService.optimizeForReceiptText(processedImagePath);
        final String optimizedText = await _extractRawText(optimizedImagePath);
        
        // Usar el mejor resultado
        return optimizedText.length > extractedText.length ? optimizedText : extractedText;
      }
      
      return extractedText;
      
    } catch (e) {
      print('❌ Error en extracción con preprocesamiento: $e');
      // Fallback: intentar con imagen original
      return await _extractRawText(imagePath);
    }
  }

  /// Extrae texto sin preprocesamiento (método original)
  Future<String> extractText(String imagePath) async {
    return await _extractRawText(imagePath);
  }

  /// Método privado para extraer texto crudo
  Future<String> _extractRawText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      print('📝 Texto extraído (${recognizedText.text.length} caracteres):');
      print(recognizedText.text.substring(0, recognizedText.text.length > 200 ? 200 : recognizedText.text.length));
      
      return recognizedText.text;
    } catch (e) {
      print('❌ Error extrayendo texto: $e');
      return "Error al extraer texto: $e";
    }
  }

  /// Determina si la calidad del texto extraído es pobre
  bool _isTextQualityPoor(String text) {
    // Criterios para determinar mala calidad:
    // 1. Muy poco texto (menos de 50 caracteres)
    if (text.length < 50) return true;
    
    // 2. Demasiados caracteres especiales raros
    int specialChars = 0;
    final weirdChars = RegExp(r'[^\w\s\$\.\,\:\;\-\/\(\)]', unicode: true);
    specialChars = weirdChars.allMatches(text).length;
    
    if (specialChars > text.length * 0.3) return true; // Más del 30% son caracteres raros
    
    // 3. No contiene palabras clave esperadas de un recibo
    final expectedWords = ['banco', 'fecha', 'total', 'valor', 'transacc', 'hora'];
    bool hasExpectedWords = expectedWords.any((word) => 
      text.toLowerCase().contains(word)
    );
    
    return !hasExpectedWords;
  }

  /// Analiza recibo con lógica mejorada y múltiples intentos
  Future<Map<String, dynamic>> analyzeReceiptEnhanced(String imagePath) async {
    try {
      print('🎯 Iniciando análisis mejorado de recibo...');
      
      // INTENTO 1: Con preprocesamiento completo
      String extractedText = await extractTextWithPreprocessing(imagePath);
      Map<String, dynamic> result = _analyzeExtractedText(extractedText);
      
      // Si los resultados son pobres, intentar método alternativo
      if (_areResultsPoor(result)) {
        print('📈 Resultados pobres, intentando método alternativo...');
        
        // INTENTO 2: Solo con imagen original
        extractedText = await extractText(imagePath);
        Map<String, dynamic> alternativeResult = _analyzeExtractedText(extractedText);
        
        // Usar el mejor resultado
        result = _selectBestResult(result, alternativeResult);
      }
      
      result['full_text'] = extractedText;
      result['confidence'] = _calculateConfidence(result);
      
      print('✅ Análisis completado con confianza: ${result['confidence']}%');
      return result;
      
    } catch (e) {
      print('❌ Error en análisis mejorado: $e');
      return _getEmptyResult();
    }
  }

  /// Analiza el texto extraído y devuelve datos estructurados
  Map<String, dynamic> _analyzeExtractedText(String text) {
    return {
      'fecha': _extractDateEnhanced(text),
      'hora': _extractTimeEnhanced(text),
      'tipo': _determineReceiptTypeEnhanced(text),
      'nro_transaccion': _extractTransactionNumberEnhanced(text),
      'valor_total': _extractAmountEnhanced(text),
    };
  }

  /// Determina si los resultados son pobres
  bool _areResultsPoor(Map<String, dynamic> result) {
    int emptyFields = 0;
    if (result['fecha'].toString().isEmpty) emptyFields++;
    if (result['hora'].toString().isEmpty) emptyFields++;
    if (result['nro_transaccion'].toString().isEmpty) emptyFields++;
    if (result['valor_total'] == 0.0) emptyFields++;
    
    return emptyFields >= 3; // Si 3 o más campos están vacíos, es pobre
  }

  /// Selecciona el mejor resultado entre dos análisis
  Map<String, dynamic> _selectBestResult(Map<String, dynamic> result1, Map<String, dynamic> result2) {
    int score1 = _scoreResult(result1);
    int score2 = _scoreResult(result2);
    
    print('🔍 Puntuación resultado 1: $score1, resultado 2: $score2');
    return score1 >= score2 ? result1 : result2;
  }

  /// Calcula puntuación de un resultado
  int _scoreResult(Map<String, dynamic> result) {
    int score = 0;
    if (result['fecha'].toString().isNotEmpty) score += 25;
    if (result['hora'].toString().isNotEmpty) score += 20;
    if (result['nro_transaccion'].toString().isNotEmpty) score += 30;
    if (result['valor_total'] > 0) score += 25;
    return score;
  }

  /// Calcula el nivel de confianza del resultado
  int _calculateConfidence(Map<String, dynamic> result) {
    return _scoreResult(result);
  }

  /// Resultado vacío por defecto
  Map<String, dynamic> _getEmptyResult() {
    return {
      'fecha': '',
      'hora': '',
      'tipo': 'PAGO DE SERVICIO',
      'nro_transaccion': '',
      'valor_total': 0.0,
      'confidence': 0,
    };
  }

  // ========== MÉTODOS DE EXTRACCIÓN MEJORADOS ==========

  /// Extracción de fecha mejorada
  String _extractDateEnhanced(String text) {
    final patterns = [
      RegExp(r'FECHA\s*:?\s*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4})', caseSensitive: false),
      RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4})', caseSensitive: false),
      RegExp(r'(\d{1,2}\s*[\/\-]\s*\d{1,2}\s*[\/\-]\s*\d{4})', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String date = match.group(1) ?? '';
        return date.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '/');
      }
    }

    return '';
  }

  /// Extracción de hora mejorada
  String _extractTimeEnhanced(String text) {
    final patterns = [
      RegExp(r'HORA\s*:?\s*(\d{1,2}:\d{1,2}:\d{1,2})', caseSensitive: false),
      RegExp(r'(\d{1,2}:\d{1,2}:\d{1,2})', caseSensitive: false),
      RegExp(r'(\d{1,2}\s*:\s*\d{1,2}\s*:\s*\d{1,2})', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.replaceAll(RegExp(r'\s+'), '') ?? '';
      }
    }

    return '';
  }

  /// Determinación de tipo mejorada (reutiliza tu lógica existente pero mejorada)
  String _determineReceiptTypeEnhanced(String text) {
    String upperText = text.toUpperCase();
    
    // Usar tu lógica existente pero con tolerancia a errores OCR
    final cleanText = upperText.replaceAll(RegExp(r'[^\w\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    
    if (_containsAnyVariation(cleanText, ['RECARGA CLARO', 'ILIM CLARO', 'CLARO'])) {
      return "RECARGA CLARO";
    }
    
    if (_containsAnyVariation(cleanText, ['EFECTIVO MOVIL', 'EFECTIVO MOVIL'])) {
      return "EFECTIVO MOVIL";
    }
    
    if (_containsAnyVariation(cleanText, ['DEPOSITO', 'DEPOSITAR'])) {
      return "DEPOSITO";
    }
    
    return "PAGO DE SERVICIO";
  }

  /// Verifica si el texto contiene alguna variación de las palabras clave
  bool _containsAnyVariation(String text, List<String> keywords) {
    for (String keyword in keywords) {
      if (text.contains(keyword)) return true;
      
      // Verificar con caracteres similares que el OCR confunde
      String tolerantKeyword = keyword
          .replaceAll('O', '[O0]')
          .replaceAll('I', '[I1L]')
          .replaceAll('S', '[S5]')
          .replaceAll('A', '[A4]');
      
      if (RegExp(tolerantKeyword).hasMatch(text)) return true;
    }
    return false;
  }

  /// Extracción de número de transacción mejorada
  String _extractTransactionNumberEnhanced(String text) {
    final lines = text.split('\n');
    
    // Buscar en líneas que mencionen transacción
    for (var line in lines) {
      if (line.toUpperCase().contains(RegExp(r'TRANSACC|NRO|NUMERO'))) {
        final numbers = RegExp(r'\d{6,12}').allMatches(line);
        for (var match in numbers) {
          String number = match.group(0)!;
          if (!_isLikelyDateOrTime(number)) {
            return number;
          }
        }
      }
    }
    
    // Buscar números largos que no sean fechas/horas
    final longNumbers = RegExp(r'\b\d{8,12}\b').allMatches(text);
    for (var match in longNumbers) {
      String number = match.group(0)!;
      if (!_isLikelyDateOrTime(number) && !_isLikelyTimestamp(number)) {
        return number;
      }
    }
    
    return '';
  }

  bool _isLikelyDateOrTime(String number) {
    if (number.length == 8 && number.startsWith('20')) return true;
    if (number.length == 6) {
      int? hour = int.tryParse(number.substring(0, 2));
      if (hour != null && hour <= 23) return true;
    }
    return false;
  }

  bool _isLikelyTimestamp(String number) {
    return number.length >= 13;
  }

  /// Extracción de monto mejorada
  double _extractAmountEnhanced(String text) {
    final patterns = [
      RegExp(r'TOTAL\s*:?\s*\$?\s*(\d+[.,]?\d*)', caseSensitive: false),
      RegExp(r'VALOR\s*:?\s*\$?\s*(\d+[.,]?\d*)', caseSensitive: false),
      RegExp(r'\$\s*(\d+[.,]?\d*)', caseSensitive: false),
      RegExp(r'(\d+[.,]\d{2})\s*$', multiLine: true), // Números al final de línea con decimales
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1) ?? '0';
        amountStr = amountStr.replaceAll(',', '.');
        
        try {
          return double.parse(amountStr);
        } catch (e) {
          continue;
        }
      }
    }

    return 0.0;
  }

  void dispose() {
    _textRecognizer.close();
  }
}