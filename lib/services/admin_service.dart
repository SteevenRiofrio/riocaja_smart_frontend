// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';

class AdminService {
  // Misma base URL que usamos para el API
  String baseUrl = 'http://34.28.127.172/api/v1/auth';
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
  }
  
  // Obtener headers HTTP
  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  // Obtener usuarios pendientes
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/pending-users'), headers: _getHeaders())
          .timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        return users.map((user) => user as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401 && _context != null) {
        // Token expirado
        Provider.of<AuthProvider>(_context!, listen: false).logout();
        throw Exception('Sesión expirada');
      }
      
      return [];
    } catch (e) {
      print('Error al obtener usuarios pendientes: $e');
      return [];
    }
  }
  
  // Aprobar un usuario
  Future<bool> approveUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/approve-user'),
        headers: _getHeaders(),
        body: jsonEncode({'user_id': userId}),
      ).timeout(Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al aprobar usuario: $e');
      return false;
    }
  }
  
  // Rechazar un usuario
  Future<bool> rejectUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reject-user'),
        headers: _getHeaders(),
        body: jsonEncode({'user_id': userId}),
      ).timeout(Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al rechazar usuario: $e');
      return false;
    }
  }
  
  // Cambiar rol de un usuario
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-role'),
        headers: _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'role': newRole
        }),
      ).timeout(Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al cambiar rol de usuario: $e');
      return false;
    }
  }
}