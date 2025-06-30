// lib/services/api_service.dart - COMPLETO Y CORREGIDO - FINAL
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/services/auth_service.dart';
import 'dart:convert';

class ApiService {
  // URL base de la API
  String baseUrl = 'https://riocajasmartbackend-production.up.railway.app/api/v1';

  // Token de autenticación
  String? _authToken;

  // Contexto para acceder a los providers
  BuildContext? _context;

  // Referencia al AuthService para refresh automático
  AuthService? _authService;

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
      }
    }
  }

  // Método para establecer AuthService (para refresh automático)
  void setAuthService(AuthService authService) {
    _authService = authService;
    print('ApiService: AuthService configurado para refresh automático');
  }

  // Método para permitir cambiar la URL dinámicamente
  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    print('URL de API actualizada a: $baseUrl');
  }

  // Método para establecer el token de autenticación directamente
  void setAuthToken(String? token) {
    _authToken = token;
    print('ApiService: Token establecido manualmente: ${token != null ? token.substring(0, min(10, token.length)) : "null"}...');
  }

  // Crear los headers HTTP con o sin token de autenticación
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
    }

    return headers;
  }

  // Método para hacer peticiones HTTP con interceptor de refresh automático
  Future<http.Response> _makeRequestWithRetry(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
    int maxRetries = 3,
  }) async {
    
    // Primera petición
    http.Response response = await _makeRawRequest(method, url, body: body, customHeaders: customHeaders);
    
    // Si es 401 (token expirado), intentar refresh automático
    if (response.statusCode == 401 && _authService != null) {
      print('Token expirado (401), intentando renovar automáticamente...');
      
      bool refreshSuccess = await _authService!.refreshAccessToken();
      
      if (refreshSuccess) {
        print('Token renovado exitosamente, reintentando petición...');
        
        // Actualizar token en ApiService
        _authToken = _authService!.token;
        
        // Actualizar token en AuthProvider si está disponible
        if (_context != null) {
          final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
          authProvider.syncTokensAfterRefresh();
        }
        
        // Reintentar la petición original con el nuevo token
        response = await _makeRawRequest(method, url, body: body, customHeaders: customHeaders);
        
        if (response.statusCode != 401) {
          print('Petición exitosa después de renovar token');
          return response;
        }
      }
      
      // Si el refresh falló o sigue dando 401, cerrar sesión
      print('No se pudo renovar el token, cerrando sesión...');
      await _handleLogout();
    }
    
    return response;
  }

  // Método auxiliar para hacer peticiones HTTP básicas (sin interceptor)
  Future<http.Response> _makeRawRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
  }) async {
    
    final headers = customHeaders ?? getHeaders();
    final uri = Uri.parse(url);
    
    print('Haciendo petición $method a: $url');
    
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(uri, headers: headers).timeout(Duration(seconds: 60));
        case 'POST':
          return await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(Duration(seconds: 60));
        case 'PUT':
          return await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(Duration(seconds: 60));
        case 'DELETE':
          return await http.delete(uri, headers: headers).timeout(Duration(seconds: 60));
        default:
          throw Exception('Método HTTP no soportado: $method');
      }
    } catch (e) {
      print('Error en petición HTTP: $e');
      throw e;
    }
  }

  // Método auxiliar para manejar logout
  Future<void> _handleLogout() async {
    try {
      if (_authService != null) {
        await _authService!.logout();
      }
      
      if (_context != null) {
        final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
        await authProvider.logout();
        
        Future.microtask(() {
          Navigator.of(_context!).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      }
    } catch (e) {
      print('Error durante logout: $e');
    }
  }

  // Obtener todos los comprobantes (con interceptor)
  Future<List<Receipt>> getAllReceipts() async {
    try {
      final url = '$baseUrl/receipts/';
      print('Obteniendo comprobantes de: $url');

      final response = await _makeRequestWithRetry('GET', url);

      print('Código de respuesta: ${response.statusCode}');

      if (response.body.isNotEmpty) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData.containsKey('data')) {
            final List<dynamic> receiptsJson = responseData['data'];
            print('Comprobantes obtenidos: ${receiptsJson.length}');
            return receiptsJson.map((json) => Receipt.fromJson(json)).toList();
          } else {
            print('La respuesta no contiene la clave "data"');
            return [];
          }
        } else {
          print('Error HTTP: ${response.statusCode}');
          throw Exception('Error al obtener comprobantes: ${response.statusCode}');
        }
      } else {
        print('El cuerpo de la respuesta está vacío');
        return [];
      }
    } catch (e) {
      print('Error en getAllReceipts: $e');
      
      if (e is SocketException) {
        print('Error de socket: No se pudo conectar al servidor');
      } else if (e.toString().contains('TimeoutException')) {
        print('La conexión al servidor agotó el tiempo de espera');
      }
      
      throw Exception('Error de conexión: $e');
    }
  }

  // Guardar comprobante (con interceptor) - CORREGIDO
  Future<bool> saveReceipt(Receipt receipt) async {
    try {
      final url = '$baseUrl/receipts/';
      print('Guardando comprobante en: $url');

      // CORREGIDO: Usar toJson() del modelo Receipt
      final Map<String, dynamic> receiptData = receipt.toJson();

      print('Datos del comprobante a enviar: ${receiptData.keys.toList()}');

      final response = await _makeRequestWithRetry('POST', url, body: receiptData);

      print('Código de respuesta guardar: ${response.statusCode}');
      print('Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Comprobante guardado exitosamente');
        return true;
      } else {
        print('Error al guardar comprobante: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error en saveReceipt: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar comprobante (con interceptor)
  Future<bool> deleteReceipt(String transactionNumber) async {
    if (transactionNumber.isEmpty) {
      throw Exception('El número de transacción no puede estar vacío.');
    }

    try {
      final url = '$baseUrl/receipts/$transactionNumber';
      print('Eliminando comprobante: $url');

      final response = await _makeRequestWithRetry('DELETE', url);

      print('Código de respuesta eliminar: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Comprobante eliminado exitosamente');
        return true;
      } else {
        print('Error al eliminar comprobante: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error en deleteReceipt: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener comprobantes filtrados por corresponsal (con interceptor)
  Future<List<Receipt>> getReceiptsByCorresponsal(String codigoCorresponsal) async {
    try {
      final url = '$baseUrl/receipts/corresponsal/$codigoCorresponsal';
      print('Obteniendo comprobantes por corresponsal: $url');

      final response = await _makeRequestWithRetry('GET', url);

      print('Código de respuesta: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('data')) {
          final List<dynamic> receiptsJson = responseData['data'];
          print('Comprobantes del corresponsal $codigoCorresponsal: ${receiptsJson.length}');
          return receiptsJson.map((json) => Receipt.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error al obtener comprobantes por corresponsal: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener lista de corresponsales disponibles (con interceptor)
  Future<List<String>> getAvailableCorresponsales() async {
    try {
      final url = '$baseUrl/receipts/corresponsales';
      print('Obteniendo corresponsales disponibles: $url');

      final response = await _makeRequestWithRetry('GET', url);

      print('Código de respuesta: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('corresponsales')) {
          final List<dynamic> corresponsalesJson = responseData['corresponsales'];
          return corresponsalesJson.map((item) => item.toString()).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error al obtener corresponsales: $e');
      return [];
    }
  }

  // NUEVO: Obtener reporte de cierre por fecha (con interceptor)
  Future<Map<String, dynamic>> getClosingReport(DateTime date) async {
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final url = '$baseUrl/receipts/closing-report/$dateStr';
      print('Obteniendo reporte de cierre: $url');

      final response = await _makeRequestWithRetry('GET', url);

      print('Código de respuesta reporte: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // Generar reporte local si el endpoint no existe
        return await getClosingReportLocal(date);
      }
    } catch (e) {
      print('Error al obtener reporte de cierre: $e');
      // Fallback a reporte local
      return await getClosingReportLocal(date);
    }
  }

  // Método alternativo para generar reporte localmente
  Future<Map<String, dynamic>> getClosingReportLocal(DateTime date) async {
    try {
      // Obtener todos los comprobantes
      final allReceipts = await getAllReceipts();
      
      // Filtrar por fecha
      final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      final receiptsForDate = allReceipts.where((receipt) => receipt.fecha == dateStr).toList();
      
      // Calcular totales
      double total = receiptsForDate.fold(0.0, (sum, receipt) => sum + receipt.valorTotal);
      
      // Agrupar por tipo
      Map<String, dynamic> summary = {};
      for (var receipt in receiptsForDate) {
        if (summary[receipt.tipo] == null) {
          summary[receipt.tipo] = {'count': 0, 'total': 0.0};
        }
        summary[receipt.tipo]['count']++;
        summary[receipt.tipo]['total'] += receipt.valorTotal;
      }
      
      return {
        'summary': summary,
        'total': total,
        'count': receiptsForDate.length,
        'receipts': receiptsForDate.map((r) => r.toJson()).toList(),
        'date': dateStr,
      };
    } catch (e) {
      print('Error generando reporte local: $e');
      return {
        'summary': {},
        'total': 0.0,
        'count': 0,
        'receipts': [],
        'date': "${date.day}/${date.month}/${date.year}",
      };
    }
  }

  // Obtener mensajes del usuario (con interceptor)
  Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final url = '$baseUrl/messages/';
      print('Obteniendo mensajes: $url');

      final response = await _makeRequestWithRetry('GET', url);

      print('Código de respuesta mensajes: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('data')) {
          final List<dynamic> messagesJson = responseData['data'];
          return messagesJson.cast<Map<String, dynamic>>();
        }
      }

      return [];
    } catch (e) {
      print('Error al obtener mensajes: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Marcar mensaje como leído (con interceptor)
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final url = '$baseUrl/messages/mark-read';
      print('Marcando mensaje como leído: $url');

      final response = await _makeRequestWithRetry('POST', url, body: {
        'message_id': messageId,
      });

      print('Código de respuesta marcar leído: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error al marcar mensaje como leído: $e');
      return false;
    }
  }

  // Obtener datos de usuario (con interceptor)
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final url = '$baseUrl/auth/me';
      print('Obteniendo datos de usuario: $url');

      final response = await _makeRequestWithRetry('GET', url);

      print('Código de respuesta getUserData: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener datos de usuario: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getUserData: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Verificar conectividad básica
  Future<bool> checkConnectivity() async {
    try {
      final url = '$baseUrl/auth/me';
      final response = await http.get(
        Uri.parse(url),
        headers: getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode != 500; // Cualquier cosa menos error de servidor
    } catch (e) {
      print('Error de conectividad: $e');
      return false;
    }
  }

  // Función auxiliar para mínimo
  int min(int a, int b) {
    return a < b ? a : b;
  }


  // Método para decodificar respuestas UTF-8 correctamente
  Map<String, dynamic> _decodeUtf8Response(String responseBody) {
    try {
      // Intentar decodificar directamente
      return jsonDecode(responseBody);
    } catch (e) {
      try {
        // Si falla, intentar con codificación UTF-8 explícita
        final utf8Bytes = utf8.encode(responseBody);
        final decodedString = utf8.decode(utf8Bytes);
        return jsonDecode(decodedString);
      } catch (e2) {
        print('Error decodificando UTF-8: $e2');
        return {};
      }
    }
  }
  
  // Método para limpiar texto con caracteres malformados
  String _cleanText(String text) {
    return text
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ãº', 'ú')
        .replaceAll('Ã±', 'ñ')
        .replaceAll('Ã"', 'Ó')
        .replaceAll('Ã', 'Á')
        .replaceAll('Ã‰', 'É')
        .replaceAll('Ã', 'Í')
        .replaceAll('Ãš', 'Ú')
        .replaceAll('Ã', 'Ñ');
  }

}
