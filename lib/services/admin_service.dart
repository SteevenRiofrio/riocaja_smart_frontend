// lib/services/admin_service.dart - VERSIÓN EXTENDIDA
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class AdminService {
  // Misma base URL que usamos para el API
  String baseUrl = 'http://34.61.195.206:8080/api/v1/auth';
  String? _authToken;
  BuildContext? _context;
  
  // Método para establecer el contexto
  void setContext(BuildContext context) {
    _context = context;
    // Obtener el token del AuthProvider si está disponible
    if (_context != null) {
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      if (authProvider.isAuthenticated) {
        _authToken = authProvider.user?.token;
        print('AdminService: Token configurado desde setContext: ${_authToken != null ? _authToken!.substring(0, min(10, _authToken!.length)) : "null"}...');
      } else {
        print('AdminService: Usuario no autenticado');
        _redirectToLogin('No hay sesión activa. Por favor inicie sesión.');
      }
    }
  }
  
  // Método para actualizar la URL base
  void updateBaseUrl(String apiBaseUrl) {
    baseUrl = '$apiBaseUrl/auth';
  }
  
  // Método para establecer el token de autenticación
  void setAuthToken(String? token) {
    _authToken = token;
    print('AdminService: Token establecido manualmente: ${token != null ? token.substring(0, min(10, token.length)) : "null"}...');
  }
  
  // Obtener headers HTTP
  Map<String, String> _getHeaders() {
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

  // Método para redirigir a login
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
  
  // Método para realizar peticiones HTTP con reintentos
  Future<http.Response> _retryableRequest(
    String method, 
    String url, 
    {Map<String, dynamic>? body, int maxRetries = 3}
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
              headers: _getHeaders(),
            ).timeout(Duration(seconds: 30));
            break;
          case 'POST':
            response = await http.post(
              Uri.parse(url),
              headers: _getHeaders(),
              body: body != null ? jsonEncode(body) : null,
            ).timeout(Duration(seconds: 30));
            break;
          case 'PUT':
            response = await http.put(
              Uri.parse(url),
              headers: _getHeaders(),
              body: body != null ? jsonEncode(body) : null,
            ).timeout(Duration(seconds: 30));
            break;
          default:
            throw Exception('Método HTTP no soportado: $method');
        }
        
        // Verificar si el token ha expirado
        if (response.statusCode == 401) {
          print('Error 401: Token inválido o expirado en AdminService');
          
          // Cerrar sesión y redirigir a login
          if (_context != null) {
            final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
            await authProvider.logout();
            _redirectToLogin('Sesión expirada. Por favor inicie sesión nuevamente.');
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
  
  // Obtener usuarios pendientes (existente)
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      print('Obteniendo usuarios pendientes...');
      final response = await _retryableRequest('GET', '$baseUrl/pending-users');
      
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        print('Usuarios pendientes obtenidos: ${users.length}');
        return users.map((user) => user as Map<String, dynamic>).toList();
      } else {
        print('Error al obtener usuarios pendientes: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error al obtener usuarios pendientes: $e');
      return [];
    }
  }
  
  // NUEVO: Obtener todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('Obteniendo todos los usuarios...');
      final response = await _retryableRequest('GET', '$baseUrl/all-users');
      
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        print('Todos los usuarios obtenidos: ${users.length}');
        return users.map((user) => user as Map<String, dynamic>).toList();
      } else {
        print('Error al obtener todos los usuarios: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error al obtener todos los usuarios: $e');
      return [];
    }
  }
  
  // Aprobar usuario con código (existente)
  Future<bool> approveUserWithCode(String userId, String codigoCorresponsal) async {
    try {
      print('Aprobando usuario $userId con código: $codigoCorresponsal');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/approve-user-with-code',
        body: {
          'user_id': userId,
          'codigo_corresponsal': codigoCorresponsal,
        },
      );
      
      if (response.statusCode == 200) {
        print('Usuario aprobado exitosamente con código');
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
  
  // Aprobar usuario (existente)
  Future<bool> approveUser(String userId) async {
    try {
      print('Aprobando usuario con ID: $userId');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/approve-user',
        body: {'user_id': userId},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al aprobar usuario: $e');
      return false;
    }
  }
  
  // Rechazar usuario (existente)
  Future<bool> rejectUser(String userId) async {
    try {
      print('Rechazando usuario con ID: $userId');
      final response = await _retryableRequest(
        'POST',
        '$baseUrl/reject-user',
        body: {'user_id': userId},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al rechazar usuario: $e');
      return false;
    }
  }
  
  // Cambiar rol de usuario (existente)
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
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al cambiar rol de usuario: $e');
      return false;
    }
  }
  
  // NUEVO: Cambiar estado del usuario
  Future<bool> changeUserState(String userId, String newState) async {
    try {
      print('Cambiando estado del usuario $userId a $newState');
      final response = await _retryableRequest(
        'PUT',
        '$baseUrl/change-state',
        body: {
          'user_id': userId,
          'state': newState
        },
      );
      
      if (response.statusCode == 200) {
        print('Estado de usuario cambiado exitosamente');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Error al cambiar estado: ${response.statusCode} - ${errorData['detail']}');
        return false;
      }
    } catch (e) {
      print('Error al cambiar estado de usuario: $e');
      return false;
    }
  }
  
  // NUEVO: Obtener detalles de un usuario específico
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      print('Obteniendo detalles del usuario: $userId');
      final response = await _retryableRequest('GET', '$baseUrl/user-details/$userId');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('Detalles del usuario obtenidos');
        return userData as Map<String, dynamic>;
      } else {
        print('Error al obtener detalles del usuario: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener detalles del usuario: $e');
      return null;
    }
  }
  
  // NUEVO: Buscar usuarios
  Future<List<Map<String, dynamic>>> searchUsers(String searchTerm) async {
    try {
      print('Buscando usuarios con término: $searchTerm');
      final response = await _retryableRequest(
        'GET', 
        '$baseUrl/search-users?q=${Uri.encodeComponent(searchTerm)}'
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        print('Usuarios encontrados: ${users.length}');
        return users.map((user) => user as Map<String, dynamic>).toList();
      } else {
        print('Error al buscar usuarios: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error al buscar usuarios: $e');
      return [];
    }
  }
  
  // NUEVO: Obtener estadísticas de usuarios
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      print('Obteniendo estadísticas de usuarios...');
      final response = await _retryableRequest('GET', '$baseUrl/user-stats');
      
      if (response.statusCode == 200) {
        final stats = jsonDecode(response.body);
        print('Estadísticas obtenidas');
        return stats as Map<String, dynamic>;
      } else {
        print('Error al obtener estadísticas: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Error al obtener estadísticas de usuarios: $e');
      return {};
    }
  }
  
  // Función auxiliar para mínimo
  int min(int a, int b) {
    return a < b ? a : b;
  }
}