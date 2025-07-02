import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';  // AÑADIR ESTE IMPORT
import 'package:provider/provider.dart';  // AÑADIR ESTE IMPORT
import 'package:riocaja_smart/providers/auth_provider.dart';  // AÑADIR ESTE IMPORT
import 'package:riocaja_smart/screens/login_screen.dart';  // AÑADIR ESTE IMPORT
import 'package:riocaja_smart/services/api_service.dart';

class AdminService {
  // URL base (existente)
  final String baseUrl;
  final ApiService _apiService = ApiService();
  
  // NUEVAS VARIABLES PARA CONTEXTO Y TOKEN
  String? _authToken;
  BuildContext? _context;

  AdminService({String? baseUrl}) 
    : baseUrl = baseUrl ?? 'https://riocajasmartbackend-production.up.railway.app/api/v1/auth';

  // NUEVO: Método para establecer el contexto
  void setContext(BuildContext context) {
    _context = context;
    // Obtener el token del AuthProvider si está disponible
    if (_context != null) {
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      if (authProvider.isAuthenticated) {
        _authToken = authProvider.user?.token;
        print('AdminService: Token configurado desde setContext: ${_authToken != null ? _authToken!.substring(0, _min(10, _authToken!.length)) : "null"}...');
      } else {
        print('AdminService: Usuario no autenticado');
        _redirectToLogin('No hay sesión activa. Por favor inicie sesión.');
      }
    }
  }
  
  // NUEVO: Método para actualizar la URL base
  void updateBaseUrl(String apiBaseUrl) {
    // El baseUrl ya está definido como final, pero podemos usar _apiService
    _apiService.updateBaseUrl(apiBaseUrl);
  }
  
  // NUEVO: Método para establecer el token de autenticación
  void setAuthToken(String? token) {
    _authToken = token;
    _apiService.setAuthToken(token);
    print('AdminService: Token establecido manualmente: ${token != null ? token.substring(0, _min(10, token.length)) : "null"}...');
  }
  
  // NUEVO: Obtener headers HTTP actualizados
  Future<Map<String, String>> getHeaders() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
      print('AdminService: Incluyendo token en los headers');
    } else {
      print('AdminService: ATENCIÓN - No hay token disponible para los headers');
      if (_context != null) {
        _redirectToLogin('No hay token de autenticación');
      }
    }
    
    return headers;
  }

  // NUEVO: Método para redirigir a login
  void _redirectToLogin(String message) {
    if (_context != null && Navigator.canPop(_context!)) {
      Future.microtask(() {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(message),
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
  
  // NUEVO: Función auxiliar para mínimo
  int _min(int a, int b) => a < b ? a : b;

Future<http.Response> _retryableRequest(
  String method,
  String url, {
  Map<String, dynamic>? body,
  int maxRetries = 3,
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      // ✅ CAMBIO CLAVE: Usar getHeaders() que incluye Authorization
      final headers = await getHeaders();
      
      print('AdminService: Petición $method a: $url');
      print('AdminService: Headers incluyen Authorization: ${headers.containsKey('Authorization')}');
      
      late http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }
      
      print('AdminService: Respuesta ${response.statusCode} de $url');
      
      // Manejar token expirado
      if (response.statusCode == 401) {
        print('AdminService: Token expirado, intentando renovar...');
        if (_context != null) {
          final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
          final refreshSuccess = await authProvider.refreshToken();
          if (refreshSuccess) {
            _authToken = authProvider.user?.token;
            continue; // Reintentar con nuevo token
          } else {
            _redirectToLogin('Sesión expirada. Por favor inicie sesión nuevamente.');
            break;
          }
        }
      }
      
      return response;
      
    } catch (e) {
      print('AdminService: Error en intento ${i + 1}: $e');
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 1));
    }
  }
  throw Exception('Máximo número de reintentos alcanzado');
}
  // ================================
  // GESTIÓN DE USUARIOS PENDIENTES
  // ================================
  
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      print('Obteniendo usuarios pendientes...');
      final response = await _retryableRequest('GET', '$baseUrl/pending-users');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Usuarios pendientes obtenidos: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Error al obtener usuarios pendientes: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error al obtener usuarios pendientes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('Obteniendo todos los usuarios...');
      final response = await _retryableRequest('GET', '$baseUrl/all-users');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Todos los usuarios obtenidos: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Error al obtener todos los usuarios: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error al obtener todos los usuarios: $e');
      return [];
    }
  }

  // ================================
  // APROBACIÓN DE USUARIOS
  // ================================
  
  Future<bool> approveUserWithCode(String userId, String codigoCorresponsal) async {
    try {
      print('Aprobando usuario $userId con código: $codigoCorresponsal');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/approve-user',
        body: {
          'user_id': userId,
          'codigo_corresponsal': codigoCorresponsal,
        },
      );
      
      if (response.statusCode == 200) {
        print('Usuario aprobado exitosamente - Email automático enviado');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Error al aprobar usuario: ${response.statusCode} - ${errorData['detail']}');
        throw Exception(errorData['detail'] ?? 'Error al aprobar usuario');
      }
    } catch (e) {
      print('Error al aprobar usuario con código: $e');
      throw e;
    }
  }

  // ================================
  // RECHAZO DE USUARIOS
  // ================================
  
  Future<bool> rejectUser(String userId, {String? reason}) async {
    try {
      print('Rechazando usuario $userId${reason != null ? " - Motivo: $reason" : ""}');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/reject-user',
        body: {
          'user_id': userId,
          if (reason != null) 'reason': reason,
        },
      );
      
      if (response.statusCode == 200) {
        print('Usuario rechazado exitosamente - Email automático enviado');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Error al rechazar usuario: ${response.statusCode} - ${errorData['detail']}');
        throw Exception(errorData['detail'] ?? 'Error al rechazar usuario');
      }
    } catch (e) {
      print('Error al rechazar usuario: $e');
      throw e;
    }
  }

  // ================================
  // CAMBIO DE ESTADOS
  // ================================
  
  Future<bool> changeUserState(String userId, String newState, {String? reason}) async {
    try {
      print('Cambiando estado del usuario $userId a $newState${reason != null ? " - Motivo: $reason" : ""}');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/change-user-state',
        body: {
          'user_id': userId,
          'state': newState,
          if (reason != null) 'reason': reason,
        },
      );
      
      if (response.statusCode == 200) {
        print('Estado cambiado exitosamente - Email automático enviado');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Error al cambiar estado: ${response.statusCode} - ${errorData['detail']}');
        throw Exception(errorData['detail'] ?? 'Error al cambiar estado');
      }
    } catch (e) {
      print('Error al cambiar estado: $e');
      throw e;
    }
  }

  // ================================
  // MÉTODOS ESPECÍFICOS POR ESTADO
  // ================================
  
  Future<bool> suspendUser(String userId, {String? reason}) async {
    return await changeUserState(userId, 'suspendido', reason: reason);
  }

  Future<bool> deactivateUser(String userId, {String? reason}) async {
    return await changeUserState(userId, 'inactivo', reason: reason);
  }

  Future<bool> activateUser(String userId, {String? reason}) async {
    return await changeUserState(userId, 'activo', reason: reason);
  }

  // ================================
  // ELIMINACIÓN DE USUARIOS
  // ================================
  
  Future<bool> deleteUser(String userId, {String? reason}) async {
    try {
      print('Eliminando usuario $userId${reason != null ? " - Motivo: $reason" : ""}');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/delete-user',
        body: {
          'user_id': userId,
          if (reason != null) 'reason': reason,
        },
      );
      
      if (response.statusCode == 200) {
        print('Usuario eliminado exitosamente - Email automático enviado');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Error al eliminar usuario: ${response.statusCode} - ${errorData['detail']}');
        throw Exception(errorData['detail'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      print('Error al eliminar usuario: $e');
      throw e;
    }
  }

  // ================================
  // CAMBIO DE ROLES
  // ================================
  
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      print('Cambiando rol del usuario $userId a $newRole');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/change-role',
        body: {
          'user_id': userId,
          'role': newRole
        },
      );
      
      if (response.statusCode == 200) {
        print('Rol cambiado exitosamente');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Error al cambiar rol: ${response.statusCode} - ${errorData['detail']}');
        throw Exception(errorData['detail'] ?? 'Error al cambiar rol');
      }
    } catch (e) {
      print('Error al cambiar rol de usuario: $e');
      throw e;
    }
  }

  // ================================
  // MÉTODOS AUXILIARES Y VALIDACIÓN
  // ================================
  
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      print('Obteniendo información del usuario: $userId');
      final response = await _retryableRequest('GET', '$baseUrl/user-info/$userId');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error al obtener información del usuario: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener información del usuario: $e');
      return null;
    }
  }

  // ================================
  // MÉTODOS DE VALIDACIÓN DE DATOS
  // ================================
  
  bool isValidCodigoCorresponsal(String codigo) {
    // Validar formato del código de corresponsal
    // Ejemplo: debe tener entre 4 y 10 caracteres alfanuméricos
    final regex = RegExp(r'^[A-Z0-9]{4,10}$');
    return regex.hasMatch(codigo.toUpperCase());
  }

  bool isValidState(String state) {
    final validStates = ['activo', 'inactivo', 'suspendido', 'pendiente', 'rechazado'];
    return validStates.contains(state.toLowerCase());
  }

  bool isValidRole(String role) {
    final validRoles = ['admin', 'asesor', 'cnb'];
    return validRoles.contains(role.toLowerCase());
  }

  // ================================
  // OPERACIONES MASIVAS
  // ================================
  
  Future<Map<String, int>> bulkApproveUsers(List<String> userIds, String codigoCorresponsalBase) async {
    int successful = 0;
    int failed = 0;

    for (int i = 0; i < userIds.length; i++) {
      try {
        final codigo = '$codigoCorresponsalBase${(i + 1).toString().padLeft(3, '0')}';
        await approveUserWithCode(userIds[i], codigo);
        successful++;
      } catch (e) {
        print('Error aprobando usuario ${userIds[i]}: $e');
        failed++;
      }
    }

    return {
      'successful': successful,
      'failed': failed,
      'total': userIds.length,
    };
  }

  Future<Map<String, int>> bulkRejectUsers(List<String> userIds, {String? reason}) async {
    int successful = 0;
    int failed = 0;

    for (String userId in userIds) {
      try {
        await rejectUser(userId, reason: reason);
        successful++;
      } catch (e) {
        print('Error rechazando usuario $userId: $e');
        failed++;
      }
    }

    return {
      'successful': successful,
      'failed': failed,
      'total': userIds.length,
    };
  }

  // ================================
  // ESTADÍSTICAS Y REPORTES
  // ================================
  
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final allUsers = await getAllUsers();
      
      Map<String, int> byState = {};
      Map<String, int> byRole = {};
      
      for (var user in allUsers) {
        final state = user['estado'] ?? 'unknown';
        final role = user['rol'] ?? 'unknown';
        
        byState[state] = (byState[state] ?? 0) + 1;
        byRole[role] = (byRole[role] ?? 0) + 1;
      }
      
      return {
        'total': allUsers.length,
        'by_state': byState,
        'by_role': byRole,
        'pending_count': byState['pendiente'] ?? 0,
        'active_count': byState['activo'] ?? 0,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'total': 0,
        'by_state': <String, int>{},
        'by_role': <String, int>{},
        'pending_count': 0,
        'active_count': 0,
      };
    }
  }

  // ================================
  // MÉTODOS LEGACY (compatibilidad)
  // ================================
  
  @Deprecated('Usar approveUserWithCode en su lugar')
  Future<bool> approveUser(String userId) async {
    // Usar código por defecto para compatibilidad
    return approveUserWithCode(userId, 'CNB001');
  }
}