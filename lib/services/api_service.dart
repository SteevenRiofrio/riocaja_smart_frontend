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

class ApiService {
  // URL base de la API
  String baseUrl = 'https://riocajasmartbackend-production.up.railway.app/api/v1';

  // Token de autenticación
  String? _authToken;

  // Contexto para acceder a los providers
  BuildContext? _context;

  // Referencia al AuthService para refresh automático
  AuthService? _authService;

  // Función auxiliar para mínimo
  int min(int a, int b) => a < b ? a : b;

  // ================================
  // MÉTODOS DE CONFIGURACIÓN
  // ================================

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

  // ================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ================================

  // Verificar que el token está disponible antes de hacer peticiones
  bool _hasValidToken() {
    if (_authToken == null || _authToken!.isEmpty) {
      print('❌ ApiService: No hay token disponible para hacer peticiones');
      return false;
    }
    return true;
  }

  // Método para esperar hasta que el token esté disponible
  Future<bool> _waitForToken({int maxWaitMs = 3000}) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    while (!_hasValidToken()) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      if (elapsed > maxWaitMs) {
        print('❌ ApiService: Timeout esperando token después de ${maxWaitMs}ms');
        return false;
      }
      
      // Intentar obtener token del contexto si está disponible
      if (_context != null) {
        final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
        if (authProvider.isAuthenticated && authProvider.user?.token != null) {
          _authToken = authProvider.user!.token;
          print('✅ ApiService: Token obtenido del AuthProvider durante espera');
          return true;
        }
      }
      
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    return true;
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

  // Método para redirigir a login
  void _redirectToLogin(String message) {
    if (_context != null) {
      Future.microtask(() {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.of(_context!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      });
    }
  }

  // Método para refrescar token cuando sea necesario
  Future<bool> _refreshTokenIfNeeded() async {
    try {
      print('🔄 Intentando refrescar token...');
      
      // Si tienes un contexto disponible, intenta refrescar desde AuthProvider
      if (_context != null) {
        final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
        if (authProvider.isAuthenticated) {
          // Aquí podrías implementar lógica de refresh token
          // Por ahora, simplemente usar el token actual del AuthProvider
          _authToken = authProvider.user?.token;
          print('✅ Token actualizado desde AuthProvider');
          return _authToken != null;
        }
      }
      
      print('❌ No se pudo refrescar el token');
      return false;
    } catch (e) {
      print('❌ Error al refrescar token: $e');
      return false;
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
        _redirectToLogin('Sesión cerrada');
      }
    } catch (e) {
      print('Error durante logout: $e');
    }
  }

  // ================================
  // MÉTODO PRINCIPAL DE PETICIONES HTTP
  // ================================

  // Método mejorado para hacer peticiones HTTP con validación de estado
  Future<http.Response> _makeRequestWithRetry(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Duration retryDelay = Duration(seconds: 2);

    while (true) {
      try {
        http.Response response;
        final headers = customHeaders ?? getHeaders();

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(Uri.parse(url), headers: headers)
                .timeout(Duration(seconds: 60));
            break;
          case 'POST':
            response = await http
                .post(
                  Uri.parse(url),
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(Duration(seconds: 60));
            break;
          case 'PUT':
            response = await http
                .put(
                  Uri.parse(url),
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(Duration(seconds: 60));
            break;
          case 'DELETE':
            response = await http
                .delete(Uri.parse(url), headers: headers)
                .timeout(Duration(seconds: 60));
            break;
          default:
            throw Exception('Método HTTP no soportado: $method');
        }

        print('ApiService: Respuesta ${response.statusCode} de $url');

        // Verificar errores específicos de estado de cuenta
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('Error ${response.statusCode}: ${response.body}');

          try {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['detail'] ?? 'Error de autenticación';

            // Verificar si es un error de sesión en otro dispositivo
            if (errorMessage.contains('sesión fue cerrada') ||
                errorMessage.contains('otro dispositivo')) {
              print('ApiService: Sesión cerrada en otro dispositivo detectada');

              // Forzar logout en el AuthProvider
              if (_context != null) {
                final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
                await authProvider.logout();

                // Mostrar mensaje específico de sesión cerrada
                _redirectToLogin('Tu sesión fue cerrada porque iniciaste sesión en otro dispositivo.');
              }
              return response;
            }

            // Verificar si es un error de estado de cuenta
            if (errorMessage.contains('pendiente') ||
                errorMessage.contains('suspendido') ||
                errorMessage.contains('inactivo') ||
                errorMessage.contains('rechazado')) {
              print('ApiService: Usuario con cuenta no activa detectado');

              // Forzar logout en el AuthProvider
              if (_context != null) {
                final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
                await authProvider.logout();

                // Redirigir a login con mensaje
                _redirectToLogin(errorMessage);
              }
              return response;
            }
          } catch (e) {
            print('Error al procesar respuesta de error: $e');
          }
        }

        // Manejar refresh automático para otros errores 401
        if (response.statusCode == 401 &&
            !url.contains('/login') &&
            !url.contains('/refresh')) {
          print('Error 401: Intentando refresh automático');

          if (_authService != null) {
            final refreshSuccess = await _authService!.refreshAccessToken();
            if (refreshSuccess) {
              print('ApiService: Token renovado automáticamente, reintentando petición');
              _authToken = _authService!.currentUser?.token;
              continue; // Reintentar la petición con el nuevo token
            }
          }

          print('ApiService: No se pudo renovar token, cerrando sesión');
          if (_context != null) {
            final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
            await authProvider.logout();
            _redirectToLogin('Sesión expirada. Por favor inicie sesión nuevamente.');
          }
        }

        return response;
      } catch (e) {
        retryCount++;
        print('ApiService: Error en petición (intento $retryCount): $e');

        if (retryCount >= maxRetries) {
          print('ApiService: Máximo de reintentos alcanzado para $url');
          rethrow;
        }

        print('ApiService: Reintentando en ${retryDelay.inSeconds} segundos...');
        await Future.delayed(retryDelay);
        retryDelay *= 2; // Backoff exponencial
      }
    }
  }

  // ================================
  // MÉTODOS DE COMPROBANTES
  // ================================

  // Obtener todos los comprobantes
  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    try {
      // Esperar hasta que el token esté disponible
      await _waitForToken();
      
      // ✅ CORRECCIÓN: Cambiar URL de '/receipts/all' a '/receipts/'
      final url = '$baseUrl/receipts/';
      print('Obteniendo todos los comprobantes desde: $url');
      
      final response = await _makeRequestWithRetry('GET', url);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // ✅ El backend retorna la estructura: {"data": [...], "count": 10, "user_role": "cnb"}
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data'];
          print('✅ Comprobantes obtenidos: ${data.length}');
          return data.cast<Map<String, dynamic>>();
        } else {
          print('⚠️ Respuesta no tiene estructura esperada');
          return [];
        }
      } else if (response.statusCode == 403) {
        print('Error 403: ${response.body}');
        throw Exception('No autorizado para obtener comprobantes');
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        throw Exception('Error de conexión: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getAllReceipts: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Guardar comprobante
  Future<bool> saveReceipt(Receipt receipt) async {
    try {
      final url = '$baseUrl/receipts/';
      print('Guardando comprobante en: $url');

      // Usar toJson() del modelo Receipt
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

  // Eliminar comprobante
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

  // Editar comprobante
  Future<bool> editReceipt(String transactionNumber, Map<String, dynamic> editData) async {
    try {
      final url = '$baseUrl/receipts/$transactionNumber';
      print('🔧 Editando comprobante: $url');
      print('🔧 Datos de edición: $editData');

      final response = await _makeRequestWithRetry('PUT', url, body: editData);

      print('🔧 Código de respuesta editar: ${response.statusCode}');
      print('🔧 Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Comprobante editado exitosamente');
        return true;
      } else {
        print('❌ Error al editar comprobante: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error en editReceipt: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener comprobantes filtrados por corresponsal
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

  // Obtener lista de corresponsales disponibles
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

  // ================================
  // MÉTODOS DE REPORTES
  // ================================

  // Obtener reporte de cierre por fecha
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
      final receiptsForDate = allReceipts.where((receipt) => receipt['fecha'] == dateStr).toList();

      // Calcular totales
      double total = receiptsForDate.fold(0.0, (sum, receipt) => sum + (receipt['valor_total'] ?? 0.0));

      // Agrupar por tipo
      Map<String, dynamic> summary = {};
      for (var receipt in receiptsForDate) {
        final tipo = receipt['tipo'] ?? 'Sin tipo';
        if (summary[tipo] == null) {
          summary[tipo] = {'count': 0, 'total': 0.0};
        }
        summary[tipo]['count']++;
        summary[tipo]['total'] += (receipt['valor_total'] ?? 0.0);
      }

      return {
        'summary': summary,
        'total': total,
        'count': receiptsForDate.length,
        'receipts': receiptsForDate,
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

  // ================================
  // MÉTODOS DE MENSAJES
  // ================================

  // Obtener mensajes del usuario
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

  // Marcar mensaje como leído
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final url = '$baseUrl/messages/mark-read';
      print('Marcando mensaje como leído: $url');

      final response = await _makeRequestWithRetry('POST', url, body: {'message_id': messageId});

      print('Código de respuesta marcar leído: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error al marcar mensaje como leído: $e');
      return false;
    }
  }

  // ================================
  // MÉTODOS DE USUARIO
  // ================================

  // Obtener datos de usuario
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

  // Método público para refrescar token
  Future<bool> refreshToken() async {
    try {
      print('ApiService: Intentando renovar token...');
      
      if (_authService != null) {
        // Usar el AuthService configurado para renovar el token
        final success = await _authService!.refreshAccessToken();
        
        if (success) {
          // Obtener el nuevo token del AuthService
          _authToken = _authService!.token;
          print('ApiService: Token renovado exitosamente');
          return true;
        } else {
          print('ApiService: Error renovando token con AuthService');
          return false;
        }
      } else if (_context != null) {
        // Usar AuthProvider como fallback
        final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
        final success = await authProvider.refreshToken();
        
        if (success) {
          _authToken = authProvider.user?.token;
          print('ApiService: Token renovado exitosamente usando AuthProvider');
          return true;
        } else {
          print('ApiService: Error renovando token con AuthProvider');
          return false;
        }
      } else {
        print('ApiService: No hay AuthService ni contexto configurado para renovar token');
        return false;
      }
    } catch (e) {
      print('ApiService: Error en refreshToken: $e');
      return false;
    }
  }

  // ================================
  // MÉTODOS DE ADMINISTRACIÓN DE USUARIOS
  // ================================

  // Obtener usuarios pendientes
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final url = '$baseUrl/auth/pending-users';
      print('Obteniendo usuarios pendientes: $url');

      final response = await _makeRequestWithRetry('GET', url);
      print('Código de respuesta usuarios pendientes: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else if (responseData['users'] != null) {
          return List<Map<String, dynamic>>.from(responseData['users']);
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener usuarios pendientes: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final url = '$baseUrl/auth/all-users';
      print('Obteniendo todos los usuarios: $url');

      final response = await _makeRequestWithRetry('GET', url);
      print('Código de respuesta todos usuarios: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else if (responseData['users'] != null) {
          return List<Map<String, dynamic>>.from(responseData['users']);
        }
      }
      return [];
    } catch (e) {
      print('Error al obtener todos los usuarios: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Aprobar usuario con código
  Future<bool> approveUserWithCode(String userId, String codigo) async {
    try {
      final url = '$baseUrl/auth/approve-user';
      print('Aprobando usuario con código: $url');

      final response = await _makeRequestWithRetry('POST', url, body: {
        'user_id': userId,
        'codigo_corresponsal': codigo,
      });

      print('Código de respuesta aprobar usuario: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error al aprobar usuario: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Rechazar usuario
  Future<bool> rejectUser(String userId, {String? reason}) async {
    try {
      final url = '$baseUrl/auth/reject-user';
      print('Rechazando usuario: $url');

      final response = await _makeRequestWithRetry('POST', url, body: {
        'user_id': userId,
        if (reason != null) 'reason': reason,
      });

      print('Código de respuesta rechazar usuario: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error al rechazar usuario: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Cambiar estado de usuario
  Future<bool> changeUserState(String userId, String newState, {String? reason}) async {
    try {
      final url = '$baseUrl/auth/change-user-state';
      print('Cambiando estado de usuario: $url');

      final response = await _makeRequestWithRetry('POST', url, body: {
        'user_id': userId,
        'state': newState,
        if (reason != null) 'reason': reason,
      });

      print('Código de respuesta cambiar estado: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error al cambiar estado de usuario: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Cambiar rol de usuario
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      final url = '$baseUrl/auth/change-role';
      print('Cambiando rol de usuario: $url');

      final response = await _makeRequestWithRetry('POST', url, body: {
        'user_id': userId,
        'role': newRole,
      });

      print('Código de respuesta cambiar rol: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error al cambiar rol de usuario: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar usuario
  Future<bool> deleteUser(String userId, {String? reason}) async {
    try {
      final url = '$baseUrl/auth/delete-user';
      print('Eliminando usuario: $url');

      final response = await _makeRequestWithRetry('POST', url, body: {
        'user_id': userId,
        if (reason != null) 'reason': reason,
      });

      print('Código de respuesta eliminar usuario: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // ================================
  // MÉTODOS DE CONECTIVIDAD
  // ================================

  // Verificar conectividad básica
  Future<bool> checkConnectivity() async {
    try {
      final url = '$baseUrl/auth/me';
      final response = await http
          .get(Uri.parse(url), headers: getHeaders())
          .timeout(Duration(seconds: 10));

      return response.statusCode != 500; // Cualquier cosa menos error de servidor
    } catch (e) {
      print('Error de conectividad: $e');
      return false;
    }
  }

  // ================================
  // MÉTODOS DE UTILIDAD
  // ================================

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