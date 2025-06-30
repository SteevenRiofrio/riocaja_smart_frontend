// lib/services/auth_service.dart - ACTUALIZADO CON NUEVOS MÉTODOS
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riocaja_smart/models/user.dart';

class AuthService {
  // Usar la misma URL base que el ApiService
  String baseUrl = 'https://riocajasmartbackend-production.up.railway.app/api/v1';
  
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
              await prefs.remove(USER_DATA_KEY);
              await prefs.remove(TOKEN_EXPIRY_KEY);
              return false;
            }
            print('Token validado correctamente');
          } catch (e) {
            print('Error al validar token: $e');
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
        final responseData = jsonDecode(response.body);
        print('Registro exitoso: $responseData');
        
        return {
          'success': true,
          'message': responseData['msg'] ?? 'Usuario registrado. Espere la aprobación de un administrador.',
          'data': responseData,
        };
      } else {
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
        final responseData = jsonDecode(response.body);
        print('Login exitoso con datos: $responseData');
        
        _token = responseData['access_token'];
        
        if (_token == null || _token!.isEmpty) {
          print('ERROR: Token recibido es nulo o vacío');
          return {
            'success': false,
            'message': 'Token de autenticación no recibido',
          };
        }
        
        print('Token recibido: ${_token!.substring(0, min(10, _token!.length))}...');
        
        // Verificar si el perfil está completo
        final perfilCompleto = responseData['perfil_completo'] ?? false;
        final codigoCorresponsal = responseData['codigo_corresponsal'];
        
        // Crear datos de usuario básicos con el token
        final basicUser = User(
          id: 'temp_id',
          nombre: email.split('@')[0],
          email: email,
          rol: 'lector',
          token: _token!,
        );
        
        // Guardar inmediatamente en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(USER_DATA_KEY, jsonEncode(basicUser.toJson()));
        await prefs.setBool(REMEMBER_ME_KEY, true);
        
        // Calcular y guardar la fecha de expiración del token
        final expiryTime = DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000);
        await prefs.setInt(TOKEN_EXPIRY_KEY, expiryTime);
        
        // Intentar obtener datos adicionales del usuario
        try {
          final userData = await getUserData();
          if (userData['success']) {
            _currentUser = User(
              id: userData['data']['sub'] ?? basicUser.id,
              nombre: userData['data']['nombre'] ?? basicUser.nombre,
              email: userData['data']['email'] ?? basicUser.email,
              rol: userData['data']['rol'] ?? basicUser.rol,
              token: _token!,
            );
            
            await prefs.setString(USER_DATA_KEY, jsonEncode(_currentUser!.toJson()));
            print('Datos completos del usuario guardados');
          } else {
            _currentUser = basicUser;
            print('No se pudieron obtener datos adicionales. Usando datos básicos.');
          }
        } catch (e) {
          _currentUser = basicUser;
          print('Error al obtener datos adicionales: $e. Usando datos básicos.');
        }
        
        return {
          'success': true,
          'message': 'Sesión iniciada correctamente',
          'user': _currentUser!.toJson(),
          'perfil_completo': perfilCompleto,
          'codigo_corresponsal': codigoCorresponsal,
        };
      } else {
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

  // Completar perfil de usuario
 Future<bool> completeProfile({
  required String codigoCorresponsal,
  required String nombreLocal,
  required String nombreCompleto, // No se usa, pero se mantiene para compatibilidad
  required String password, // No se usa, pero se mantiene para compatibilidad
}) async {
  try {
    if (_token == null) {
      print('Error: No hay token de autenticación');
      return false;
    }
    
    final url = '$baseUrl/auth/complete-profile';
    print('Completando perfil en: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'codigo_corresponsal': codigoCorresponsal, // Para verificación
        'nombre_local': nombreLocal, // Único campo que se actualiza
        // NO enviamos nombre_completo ni password
      }),
    ).timeout(Duration(seconds: 60));
    
    print('Respuesta completar perfil: ${response.statusCode}');
    print('Cuerpo de respuesta: ${response.body}');
    
    if (response.statusCode == 200) {
      print('Perfil completado exitosamente');
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      print('Error al completar perfil: $errorData');
      return false;
    }
  } catch (e) {
    print('Error en completeProfile: $e');
    return false;
  }
}
  
  // NUEVO: Verificar código de corresponsal
  Future<bool> verifyCorresponsalCode(String codigo) async {
    try {
      if (_token == null) {
        print('Error: No hay token de autenticación');
        return false;
      }
      
      final url = '$baseUrl/auth/verify-code/$codigo';
      print('Verificando código en: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(Duration(seconds: 30));
      
      print('Respuesta verificación código: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['valid'] ?? false;
      } else {
        print('Error al verificar código: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error en verifyCorresponsalCode: $e');
      return false;
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
      _token = null;
      _currentUser = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(USER_DATA_KEY);
      await prefs.remove(TOKEN_EXPIRY_KEY);
      
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
  
  // Renovar token
  Future<bool> refreshToken() async {
    return false;
  }
  
  // Función auxiliar para mínimo
  int min(int a, int b) {
    return a < b ? a : b;
  }
}