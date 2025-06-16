// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class ApiService {
  // URL con dirección IP directa
  String baseUrl = 'http://34.63.192.239:8080/api/v1';

  // Token de autenticación
  String? _authToken;

  // Contexto para acceder a los providers
  BuildContext? _context;

  // Método para establecer el contexto
  void setContext(BuildContext context) {
    _context = context;
    // Obtener el token del AuthProvider si está disponible
    if (_context != null) {
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      if (authProvider.isAuthenticated) {
        _authToken = authProvider.user?.token;
        print('ApiService: Token configurado desde setContext: ${_authToken != null ? _authToken!.substring(0, min(10, _authToken!.length)) : "null"}...');
      } else {
        print('ApiService: AuthProvider no está autenticado');
        // Si no está autenticado, redirigir a login
        _redirectToLogin();
      }
    }
  }

  // Método para permitir cambiar la URL dinámicamente (útil para pruebas/desarrollo)
  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    print('URL de API actualizada a: $baseUrl');
  }

  // Método para establecer el token de autenticación directamente
  void setAuthToken(String? token) {
    _authToken = token;
    print('ApiService: Token establecido manualmente: ${token != null ? token.substring(0, min(10, token.length)) : "null"}...');
  }

  // Método para convertir formato de fecha de dd/mm/aaaa a dd-mm-aaaa
  String _convertDateFormat(String dateStr) {
    return dateStr.replaceAll('/', '-');
  }

  // Crear los headers HTTP con o sin token de autenticación (método público)
  Map<String, String> getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
      print('ApiService: Incluyendo token en los headers');
    } else {
      print('ApiService: ATENCIÓN - No hay token disponible para los headers');
      // Si no hay token y estamos en un contexto, redirigir a login
      if (_context != null) {
        _redirectToLogin();
      }
    }

    return headers;
  }

  // Método auxiliar para redirigir a login
  void _redirectToLogin() {
    // Solo redirigir si tenemos un contexto y está montado
    if (_context != null && Navigator.canPop(_context!)) {
      // Usar Future.microtask para evitar problemas durante la construcción
      Future.microtask(() {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Sesión expirada. Por favor inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        Navigator.of(_context!).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }
  }

  // Método para realizar una petición HTTP con manejo de errores y reintentos
  Future<http.Response> _retryableRequest(
    String method,
    String url,
    {Map<String, String>? headers, String? body, int maxRetries = 3}
  ) async {
    int retryCount = 0;
    Duration retryDelay = Duration(seconds: 2);
    
    while (true) {
      try {
        http.Response response;
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(
              Uri.parse(url),
              headers: headers ?? getHeaders(),
            ).timeout(Duration(seconds: 60));
            break;
          case 'POST':
            response = await http.post(
              Uri.parse(url),
              headers: headers ?? getHeaders(),
              body: body,
            ).timeout(Duration(seconds: 60));
            break;
          case 'DELETE':
            response = await http.delete(
              Uri.parse(url),
              headers: headers ?? getHeaders(),
            ).timeout(Duration(seconds: 60));
            break;
          default:
            throw Exception('Método HTTP no soportado: $method');
        }
        
        // Verificar estado de autenticación
        if (response.statusCode == 401) {
          // Token inválido o expirado
          print('Error 401: Token inválido o expirado');
          
          // Intentar cerrar sesión y redirigir a login
          if (_context != null) {
            final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
            await authProvider.logout();
            _redirectToLogin();
          }
          
          throw Exception('Token inválido o expirado');
        }
        
        return response;
      } catch (e) {
        retryCount++;
        print('Error en petición HTTP ($retryCount/$maxRetries): $e');
        
        // Si es un error de autenticación, no reintentar
        if (e.toString().contains('Token inválido') || e.toString().contains('401')) {
          throw e;
        }
        
        // Si hemos alcanzado el número máximo de reintentos, lanzar excepción
        if (retryCount >= maxRetries) {
          throw e;
        }
        
        // Esperar antes de reintentar
        await Future.delayed(retryDelay);
        
        // Incrementar el tiempo de espera para el próximo reintento
        retryDelay *= 2;
      }
    }
  }

  // Obtener todos los comprobantes
  Future<List<Receipt>> getAllReceipts() async {
    try {
      final url = '$baseUrl/receipts/';
      print('Obteniendo comprobantes de: $url');

      // Mejorar el registro de la petición HTTP
      print('Enviando petición GET a: $url');
      print('Headers: ${getHeaders()}');

      final response = await _retryableRequest('GET', url);

      print('Código de respuesta: ${response.statusCode}');

      if (response.body.isNotEmpty) {
        try {
          print(
            'Primeros 200 caracteres del cuerpo: ${response.body.substring(0, min(200, response.body.length))}...',
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            if (responseData.containsKey('data')) {
              final List<dynamic> receiptsJson = responseData['data'];
              print('Comprobantes obtenidos: ${receiptsJson.length}');
              return receiptsJson
                  .map((json) => Receipt.fromJson(json))
                  .toList();
            } else {
              print('La respuesta no contiene la clave "data"');
              print('Respuesta completa: ${response.body}');
              return [];
            }
          } else {
            print('Error HTTP: ${response.statusCode}');
            print('Detalles: ${response.body}');
            throw Exception(
              'Error al obtener comprobantes: ${response.statusCode} - ${response.body}',
            );
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
        print(
          'La conexión al servidor agotó el tiempo de espera (60 segundos)',
        );
        print(
          'Nota: Los servicios en servidores en la nube pueden tener "cold starts" que tardan más en responder la primera vez',
        );
      } else if (e is FormatException) {
        print(
          'Error de formato: La respuesta no tiene el formato JSON esperado',
        );
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

      final response = await _retryableRequest('POST', url, body: jsonBody);

      print('Respuesta del servidor: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print(
          'Cuerpo: ${response.body.substring(0, min(200, response.body.length))}...',
        );
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
        throw Exception(
          'Error al guardar comprobante: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error en saveReceipt: $e');

      if (e is SocketException) {
        print('Error de socket: No se pudo conectar al servidor');
        print('Detalles: ${e.message}');
      } else if (e.toString().contains('TimeoutException')) {
        print(
          'La conexión al servidor agotó el tiempo de espera (60 segundos)',
        );
        print(
          'Nota: Los servicios en servidores en la nube pueden tener "cold starts" que tardan más en responder la primera vez',
        );
      } else if (e is FormatException) {
        print(
          'Error de formato: La respuesta no tiene el formato JSON esperado',
        );
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
      print(
        'Eliminando comprobante con número de transacción: $transactionNumber',
      );
      
      final response = await _retryableRequest(
        'DELETE', 
        '$baseUrl/receipts/$transactionNumber'
      );

      print('Respuesta del servidor: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print(
          'Cuerpo: ${response.body.substring(0, min(200, response.body.length))}...',
        );
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Error al eliminar comprobante: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error en deleteReceipt: $e');

      if (e is SocketException) {
        print('Error de socket: No se pudo conectar al servidor');
      } else if (e.toString().contains('TimeoutException')) {
        print(
          'La conexión al servidor agotó el tiempo de espera (60 segundos)',
        );
      }

      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener reporte de cierre
  Future<Map<String, dynamic>> getClosingReport(DateTime date) async {
    try {
      // Formato de fecha con guiones: dd-MM-yyyy
      String dateStr =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';

      // Imprimir el formato de fecha para verificar
      print('Formato de fecha enviado: $dateStr');

      // Revisar la ruta completa
      final String url = '$baseUrl/receipts/report/$dateStr';
      print('URL del reporte: $url');

      // Añadir logs detallados
      print('Enviando solicitud GET a: $url');
      print('Headers: ${getHeaders()}');

      final response = await _retryableRequest('GET', url);

      print('Código de respuesta: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Datos del reporte recibidos: $jsonResponse');
        return jsonResponse;
      } else {
        // Manejar específicamente el error 404
        if (response.statusCode == 404) {
          print(
            'Error 404: No se encontró la ruta o no hay datos para la fecha $dateStr',
          );
          return {
            'summary': {},
            'total': 0.0,
            'date': date.toString(),
            'count': 0,
            'error': 'No se encontraron datos para la fecha especificada',
          };
        } else {
          throw Exception(
            'Error en la respuesta del servidor: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error en getClosingReport: $e');

      return {
        'summary': {},
        'total': 0.0,
        'date': date.toString(),
        'count': 0,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Helper function for min (used in truncating logs)
  int min(int a, int b) {
    return (a < b) ? a : b;
  }
}