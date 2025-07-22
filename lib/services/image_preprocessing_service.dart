// lib/services/image_preprocessing_service.dart - VERSIÓN CORREGIDA
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessingService {
  
  /// Mejora la imagen antes del OCR para mayor precisión
  static Future<String> preprocessImage(String originalImagePath) async {
    try {
      // Leer la imagen original
      final File originalFile = File(originalImagePath);
      final Uint8List imageBytes = await originalFile.readAsBytes();
      
      // Decodificar la imagen
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('No se pudo decodificar la imagen');
      
      // PASO 1: Ajustar el tamaño si es necesario (pero manteniendo calidad)
      if (image.width > 2000 || image.height > 2000) {
        image = img.copyResize(image, 
          width: image.width > image.height ? 2000 : null,
          height: image.height > image.width ? 2000 : null,
          interpolation: img.Interpolation.cubic
        );
      }
      
      // PASO 2: Convertir a escala de grises (mejora OCR)
      image = img.grayscale(image);
      
      // PASO 3: Aumentar contraste
      image = img.contrast(image, contrast: 120); // Valor entre 0-255
      
      // PASO 4: Ajustar brillo si está muy oscuro
      image = img.adjustColor(image, brightness: 10); // Valor entre -255 y 255
      
      // PASO 5: Aplicar un filtro de nitidez suave - CORREGIDO
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
      ], div: 1);
      
      // PASO 6: Reducir ruido con un filtro gaussiano muy suave
      image = img.gaussianBlur(image, radius: 1); // Usar entero
      
      // Crear archivo procesado
      final String processedPath = originalImagePath.replaceAll('.jpg', '_processed.jpg');
      final File processedFile = File(processedPath);
      
      // Guardar imagen procesada con alta calidad
      await processedFile.writeAsBytes(
        img.encodeJpg(image, quality: 95)
      );
      
      print('✅ Imagen preprocesada guardada en: $processedPath');
      return processedPath;
      
    } catch (e) {
      print('❌ Error en preprocesamiento: $e');
      // Si falla el preprocesamiento, devolver la imagen original
      return originalImagePath;
    }
  }
  
  /// Mejora específica para texto de recibos
  static Future<String> optimizeForReceiptText(String imagePath) async {
    try {
      final File file = File(imagePath);
      final Uint8List imageBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) return imagePath;
      
      // Convertir a escala de grises
      image = img.grayscale(image);
      
      // Binarización adaptativa (muy efectiva para texto)
      image = _adaptiveThreshold(image);
      
      // Erosión y dilatación para limpiar texto
      image = _morphologyClean(image);
      
      // Guardar resultado
      final String optimizedPath = imagePath.replaceAll('.jpg', '_optimized.jpg');
      final File optimizedFile = File(optimizedPath);
      await optimizedFile.writeAsBytes(img.encodeJpg(image, quality: 100));
      
      return optimizedPath;
      
    } catch (e) {
      print('Error en optimización para texto: $e');
      return imagePath;
    }
  }
  
  /// Modo de alto contraste para recibos difíciles
  static Future<String> highContrastMode(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image != null) {
        // Convertir a escala de grises
        image = img.grayscale(image);
        
        // Aumentar contraste dramáticamente
        image = img.contrast(image, contrast: 200); // Valor entre 0-255
        
        // Aplicar ajustes de color - CORREGIDO
        image = img.adjustColor(image, 
          brightness: 1.2,
          saturation: 0,
          gamma: 0.8
        );
        
        // Guardar resultado
        final processedPath = imagePath.replaceAll('.jpg', '_high_contrast.jpg');
        await File(processedPath).writeAsBytes(img.encodeJpg(image, quality: 100));
        return processedPath;
      }
      
      return imagePath;
    } catch (e) {
      print('Error en modo alto contraste: $e');
      return imagePath;
    }
  }
  
  /// Binarización adaptativa simple - CORREGIDA
  static img.Image _adaptiveThreshold(img.Image image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image result = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final img.Pixel pixel = image.getPixel(x, y);
        final int gray = img.getLuminance(pixel).toInt(); // CORREGIDO: convertir a int
        
        // Calcular umbral local (promedio de área 5x5)
        int sum = 0;
        int count = 0;
        for (int dy = -2; dy <= 2; dy++) {
          for (int dx = -2; dx <= 2; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              final img.Pixel neighborPixel = image.getPixel(nx, ny);
              sum += img.getLuminance(neighborPixel).toInt(); // CORREGIDO
              count++;
            }
          }
        }
        
        final int threshold = sum ~/ count; // CORREGIDO: división entera
        final int binaryValue = gray > threshold - 10 ? 255 : 0;
        
        // CORREGIDO: usar setPixelRgb
        result.setPixelRgb(x, y, binaryValue, binaryValue, binaryValue);
      }
    }
    
    return result;
  }
  
  /// Limpieza morfológica básica - CORREGIDA
  static img.Image _morphologyClean(img.Image image) {
    // Implementación simple de erosión seguida de dilatación
    final eroded = _erode(image);
    return _dilate(eroded);
  }
  
  static img.Image _erode(img.Image image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image result = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int minValue = 255;
        
        // Kernel 3x3
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              final img.Pixel pixel = image.getPixel(nx, ny);
              final int value = img.getLuminance(pixel).toInt(); // CORREGIDO
              if (value < minValue) minValue = value;
            }
          }
        }
        
        // CORREGIDO: usar setPixelRgb
        result.setPixelRgb(x, y, minValue, minValue, minValue);
      }
    }
    
    return result;
  }
  
  static img.Image _dilate(img.Image image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image result = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int maxValue = 0;
        
        // Kernel 3x3
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              final img.Pixel pixel = image.getPixel(nx, ny);
              final int value = img.getLuminance(pixel).toInt(); // CORREGIDO
              if (value > maxValue) maxValue = value;
            }
          }
        }
        
        // CORREGIDO: usar setPixelRgb
        result.setPixelRgb(x, y, maxValue, maxValue, maxValue);
      }
    }
    
    return result;
  }
}