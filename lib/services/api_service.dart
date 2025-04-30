// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riocaja_smart/models/receipt.dart';

class ApiService {
  // Asegúrate de que esta URL sea correcta - usa tu dirección IP y puerto correcto
  final String baseUrl = 'http://10.41.1.251:8080/api/v1';
 
  // Obtener todos los comprobantes
  Future<List<Receipt>> getAllReceipts() async {
    try {
      print('Obteniendo comprobantes de: $baseUrl/receipts/');
      final response = await http.get(Uri.parse('$baseUrl/receipts/'));
      
      print('Respuesta: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> receiptsJson = responseData['data'];
        
        print('Comprobantes obtenidos: ${receiptsJson.length}');
        return receiptsJson.map((json) => Receipt.fromJson(json)).toList();
      } else {
        print('Error HTTP: ${response.statusCode}');
        throw Exception('Error al obtener comprobantes');
      }
    } catch (e) {
      print('Error en getAllReceipts: $e');
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Guardar un nuevo comprobante
  Future<bool> saveReceipt(Receipt receipt) async {
    try {
      print('Guardando comprobante en: $baseUrl/receipts/');
      print('Datos a enviar: ${jsonEncode(receipt.toJson())}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/receipts/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(receipt.toJson()),
      );
      
      print('Respuesta del servidor: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('Cuerpo: ${response.body.substring(0, min(100, response.body.length))}...');
      }
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error al guardar comprobante: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en saveReceipt: $e');
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
    );

    print('Respuesta del servidor: ${response.statusCode}');
    if (response.body.isNotEmpty) {
      print('Cuerpo: ${response.body.substring(0, min(100, response.body.length))}...');
    }

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Error al eliminar comprobante: ${response.statusCode}');
    }
  } catch (e) {
    print('Error en deleteReceipt: $e');
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
      );
      
      print('Respuesta: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener reporte: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getClosingReport: $e');
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Helper function for min (used in truncating logs)
  int min(int a, int b) {
    return (a < b) ? a : b;
  }
}