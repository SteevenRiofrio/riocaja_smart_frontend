// lib/services/api_service.dart - Completo y corregido
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:riocaja_smart/models/receipt.dart';

class ApiService {
  // URL actualizada al backend desplegado en Render
  String baseUrl = 'https://35.202.219.87/api/v1';
  
  // Método para permitir cambiar la URL dinámicamente (útil para pruebas/desarrollo)
  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    print('URL de API actualizada a: $baseUrl');
  }

  // Obtener todos los comprobantes
  Future<List<Receipt>> getAllReceipts() async {
    try {
      final url = '$baseUrl/receipts/';
      print('Obteniendo comprobantes de: $url');
      
      // Mejorar el registro de la petición HTTP
      print('Enviando petición GET a: $url');
      print('Headers: ${{'Content-Type': 'application/json', 'Accept': 'application/json'}}');
      
      // Aumentar el timeout para servicios en la nube como Render que pueden tener cold starts
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 60)); // 60 segundos para manejar cold starts
      
      print('Código de respuesta: ${response.statusCode}');
      
      if (response.body.isNotEmpty) {
        try {
          print('Primeros 200 caracteres del cuerpo: ${response.body.substring(0, min(200, response.body.length))}...');
          
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            if (responseData.containsKey('data')) {
              final List<dynamic> receiptsJson = responseData['data'];
              print('Comprobantes obtenidos: ${receiptsJson.length}');
              return receiptsJson.map((json) => Receipt.fromJson(json)).toList();
            } else {
              print('La respuesta no contiene la clave "data"');
              print('Respuesta completa: ${response.body}');
              return [];
            }
          } else {
            print('Error HTTP: ${response.statusCode}');
            print('Detalles: ${response.body}');
            throw Exception('Error al obtener comprobantes: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          print('Error al procesar el cuerpo de la respuesta: $e');
          print('Cuerpo de respuesta original: ${response.body}');
          throw Exception('Error al procesar respuesta: $e');
        }
      } else {
        print('El cuerpo de la respuesta está vacío');
        throw Exception('Respuesta vacía del servidor');
      }
    } catch (e) {
      print('Error en getAllReceipts: $e');
      
      // Mejor diagnóstico de errores de red
      if (e is SocketException) {
        print('Error de socket: No se pudo conectar al servidor');
        print('Detalles: ${e.message}');
      } else if (e.toString().contains('TimeoutException')) {
        print('La conexión al servidor agotó el tiempo de espera (60 segundos)');
        print('Nota: Los servicios en Render pueden tener "cold starts" que tardan más en responder la primera vez');
      } else if (e is FormatException) {
        print('Error de formato: La respuesta no tiene el formato JSON esperado');
      }
      
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Guardar un nuevo comprobante
  Future<bool> saveReceipt(Receipt receipt) async {
    try {
      final url = '$baseUrl/receipts/';
      print('Guardando comprobante en: $url');
      
      // Convertir el objeto Receipt a JSON con el formato correcto
      final Map<String, dynamic> receiptJson = receipt.toJson();
      final String jsonBody = jsonEncode(receiptJson);
      
      print('Datos a enviar: $jsonBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      ).timeout(Duration(seconds: 60));
      
      print('Respuesta del servidor: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('Cuerpo: ${response.body.substring(0, min(200, response.body.length))}...');
      }
      
      // Revisar códigos de estado adicionales
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 400) {
        print('Error 400: Solicitud incorrecta');
        print('Detalles: ${response.body}');
        throw Exception('Error 400: ${response.body}');
      } else if (response.statusCode == 500) {
        print('Error 500: Error interno del servidor');
        print('Detalles: ${response.body}');
        throw Exception('Error 500: ${response.body}');
      } else {
        print('Error HTTP no esperado: ${response.statusCode}');
        print('Detalles: ${response.body}');
        throw Exception('Error al guardar comprobante: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en saveReceipt: $e');
      
      if (e is SocketException) {
        print('Error de socket: No se pudo conectar al servidor');
        print('Detalles: ${e.message}');
      } else if (e.toString().contains('TimeoutException')) {
        print('La conexión al servidor agotó el tiempo de espera (60 segundos)');
        print('Nota: Los servicios en Render pueden tener "cold starts" que tardan más en responder la primera vez');
      } else if (e is FormatException) {
        print('Error de formato: La respuesta no tiene el formato JSON esperado');
      }
      
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar un comprobante por número de transacción
  Future<bool> deleteReceipt(String transactionNumber) async {
    if (transactionNumber.isEmpty) {
      throw Exception('El número de transacción no puede estar vacío.');
    }

    try {
      print('Eliminando comprobante con número de transacción: $transactionNumber');
      final response = await http.delete(
        Uri.parse('$baseUrl/receipts/$transactionNumber'),
      ).timeout(Duration(seconds: 60));

      print('Respuesta del servidor: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('Cuerpo: ${response.body.substring(0, min(200, response.body.length))}...');
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al eliminar comprobante: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en deleteReceipt: $e');
      
      if (e is SocketException) {
        print('Error de socket: No se pudo conectar al servidor');
      } else if (e.toString().contains('TimeoutException')) {
        print('La conexión al servidor agotó el tiempo de espera (60 segundos)');
      }
      
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener reporte de cierre
  Future<Map<String, dynamic>> getClosingReport(DateTime date) async {
    // Formato de fecha esperado: dd/MM/yyyy
    String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    
    try {
      print('Obteniendo reporte para fecha: $dateStr');
      final response = await http.get(
        Uri.parse('$baseUrl/receipts/report/$dateStr'),
      ).timeout(Duration(seconds: 60));
      
      print('Respuesta: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener reporte: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en getClosingReport: $e');
      
      if (e is SocketException) {
        print('Error de socket: No se pudo conectar al servidor');
      } else if (e.toString().contains('TimeoutException')) {
        print('La conexión al servidor agotó el tiempo de espera (60 segundos)');
      }
      
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Helper function for min (used in truncating logs)
  int min(int a, int b) {
    return (a < b) ? a : b;
  }
}