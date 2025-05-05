// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riocaja_smart/models/user.dart';

class AuthService {
  // Usar la misma URL base que el ApiService
  String baseUrl = 'http://35.225.88.153:8080/api/v1';
  
  // Token almacenado en memoria
  String? _token;
  
  // Usuario actual
  User? _currentUser;
  
  // Getter para el usuario actual
  User? get currentUser => _currentUser;
  
  // Getter para el token
  String? get token => _token;
  
  // Método para actualizar la URL base
  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    print('URL de API para autenticación actualizada a: $baseUrl');
  }
  
  // Inicializar el servicio (cargar token almacenado)
  Future<bool> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        final userMap = jsonDecode(userData);
        _currentUser = User.fromJson(userMap);
        _token = _currentUser!.token;
        
        print('AuthService: Usuario cargado desde almacenamiento local');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error al inicializar AuthService: $e');
      return false;
    }
  }
  
  // Registro de nuevo usuario
  Future<Map<String, dynamic>> register(String nombre, String email, String password, {String rol = 'lector'}) async {
    try {
      final url = '$baseUrl/auth/register';
      print('Registrando usuario en: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol,
        }),
      ).timeout(Duration(seconds: 60));
      
      print('Respuesta del servidor: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registro exitoso, parseamos la respuesta
        final responseData = jsonDecode(response.body);
        print('Registro exitoso: $responseData');
        return {
          'success': true,
          'message': 'Usuario registrado exitosamente',
          'data': responseData,
        };
      } else {
        // Error en el registro
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'detail': 'Error en el servidor'};
        }
        
        print('Error en registro: $errorData');
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al registrar usuario',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Error en register: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Login de usuario
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = '$baseUrl/auth/login';
      print('Iniciando sesión en: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 60));
      
      print('Respuesta del servidor: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Login exitoso, parseamos la respuesta
        final responseData = jsonDecode(response.body);
        print('Login exitoso: $responseData');
        
        // Obtener datos del usuario con el token recibido
        _token = responseData['access_token'];
        
        // Obtener los datos del usuario
        final userData = await getUserData();
        if (userData['success']) {
          // Guardar en memoria y en SharedPreferences
          _currentUser = User(
            id: userData['data']['sub'] ?? '',
            nombre: userData['data']['email'].split('@')[0] ?? '',  // Temporal hasta recibir nombre completo
            email: userData['data']['email'] ?? '',
            rol: userData['data']['rol'] ?? 'lector',
            token: _token!,
          );
          
          // Guardar en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
          
          return {
            'success': true,
            'message': 'Sesión iniciada correctamente',
            'user': _currentUser!.toJson(),
          };
        } else {
          return {
            'success': false,
            'message': 'Error al obtener datos del usuario',
          };
        }
      } else {
        // Error en el login
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'detail': 'Error en el servidor'};
        }
        
        print('Error en login: $errorData');
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Credenciales incorrectas',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Error en login: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Obtener datos del usuario actual (con token)
  Future<Map<String, dynamic>> getUserData() async {
    try {
      if (_token == null) {
        return {
          'success': false,
          'message': 'No hay token de autenticación',
        };
      }
      
      final url = '$baseUrl/auth/me';
      print('Obteniendo datos del usuario: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 30));
      
      print('Respuesta del servidor: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('Datos del usuario: $userData');
        
        return {
          'success': true,
          'data': userData,
        };
      } else {
        print('Error al obtener datos del usuario: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Error al obtener datos del usuario',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Error en getUserData: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Cerrar sesión
  Future<bool> logout() async {
    try {
      // Eliminar datos de usuario y token
      _token = null;
      _currentUser = null;
      
      // Eliminar datos de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('user_data');
      
      print('Sesión cerrada exitosamente');
      return true;
    } catch (e) {
      print('Error al cerrar sesión: $e');
      return false;
    }
  }
  
  // Verificar si hay un usuario autenticado
  bool isAuthenticated() {
    return _token != null && _currentUser != null;
  }
}