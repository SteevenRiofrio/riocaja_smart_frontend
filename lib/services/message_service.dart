// lib/services/message_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/models/message.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';

class MessageService {
  // Misma base URL que usamos para el API
  String baseUrl = 'http://34.28.127.172/api/v1/messages';
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
    baseUrl = '$apiBaseUrl/messages';
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
  
  // Obtener mensajes para el usuario actual
  Future<List<Message>> getMessages() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl), headers: _getHeaders())
          .timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          final List<dynamic> messagesJson = jsonResponse['data'];
          return messagesJson.map((json) => Message.fromJson(json)).toList();
        }
      } else if (response.statusCode == 401 && _context != null) {
        // Token expirado
        Provider.of<AuthProvider>(_context!, listen: false).logout();
        throw Exception('Sesión expirada');
      }
      
      return [];
    } catch (e) {
      print('Error al obtener mensajes: $e');
      return [];
    }
  }
  
  // Marcar un mensaje como leído
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mark-read'),
        headers: _getHeaders(),
        body: jsonEncode({'message_id': messageId}),
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['success'] ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error al marcar mensaje como leído: $e');
      return false;
    }
  }
  
  // Crear un nuevo mensaje (solo para admin/operador)
  Future<bool> createMessage(String titulo, String contenido, String tipo, 
                           {DateTime? visibleHasta, List<String>? destinatarios}) async {
    try {
      final Map<String, dynamic> body = {
        'titulo': titulo,
        'contenido': contenido,
        'tipo': tipo,
      };
      
      if (visibleHasta != null) {
        body['visible_hasta'] = visibleHasta.toIso8601String();
      }
      
      if (destinatarios != null && destinatarios.isNotEmpty) {
        body['destinatarios'] = destinatarios;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(Duration(seconds: 30));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al crear mensaje: $e');
      return false;
    }
  }
  
  // Eliminar un mensaje (solo para admin/operador)
  Future<bool> deleteMessage(String messageId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$messageId'), headers: _getHeaders())
          .timeout(Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al eliminar mensaje: $e');
      return false;
    }
  }
}