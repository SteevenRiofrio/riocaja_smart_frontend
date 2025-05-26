// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riocaja_smart/models/user.dart';

class AuthService {
  // Usar la misma URL base que el ApiService
  String baseUrl = 'http://34.28.127.172:8080/api/v1';
  
  // Token almacenado en memoria
  String? _token;
  
  // Usuario actual
  User? _currentUser;
  
  // Getter para el usuario actual
  User? get currentUser => _currentUser;
  
  // Getter para el token
  String? get token => _token;
  
  // Claves para SharedPreferences
  static const String USER_DATA_KEY = 'user_data';
  static const String REMEMBER_ME_KEY = 'remember_me';
  static const String TOKEN_EXPIRY_KEY = 'token_expiry';
  
  // Método para actualizar la URL base
  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    print('URL de API para autenticación actualizada a: $baseUrl');
  }
  
  /// Inicializar el servicio (cargar token almacenado)
  Future<bool> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(USER_DATA_KEY);
      final rememberMe = prefs.getBool(REMEMBER_ME_KEY) ?? false;
      final tokenExpiry = prefs.getInt(TOKEN_EXPIRY_KEY) ?? 0;
      
      print('AuthService.init - RememberMe: $rememberMe, UserData existe: ${userData != null}');
      
      // Verificar si el token ha expirado
      final now = DateTime.now().millisecondsSinceEpoch;
      if (tokenExpiry > 0 && now > tokenExpiry) {
        print('Token expirado. Se requiere nuevo inicio de sesión.');
        // Limpiar datos y solicitar nuevo inicio de sesión
        await prefs.remove(USER_DATA_KEY);
        await prefs.remove(TOKEN_EXPIRY_KEY);
        return false;
      }
      
      if (userData != null && rememberMe) {
        try {
          final userMap = jsonDecode(userData);
          _currentUser = User.fromJson(userMap);
          _token = _currentUser!.token;
          
          if (_token == null || _token!.isEmpty) {
            print('Error: Token cargado es nulo o vacío');
            return false;
          }
          
          print('Usuario cargado: ${_currentUser!.nombre}, Email: ${_currentUser!.email}');
          print('Token cargado: ${_token!.substring(0, min(10, _token!.length))}...');
          
          // Verificar validez del token con una llamada al servidor
          try {
            final validationResult = await getUserData();
            if (!validationResult['success']) {
              print('Token no válido o expirado');
              // Limpiar datos y solicitar nuevo inicio de sesión
              await prefs.remove(USER_DATA_KEY);
              await prefs.remove(TOKEN_EXPIRY_KEY);
              return false;
            }
            print('Token validado correctamente');
          } catch (e) {
            print('Error al validar token: $e');
            // En caso de error de conexión, consideramos el token válido temporalmente
            // para no bloquear al usuario, pero marcamos para revalidar después
            return true;
          }
          
          return true;
        } catch (e) {
          print('Error al decodificar datos del usuario: $e');
          return false;
        }
      }
      
      return false;
    } catch (e) {
      print('Error en init: $e');
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
        
        // Aquí el mensaje debería indicar que el usuario está pendiente de aprobación
        return {
          'success': true,
          'message': responseData['msg'] ?? 'Usuario registrado. Espere la aprobación de un administrador.',
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
      
      print('Respuesta del servidor login: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Login exitoso, parseamos la respuesta
        final responseData = jsonDecode(response.body);
        print('Login exitoso con datos: $responseData');
        
        // Extraer el token
        _token = responseData['access_token'];
        
        if (_token == null || _token!.isEmpty) {
          print('ERROR: Token recibido es nulo o vacío');
          return {
            'success': false,
            'message': 'Token de autenticación no recibido',
          };
        }
        
        print('Token recibido: ${_token!.substring(0, min(10, _token!.length))}...');
        
        // Crear datos de usuario básicos con el token
        final basicUser = User(
          id: 'temp_id',
          nombre: email.split('@')[0],
          email: email,
          rol: 'lector', // Valor por defecto
          token: _token!,
        );
        
        // Guardar inmediatamente en SharedPreferences para no perder el token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(USER_DATA_KEY, jsonEncode(basicUser.toJson()));
        await prefs.setBool(REMEMBER_ME_KEY, true);
        
        // Calcular y guardar la fecha de expiración del token (ejemplo: 24 horas)
        final expiryTime = DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000);
        await prefs.setInt(TOKEN_EXPIRY_KEY, expiryTime);
        
        print('Datos básicos guardados en SharedPreferences');
        
        // Intentar obtener datos adicionales del usuario
        try {
          final userData = await getUserData();
          if (userData['success']) {
            // Actualizar usuario con datos completos
            _currentUser = User(
              id: userData['data']['sub'] ?? basicUser.id,
              nombre: userData['data']['nombre'] ?? basicUser.nombre,
              email: userData['data']['email'] ?? basicUser.email,
              rol: userData['data']['rol'] ?? basicUser.rol,
              token: _token!,
            );
            
            // Actualizar en SharedPreferences
            await prefs.setString(USER_DATA_KEY, jsonEncode(_currentUser!.toJson()));
            print('Datos completos del usuario guardados en SharedPreferences');
          } else {
            // Si no podemos obtener datos adicionales, usar los básicos
            _currentUser = basicUser;
            print('No se pudieron obtener datos adicionales. Usando datos básicos.');
          }
        } catch (e) {
          // En caso de error, usar los datos básicos
          _currentUser = basicUser;
          print('Error al obtener datos adicionales: $e. Usando datos básicos.');
        }
        
        return {
          'success': true,
          'message': 'Sesión iniciada correctamente',
          'user': _currentUser!.toJson(),
        };
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
      await prefs.remove(USER_DATA_KEY);
      await prefs.remove(TOKEN_EXPIRY_KEY);
      
      // Importante: No eliminamos la preferencia REMEMBER_ME_KEY
      // para que se mantenga la elección del usuario
      
      print('Sesión cerrada exitosamente');
      return true;
    } catch (e) {
      print('Error al cerrar sesión: $e');
      return false;
    }
  }
  
  // Establecer la preferencia de "Recordar sesión"
  Future<bool> setRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(REMEMBER_ME_KEY, value);
      print('Preferencia de recordar sesión actualizada: $value');
      return true;
    } catch (e) {
      print('Error al establecer preferencia de recordar sesión: $e');
      return false;
    }
  }
  
  // Verificar si hay un usuario autenticado
  bool isAuthenticated() {
    return _token != null && _currentUser != null;
  }
  
  // Renovar token (implementación básica)
  Future<bool> refreshToken() async {
    // Aquí deberías implementar la lógica para renovar el token
    // usando un endpoint de refresh si tu backend lo soporta
    
    // Si no tienes un endpoint de refresh, puedes forzar un nuevo login
    // con las credenciales almacenadas (si las tienes)
    
    // Por ahora, simplemente devolvemos false para indicar que se necesita un nuevo login
    return false;
  }
  
  // Función auxiliar para mínimo
  int min(int a, int b) {
    return a < b ? a : b;
  }
}