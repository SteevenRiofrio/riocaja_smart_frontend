// lib/services/auth_service.dart - COMPLETO CON REFRESH TOKENS Y CORRECCIÓN DE NOMBRE
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riocaja_smart/models/user.dart';

class AuthService {
  static const String baseUrl = 'https://riocajasmartbackend-production.up.railway.app/api/v1';
  static const String USER_DATA_KEY = 'user_data';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String REMEMBER_ME_KEY = 'remember_me';
  static const String TOKEN_EXPIRY_KEY = 'token_expiry';

  String? _token;
  String? _refreshToken;
  User? _currentUser;

  // Getters
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  User? get currentUser => _currentUser;

  // Inicializar servicio (cargar sesión guardada)
  Future<bool> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(USER_DATA_KEY);
      final refreshTokenStored = prefs.getString(REFRESH_TOKEN_KEY);
      final rememberMe = prefs.getBool(REMEMBER_ME_KEY) ?? false;
      final tokenExpiry = prefs.getInt(TOKEN_EXPIRY_KEY) ?? 0;
      
      print('AuthService.init - RememberMe: $rememberMe, UserData existe: ${userData != null}');
      print('AuthService.init - Refresh token existe: ${refreshTokenStored != null}');
      
      // Verificar si el token ha expirado
      final now = DateTime.now().millisecondsSinceEpoch;
      if (tokenExpiry > 0 && now > tokenExpiry) {
        print('Access token expirado. Intentando renovar con refresh token...');
        
        if (refreshTokenStored != null && refreshTokenStored.isNotEmpty) {
          _refreshToken = refreshTokenStored;
          final refreshSuccess = await refreshAccessToken();
          
          if (!refreshSuccess) {
            print('Refresh token expirado o inválido. Cerrando sesión.');
            await logout();
            return false;
          }
        } else {
          print('No hay refresh token. Cerrando sesión.');
          await logout();
          return false;
        }
      }
      
      if (userData != null && rememberMe) {
        try {
          final userMap = jsonDecode(userData);
          _currentUser = User.fromJson(userMap);
          _token = _currentUser!.token;
          _refreshToken = refreshTokenStored ?? _currentUser!.refreshToken;
          
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
              print('Token no válido. Intentando renovar...');
              
              if (_refreshToken != null) {
                final refreshSuccess = await refreshAccessToken();
                if (!refreshSuccess) {
                  print('No se pudo renovar el token. Cerrando sesión.');
                  await logout();
                  return false;
                }
              } else {
                print('No hay refresh token para renovar');
                await logout();
                return false;
              }
            }
            print('Token validado correctamente');
          } catch (e) {
            print('Error al validar token: $e');
            // Si hay error de conexión, asumir que el token es válido
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
  Future<Map<String, dynamic>> register(String nombre, String email, String password, {String rol = 'cnb'}) async {
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
        _refreshToken = responseData['refresh_token'];
        
        if (_token == null || _token!.isEmpty) {
          print('ERROR: Token recibido es nulo o vacío');
          return {
            'success': false,
            'message': 'Token de autenticación no recibido',
          };
        }
        
        print('Token recibido: ${_token!.substring(0, min(10, _token!.length))}...');
        print('Refresh token recibido: ${_refreshToken != null ? "SÍ" : "NO"}');
        
        final perfilCompleto = responseData['perfil_completo'] ?? false;
        final codigoCorresponsal = responseData['codigo_corresponsal'];
        
        try {
          final userData = await getUserData();
          if (userData['success']) {
            _currentUser = User(
              id: userData['data']['data']['_id'],
              nombre: userData['data']['data']['nombre'],
              email: userData['data']['data']['email'],
              rol: userData['data']['data']['rol'],
              token: _token!,
              refreshToken: _refreshToken,
              estado: userData['data']['data']['estado'] ?? 'activo',
              perfilCompleto: userData['data']['data']['perfil_completo'] ?? false,
              codigoCorresponsal: userData['data']['data']['codigo_corresponsal'],
              nombreLocal: userData['data']['data']['nombre_local'],
            );
            await _saveUserData();
            print('Datos completos del usuario guardados');
          } else {
            // ✅ CORRECCIÓN: usar responseData['nombre'] directamente
            print('⚠️ No se pudieron obtener datos completos, usando datos del login');
            final String rolFromResponse = responseData['rol'];
            final bool perfilCompletoFromResponse = responseData['perfil_completo'] ?? false;
            
            _currentUser = User(
              id: 'temp_id',
              nombre: responseData['nombre'] ?? email.split('@')[0], // ✅ CORREGIDO
              email: email,
              rol: rolFromResponse,
              token: _token!,
              refreshToken: _refreshToken,
              perfilCompleto: perfilCompletoFromResponse,
            );
            await _saveUserData();
            print('Usando datos del login - Nombre: ${_currentUser!.nombre}, Rol: $rolFromResponse');
          }
        } catch (e) {
          // ✅ CORRECCIÓN: usar responseData['nombre'] directamente
          print('❌ Error al obtener datos adicionales: $e');
          final String rolFromResponse = responseData['rol'];
          final bool perfilCompletoFromResponse = responseData['perfil_completo'] ?? false;
          
          _currentUser = User(
            id: 'temp_id',
            nombre: responseData['nombre'] ?? email.split('@')[0], // ✅ CORREGIDO
            email: email,
            rol: rolFromResponse,
            token: _token!,
            refreshToken: _refreshToken,
            perfilCompleto: perfilCompletoFromResponse,
          );
          await _saveUserData();
          print('Error al obtener datos adicionales: $e. Usando nombre: ${_currentUser!.nombre}, rol: $rolFromResponse');
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

  // Renovar access token usando refresh token
Future<bool> refreshAccessToken() async {
  try {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      print('No hay refresh token disponible');
      return false;
    }
    
    final url = '$baseUrl/auth/refresh';
    print('Renovando token en: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refresh_token': _refreshToken,
      }),
    ).timeout(Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _token = responseData['access_token'];
      
      // AGREGAR ESTAS LÍNEAS SI NO ESTÁN:
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(token: _token!);
        await _saveUserData();
      }
      
      print('Token renovado exitosamente');
      return true;
    }
    return false;
  } catch (e) {
    print('Error en refreshAccessToken: $e');
    return false;
  }
}

  // Completar perfil de usuario
  Future<bool> completeProfile({
    required String codigoCorresponsal,
    required String nombreLocal,
    required String nombreCompleto, // Mantenido para compatibilidad
    required String password, // Mantenido para compatibilidad
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
          'codigo_corresponsal': codigoCorresponsal,
          'nombre_local': nombreLocal,
        }),
      ).timeout(Duration(seconds: 60));
      
      print('Respuesta completar perfil: ${response.statusCode}');
      
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
  
  // Verificar código de corresponsal
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
      
      print('Respuesta del servidor getUserData: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('Datos del usuario obtenidos correctamente');
        
        return {
          'success': true,
          'data': userData,
        };
      } else if (response.statusCode == 401) {
        // Token expirado, intentar renovar automáticamente
        print('Token expirado en getUserData, intentando renovar...');
        
        if (_refreshToken != null) {
          final refreshSuccess = await refreshAccessToken();
          if (refreshSuccess) {
            // Reintentar la petición con el nuevo token
            return await getUserData();
          }
        }
        
        return {
          'success': false,
          'message': 'Token expirado y no se pudo renovar',
          'statusCode': response.statusCode,
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
  
  // Guardar datos de usuario incluyendo refresh token y email/nombre para PDF service
  Future<void> _saveUserData() async {
    try {
      if (_currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        
        // Guardar datos del usuario
        await prefs.setString(USER_DATA_KEY, jsonEncode(_currentUser!.toJson()));
        await prefs.setBool(REMEMBER_ME_KEY, true);

        // Guardar el email y nombre por separado para otros servicios (ej: PDF)
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_name', _currentUser!.nombre);

        print('📧 Email guardado en SharedPreferences: ${_currentUser!.email}');
        print('👤 Nombre guardado en SharedPreferences: ${_currentUser!.nombre}');
        
        // Guardar refresh token por separado para mayor seguridad
        if (_refreshToken != null) {
          await prefs.setString(REFRESH_TOKEN_KEY, _refreshToken!);
        }
        
        // Calcular y guardar la fecha de expiración del access token (24 horas)
        final expiryTime = DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000);
        await prefs.setInt(TOKEN_EXPIRY_KEY, expiryTime);
        
        print('Datos de usuario guardados con refresh token');
      }
    } catch (e) {
      print('Error guardando datos de usuario: $e');
    }
  }
  
  // Cerrar sesión
  Future<bool> logout() async {
    try {
      _token = null;
      _refreshToken = null;
      _currentUser = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(USER_DATA_KEY);
      await prefs.remove(REFRESH_TOKEN_KEY);
      await prefs.remove(TOKEN_EXPIRY_KEY);
      await prefs.remove(REMEMBER_ME_KEY);
      
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
  
  // Función auxiliar para mínimo
  int min(int a, int b) {
    return a < b ? a : b;
  }
}