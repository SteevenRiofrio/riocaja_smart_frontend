// lib/services/message_service.dart - CORREGIDO
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/models/message.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class MessageService {
  // CORREGIDO: URL base con barra final
  String baseUrl = 'https://riocajasmartbackend-production.up.railway.app/api/v1/messages/';
  String? _authToken;
  BuildContext? _context;
  
  // Método para establecer el contexto
  void setContext(BuildContext context) {
    _context = context;
    if (_context != null) {
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      if (authProvider.isAuthenticated) {
        _authToken = authProvider.user?.token;
        print('MessageService: Token configurado desde setContext: ${_authToken != null ? _authToken!.substring(0, min(10, _authToken!.length)) : "null"}...');
      } else {
        print('MessageService: Usuario no autenticado');
        _redirectToLogin('No hay sesión activa. Por favor inicie sesión.');
      }
    }
  }
  
  // Método para actualizar la URL base
  void updateBaseUrl(String apiBaseUrl) {
    // CORREGIDO: Asegurar barra final
    baseUrl = apiBaseUrl.endsWith('/') ? '${apiBaseUrl}messages/' : '${apiBaseUrl}/messages/';
  }
  
  // Método para establecer el token de autenticación
  void setAuthToken(String? token) {
    _authToken = token;
    print('MessageService: Token establecido manualmente: ${token != null ? token.substring(0, min(10, token.length)) : "null"}...');
  }
  
  // Obtener headers HTTP
  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
      print('MessageService: Incluyendo token en los headers');
    } else {
      print('MessageService: ATENCIÓN - No hay token disponible para los headers');
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
    String endpoint,  // CAMBIADO: ahora recibe solo el endpoint
    {Map<String, dynamic>? body, int maxRetries = 3}
  ) async {
    int retryCount = 0;
    Duration retryDelay = Duration(seconds: 2);
    
    // CORREGIDO: Construir URL correctamente
    String url = baseUrl;
    if (endpoint.isNotEmpty) {
      // Remover barra inicial del endpoint si existe, ya que baseUrl termina en /
      final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      url = baseUrl + cleanEndpoint;
    }
    
    print('MessageService: Petición $method a: $url');
    
    while (true) {
      try {
        http.Response response;
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(
              Uri.parse(url),
              headers: _getHeaders(),
            ).timeout(Duration(seconds: 60));
            break;
          case 'POST':
            response = await http.post(
              Uri.parse(url),
              headers: _getHeaders(),
              body: body != null ? jsonEncode(body) : null,
            ).timeout(Duration(seconds: 60));
            break;
          case 'DELETE':
            response = await http.delete(
              Uri.parse(url),
              headers: _getHeaders(),
            ).timeout(Duration(seconds: 60));
            break;
          default:
            throw Exception('Método HTTP no soportado: $method');
        }
        
        print('MessageService: Respuesta ${response.statusCode} de $url');
        
        // Verificar si el token ha expirado
        if (response.statusCode == 401) {
          print('Error 401: Token inválido o expirado en MessageService');
          
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
        
        if (e.toString().contains('Token inválido') || e.toString().contains('401')) {
          throw e;
        }
        
        if (retryCount >= maxRetries) {
          throw e;
        }
        
        await Future.delayed(retryDelay);
        retryDelay *= 2;
      }
    }
  }
  
  // CORREGIDO: Obtener mensajes para el usuario actual
  Future<List<Message>> getMessages() async {
    try {
      print('Obteniendo mensajes...');
      // CORREGIDO: Usar endpoint vacío ya que baseUrl ya incluye la ruta completa
      final response = await _retryableRequest('GET', '');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          final List<dynamic> messagesJson = jsonResponse['data'];
          print('Mensajes obtenidos: ${messagesJson.length}');
          return messagesJson.map((json) => Message.fromJson(json)).toList();
        }
      } else {
        print('Error al obtener mensajes: ${response.statusCode} - ${response.body}');
      }
      
      return [];
    } catch (e) {
      print('Error al obtener mensajes: $e');
      return [];
    }
  }
  
  // CORREGIDO: Marcar un mensaje como leído
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      print('Marcando mensaje $messageId como leído...');
      final response = await _retryableRequest(
        'POST',
        'mark-read',  // CORREGIDO: endpoint relativo
        body: {'message_id': messageId},
      );
      
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
  
  // CORREGIDO: Crear un nuevo mensaje (solo para admin/asesor)
  Future<bool> createMessage(String titulo, String contenido, String tipo, 
                           {DateTime? visibleHasta, List<String>? destinatarios}) async {
    try {
      print('Creando nuevo mensaje: $titulo');
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
      
      final response = await _retryableRequest(
        'POST',
        'create',  // CORREGIDO: endpoint relativo
        body: body,
      );
      
      print('Respuesta al crear mensaje: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al crear mensaje: $e');
      return false;
    }
  }
  
  // CORREGIDO: Eliminar un mensaje (solo para admin/asesor)
  Future<bool> deleteMessage(String messageId) async {
    try {
      print('Eliminando mensaje: $messageId');
      final response = await _retryableRequest(
        'DELETE',
        messageId,  // CORREGIDO: endpoint relativo
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error al eliminar mensaje: $e');
      return false;
    }
  }
  
  // Función auxiliar para mínimo
  int min(int a, int b) {
    return a < b ? a : b;
  }
}