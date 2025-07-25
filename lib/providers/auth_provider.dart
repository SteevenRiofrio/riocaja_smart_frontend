import 'package:flutter/foundation.dart';
import 'package:riocaja_smart/models/user.dart';
import 'package:riocaja_smart/services/auth_service.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  needsProfileCompletion, // Solo para usuarios normales
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService(); // ← Para sincronización

  AuthStatus _authStatus = AuthStatus.uninitialized;
  User? _user;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _perfilCompleto = false;
  String? _codigoCorresponsal;

  // ✅ NUEVAS VARIABLES PARA TÉRMINOS Y CONDICIONES
  bool _needsTermsAcceptance = false;

  // Getters
  AuthStatus get authStatus => _authStatus;
  User? get user => _user;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  bool get rememberMe => _rememberMe;
  bool get perfilCompleto => _perfilCompleto;
  String? get codigoCorresponsal => _codigoCorresponsal;
  bool get needsProfileCompletion =>
      _authStatus == AuthStatus.needsProfileCompletion;

  // ✅ NUEVO GETTER PARA TÉRMINOS
  bool get needsTermsAcceptance => _needsTermsAcceptance;

  // Getter para ApiService
  ApiService get apiService => _apiService;

  // Constructor
  AuthProvider() {
    print('Inicializando AuthProvider...');
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool(AuthService.REMEMBER_ME_KEY) ?? true;

      final success = await _authService.init();

      if (success) {
        _user = _authService.currentUser;
        _authStatus = AuthStatus.authenticated;

        print('🔑 AUTH PROVIDER DEBUG:');
        print('   Usuario: ${_user!.nombre}');
        print('   Rol: "${_user!.rol}"');
        print('   AuthStatus: $_authStatus');
        print('   Perfil completo: $_perfilCompleto');

        // ✅ CAMBIO CRÍTICO: Sincronizar tokens INMEDIATAMENTE Y ESPERAR
        _syncTokensWithApiService();
        await Future.delayed(Duration(milliseconds: 100));
        
        print('AuthProvider: Usuario autenticado: ${_user!.nombre}');

        // AGREGAR: Configurar expiración del token
        final expiryTime = DateTime.now().add(Duration(hours: 1));
        await prefs.setInt(AuthService.TOKEN_EXPIRY_KEY, expiryTime.millisecondsSinceEpoch);

      } else {
        _authStatus = AuthStatus.unauthenticated;
        print('AuthProvider: No hay usuario autenticado');
      }
    } catch (e) {
      print('Error al inicializar AuthProvider: $e');
      _authStatus = AuthStatus.unauthenticated;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Método para sincronizar tokens con ApiService
  void _syncTokensWithApiService() {
    if (_user != null && _user!.token.isNotEmpty) {
      // Configurar ApiService inmediatamente
      _apiService.setAuthToken(_user!.token);
      _apiService.setAuthService(_authService); // Para refresh automático
      
      // ✅ NUEVO:
      print('AuthProvider: Tokens sincronizados con ApiService');
    }
  }

  // Método para sincronizar después de refresh automático
  void syncTokensAfterRefresh() {
    if (_authService.isAuthenticated() && _authService.currentUser != null) {
      _user = _authService.currentUser;
      _apiService.setAuthToken(_user!.token);
      notifyListeners();
      print('AuthProvider: Tokens sincronizados después de refresh automático');
    }
  }

  // ✅ NUEVO: Verificar si el usuario necesita aceptar términos
  Future<bool> checkTermsAcceptance(String userId) async {
    try {
      final baseUrl = _apiService.baseUrl; // Usar la URL del ApiService
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/terms/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user?.token ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _needsTermsAcceptance = data['necesita_aceptar'] ?? false;
        
        print('✅ Verificación de términos:');
        print('   Usuario ID: $userId');
        print('   Acepto términos: ${data['acepto_terminos']}');
        print('   Necesita aceptar: $_needsTermsAcceptance');
        
        notifyListeners();
        return _needsTermsAcceptance;
      } else {
        print('❌ Error verificando términos: ${response.statusCode}');
        print('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error en checkTermsAcceptance: $e');
      return false;
    }
  }

  // ✅ NUEVO: Aceptar o rechazar términos y condiciones
  Future<bool> acceptTerms(String userId, bool acepta) async {
    try {
      final baseUrl = _apiService.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/terms/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user?.token ?? ''}',
        },
        body: json.encode({
          'user_id': userId,
          'acepta': acepta,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          _needsTermsAcceptance = data['necesita_aceptar'] ?? false;
          
          print('✅ ${acepta ? 'Aceptados' : 'Rechazados'} términos para usuario: $userId');
          print('   Necesita aceptar después: $_needsTermsAcceptance');
          
          notifyListeners();
          return true;
        }
      }

      print('❌ Error aceptando términos: ${response.statusCode}');
      print('   Response: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error en acceptTerms: $e');
      return false;
    }
  }

  // Registro de usuario
  Future<bool> register(
    String nombre,
    String email,
    String password, {
    String rol = 'cnb',
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final result = await _authService.register(
        nombre,
        email,
        password,
        rol: rol,
      );

      _isLoading = false;

      if (result['success']) {
        // ✅ NUEVO: Los usuarios nuevos aceptan términos automáticamente durante el registro
        print('✅ Usuario registrado - términos aceptados automáticamente');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ MODIFICADO: Login con verificación de términos
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Solo limpiar tokens sin hacer logout completo
      _apiService.setAuthToken(null);

      final result = await _authService.login(email, password);

      _isLoading = false;

      if (result['success']) {
        _user = User.fromJson(result['user']);
        _perfilCompleto = result['perfil_completo'] ?? false;
        _codigoCorresponsal = result['codigo_corresponsal'];

        // Determinar estado de autenticación basado en el rol
        if (_user!.rol == 'admin' || _user!.rol == 'asesor') {
          // Admin y asesores van directo al dashboard
          _authStatus = AuthStatus.authenticated;
          print('AuthProvider: Admin/Asesor autenticado - acceso completo');
        } else {
          // Usuarios normales: verificar perfil completo
          if (_perfilCompleto) {
            _authStatus = AuthStatus.authenticated;
            print('AuthProvider: Usuario normal autenticado - perfil completo');
          } else {
            _authStatus = AuthStatus.needsProfileCompletion;
            print('AuthProvider: Usuario normal - necesita completar perfil');
          }
        }

        // Sincronizar tokens con ApiService
        _syncTokensWithApiService();

        // ✅ NUEVO: Verificar términos inmediatamente después del login
        await checkTermsAcceptance(_user!.id);

        await _authService.setRememberMe(_rememberMe);

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _authStatus = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Completar perfil (solo para usuarios normales)
  Future<bool> completeProfile({
    required String codigoCorresponsal,
    required String nombreLocal,
    required String nombreCompleto,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final success = await _authService.completeProfile(
        codigoCorresponsal: codigoCorresponsal,
        nombreLocal: nombreLocal,
        nombreCompleto: nombreCompleto,
        password: password,
      );

      if (success) {
        _perfilCompleto = true;
        _authStatus = AuthStatus.authenticated;
        _codigoCorresponsal = codigoCorresponsal;

        // Actualizar usuario con datos completos
        if (_user != null) {
          _user = _user!.copyWith(
            nombre: nombreCompleto,
            perfilCompleto: true,
            codigoCorresponsal: codigoCorresponsal,
            nombreLocal: nombreLocal,
          );
        }

        print('AuthProvider: Perfil completado exitosamente');
      } else {
        _errorMessage = 'Error al completar perfil';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // Verificar código de corresponsal
  Future<bool> verifyCorresponsalCode(String codigo) async {
    try {
      return await _authService.verifyCorresponsalCode(codigo);
    } catch (e) {
      print('Error al verificar código: $e');
      return false;
    }
  }

  // NUEVO: Método para verificar el estado del usuario periódicamente
  Future<bool> checkUserStatus() async {
    if (_user == null || _user!.token.isEmpty) {
      return false;
    }

    try {
      final userData = await _authService.getUserData();

      if (userData['success']) {
        final userInfo = userData['data']['data'];
        final currentState = userInfo['estado'] ?? 'pendiente';

        // Si el usuario no está activo, cerrar sesión automáticamente
        if (currentState != 'activo') {
          print(
            'AuthProvider: Usuario con estado $currentState detectado - cerrando sesión',
          );

          // Mostrar mensaje específico
          String message = _getStateMessage(currentState);

          // Cerrar sesión
          await logout();

          // Mostrar notificación
          _errorMessage = message;
          notifyListeners();

          return false;
        }

        // Actualizar información del usuario si está activo
        _user = _user!.copyWith(
          nombre: userInfo['nombre'] ?? _user!.nombre,
          rol: userInfo['rol'] ?? _user!.rol,
          perfilCompleto: userInfo['perfil_completo'] ?? _user!.perfilCompleto,
          codigoCorresponsal: userInfo['codigo_corresponsal'],
          nombreLocal: userInfo['nombre_local'],
        );

        return true;
      }

      return false;
    } catch (e) {
      print('Error al verificar estado del usuario: $e');
      return false;
    }
  }

  // NUEVO: Obtener mensaje según el estado
  String _getStateMessage(String state) {
    switch (state.toLowerCase()) {
      case 'pendiente':
        return 'Su cuenta está pendiente de aprobación. Contacte al administrador.';
      case 'suspendido':
        return 'Su cuenta ha sido suspendida. Contacte al administrador.';
      case 'inactivo':
        return 'Su cuenta está inactiva. Contacte al administrador.';
      case 'rechazado':
        return 'Su cuenta ha sido rechazada. Contacte al administrador.';
      default:
        return 'Su cuenta no está disponible. Contacte al administrador.';
    }
  }

  // ✅ NUEVO: Ejecutar migración para usuarios existentes (solo admin)
  Future<bool> migrateExistingUsersTerms() async {
    try {
      final baseUrl = _apiService.baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/terms/migrate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_user?.token ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Migración completada: ${data['message']}');
        return data['success'] == true;
      }

      print('❌ Error en migración: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error en migración: $e');
      return false;
    }
  }

  // Método para forzar refresh de token manualmente
  Future<bool> refreshToken() async {
    try {
      final success = await _authService.refreshAccessToken();
      if (success) {
        _user = _authService.currentUser;
        _syncTokensWithApiService();
        notifyListeners();
        print('AuthProvider: Token renovado manualmente');
      }
      return success;
    } catch (e) {
      print('Error al renovar token manualmente: $e');
      return false;
    }
  }

  // Establecer preferencia de recordar sesión
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    await _authService.setRememberMe(value);
    notifyListeners();
  }

  // Logout con limpieza completa
  Future<void> logout() async {
    print('🚪 AuthProvider: Iniciando logout...');
    
    // ✅ NO mostrar loading durante logout
    // _isLoading = true;
    // notifyListeners();

    try {
      // Limpiar AuthService en paralelo (no esperar)
      _authService.logout(); // Sin await para que sea más rápido
      
      // Limpiar ApiService inmediatamente
      _apiService.setAuthToken(null);
      
      // Limpiar estado local inmediatamente
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
      _perfilCompleto = false;
      _codigoCorresponsal = null;
      _errorMessage = '';
      _needsTermsAcceptance = false;
      _isLoading = false; // ✅ Asegurar que no está en loading
      
      // Limpiar SharedPreferences en paralelo
      _clearUserPreferences(); // Sin await para que sea más rápido
      
      print('✅ AuthProvider: Logout completado');
      
      // ✅ Notificar INMEDIATAMENTE para que la UI cambie rápido
      notifyListeners();
      
    } catch (e) {
      print('❌ Error durante logout: $e');
      
      // Incluso si hay error, forzar el logout local
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Método auxiliar para limpiar preferencias sin bloquear
  Future<void> _clearUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.setBool('is_authenticated', false);
      // Mantener 'remember_session' para facilitar próximo login
      print('🧹 Preferencias de usuario limpiadas');
    } catch (e) {
      print('⚠️ Error limpiando preferencias: $e');
    }
  }

  // Actualizar URL base
  void updateBaseUrl(String newUrl) {
    _apiService.updateBaseUrl(newUrl);
  }

  // Verificar si el usuario tiene un rol específico
  bool hasRole(String role) {
    if (_user == null) return false;
    return _user!.rol == role;
  }

  // Método para manejar errores de autenticación global
  void handleAuthError(String error) {
    _errorMessage = error;
    notifyListeners();

    // Si es un error de token, intentar logout
    if (error.contains('token') ||
        error.contains('401') ||
        error.contains('unauthorized')) {
      print('AuthProvider: Error de autenticación detectado - cerrando sesión');
      logout();
    }
  }

  /// Verifica el estado de autenticación y restaura sesión si es posible
  Future<void> checkAuthStatus() async {
    print('🔍 AuthProvider: Iniciando verificación de estado...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberSession = prefs.getBool('remember_session') ?? false;
      final userDataString = prefs.getString('user_data');
      if (rememberSession && userDataString != null) {
        print('📱 Datos de sesión encontrados, validando...');
        final userData = json.decode(userDataString);
        _user = User.fromJson(userData);
        final tokenValid = await _verifyTokenValidity();
        if (tokenValid) {
          _authStatus = AuthStatus.authenticated;
          _perfilCompleto = _user?.perfilCompleto ?? false;
          _codigoCorresponsal = _user?.codigoCorresponsal;
          _syncTokensWithApiService();
          print('✅ AuthProvider: Sesión válida restaurada para ${_user!.nombre}');
        } else {
          print('⚠️ AuthProvider: Token expirado, intentando renovar...');
          final refreshed = await refreshToken();
          if (refreshed) {
            _authStatus = AuthStatus.authenticated;
            print('✅ AuthProvider: Token renovado exitosamente');
          } else {
            print('❌ AuthProvider: No se pudo renovar token');
            await _clearInvalidSession();
          }
        }
      } else {
        print('ℹ️ AuthProvider: No hay sesión guardada o remember_session es false');
        _authStatus = AuthStatus.unauthenticated;
      }
      print('📊 AuthProvider: Estado final - Autenticado: ${_authStatus == AuthStatus.authenticated}');
    } catch (e) {
      print('❌ AuthProvider: Error verificando estado: $e');
      await _clearInvalidSession();
    }
  }

  Future<bool> _verifyTokenValidity() async {
    try {
      if (_user?.token == null || _user!.token.isEmpty) {
        print('🔍 No hay token para verificar');
        return false;
      }
      print('🔍 Verificando validez del token...');
      final tempApiService = ApiService();
      tempApiService.setAuthToken(_user!.token);
      final userData = await tempApiService.getUserData();
      if (userData.isNotEmpty) {
        print('✅ Token válido - usuario: ${userData['nombre'] ?? 'N/A'}');
        return true;
      } else {
        print('❌ Token inválido - respuesta vacía');
        return false;
      }
    } catch (e) {
      print('❌ Token no válido: $e');
      return false;
    }
  }

  Future<void> _clearInvalidSession() async {
    try {
      print('🧹 Limpiando sesión inválida...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.setBool('is_authenticated', false);
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
      _perfilCompleto = false;
      _codigoCorresponsal = null;
      _needsTermsAcceptance = false;
      _errorMessage = '';
      print('✅ AuthProvider: Sesión inválida limpiada');
    } catch (e) {
      print('❌ Error limpiando sesión: $e');
    }
  }

  Future<bool> isTokenNearExpiration() async {
    try {
      if (_user?.token == null) return false;
      final parts = _user!.token.split('.');
      if (parts.length != 3) return false;
      final payload = parts[1];
      final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final data = json.decode(decoded);
      if (data['exp'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
        final now = DateTime.now();
        final timeUntilExpiry = expiry.difference(now);
        print('⏰ Token expira en: ${timeUntilExpiry.inMinutes} minutos');
        return timeUntilExpiry.inMinutes < 10;
      }
      return false;
    } catch (e) {
      print('❌ Error verificando expiración: $e');
      return false;
    }
  }

  Future<void> _saveTokenExpiry(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
        final decoded = utf8.decode(base64Url.decode(normalizedPayload));
        final data = json.decode(decoded);
        if (data['exp'] != null) {
          final expiry = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('token_expiry', expiry.millisecondsSinceEpoch);
          print('💾 Expiración del token guardada: $expiry');
        }
      }
    } catch (e) {
      print('❌ Error guardando expiración del token: $e');
      final defaultExpiry = DateTime.now().add(Duration(hours: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('token_expiry', defaultExpiry.millisecondsSinceEpoch);
    }
  }

  bool _isValidJWTToken(String token) {
    try {
      final parts = token.split('.');
      return parts.length == 3 && parts.every((part) => part.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  // Método para renovación proactiva de token
  Future<void> proactiveTokenRefresh() async {
    if (await isTokenNearExpiration()) {
      print('AuthProvider: Token próximo a expirar - renovando proactivamente');
      await refreshToken();
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData['success']) {
        return userData['data']['data'];
      }
      return null;
    } catch (e) {
      print('Error obteniendo datos actuales del usuario: $e');
      return null;
    }
  }

  Future<bool> checkServerConnectivity() async {
    try {
      return await _apiService.checkConnectivity();
    } catch (e) {
      print('Error verificando conectividad: $e');
      return false;
    }
  }

  Future<bool> checkSessionValidity() async {
    if (_user == null || _user!.token.isEmpty) {
      return false;
    }

    try {
      final userData = await _authService.getUserData();

      if (userData['success']) {
        // ✅ CORRECCIÓN: Verificar que los datos no sean null
        final dataResponse = userData['data'];
        if (dataResponse == null) {
          print('AuthProvider: Datos de usuario null en respuesta');
          return false;
        }

        final userInfo = dataResponse['data'] ?? dataResponse;
        if (userInfo == null) {
          print('AuthProvider: userInfo es null');
          return false;
        }

        final currentState = userInfo['estado'] ?? 'pendiente';

        // Si el usuario no está activo, cerrar sesión automáticamente
        if (currentState != 'activo') {
          print(
            'AuthProvider: Usuario con estado $currentState detectado - cerrando sesión',
          );

          String message = _getStateMessage(currentState);
          await logout();
          _errorMessage = message;
          notifyListeners();

          return false;
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Error al verificar validez de sesión: $e');

      // Si el error contiene mensaje de sesión cerrada
      if (e.toString().contains('sesión fue cerrada') ||
          e.toString().contains('otro dispositivo')) {
        print('AuthProvider: Sesión cerrada en otro dispositivo');
        await logout();
        _errorMessage =
            'Tu sesión fue cerrada porque iniciaste sesión en otro dispositivo.';
        notifyListeners();
        return false;
      }

      return false;
    }
  }

  Future<bool> checkAndRefreshToken() async {
    if (_user == null || _user!.token.isEmpty) {
      return false;
    }

    try {
      // PRIMERO: Verificar validez de la sesión
      final isValidSession = await checkSessionValidity();
      if (!isValidSession) {
        return false;
      }

      // SEGUNDO: Verificar datos del usuario y perfil
      final userData = await _authService.getUserData();

      if (userData['success']) {
        // ✅ CORRECCIÓN: Verificar que los datos no sean null
        final dataResponse = userData['data'];
        if (dataResponse == null) {
          print('AuthProvider: Datos de usuario null en checkAndRefreshToken');
          return false;
        }

        final userInfo = dataResponse['data'] ?? dataResponse;
        if (userInfo == null) {
          print('AuthProvider: userInfo es null en checkAndRefreshToken');
          return false;
        }

        // Solo verificar perfil completo para usuarios normales
        if (_user!.rol != 'admin' && _user!.rol != 'asesor') {
          _perfilCompleto = userInfo['perfil_completo'] ?? false;
          _codigoCorresponsal = userInfo['codigo_corresponsal'];

          if (!_perfilCompleto && _authStatus == AuthStatus.authenticated) {
            _authStatus = AuthStatus.needsProfileCompletion;
            notifyListeners();
          } else if (_perfilCompleto &&
              _authStatus == AuthStatus.needsProfileCompletion) {
            _authStatus = AuthStatus.authenticated;
            notifyListeners();
          }
        }

        // Actualizar usuario con datos más recientes
        _user = _user!.copyWith(
          nombre: userInfo['nombre'] ?? _user!.nombre,
          perfilCompleto: _perfilCompleto,
          codigoCorresponsal: _codigoCorresponsal,
          nombreLocal: userInfo['nombre_local'],
        );

        // ✅ NUEVO: También verificar términos durante refresh
        if (_user != null) {
          await checkTermsAcceptance(_user!.id);
        }

        return true;
      }

      // Si getUserData falló, el AuthService automáticamente intentó el refresh
      print('No se pudo verificar token ni hacer refresh - cerrando sesión');
      await logout();
      return false;
    } catch (e) {
      print('Error al verificar token: $e');

      // Verificar si es error de sesión cerrada
      if (e.toString().contains('sesión fue cerrada') ||
          e.toString().contains('otro dispositivo')) {
        await logout();
        _errorMessage =
            'Tu sesión fue cerrada porque iniciaste sesión en otro dispositivo.';
        notifyListeners();
        return false;
      }

      // En caso de error de red, asumir que el token es válido
      return true;
    }
  }

// ================================
// MÉTODOS OPTIMIZADOS para tu AuthProvider
// ================================

// ✅ CONFIGURAR usuario rápidamente SIN verificar token
void setQuickUser(User user) {
  _user = user;
  _authStatus = AuthStatus.authenticated;
  _perfilCompleto = user.perfilCompleto;
  _codigoCorresponsal = user.codigoCorresponsal;
  
  // Configurar ApiService inmediatamente
  _apiService.setAuthToken(user.token);
  _apiService.setAuthService(_authService);
  
  print('⚡ Usuario configurado rápidamente: ${user.nombre}');
  notifyListeners();
}

// ✅ VERIFICAR token SIN bloquear la UI y SIN cambiar estado hasta confirmar
Future<bool> verifyTokenQuietly() async {
  try {
    if (_user?.token == null || _user!.token.isEmpty) {
      return false;
    }
    
    print('🔍 Verificando token silenciosamente...');
    
    // Crear instancia temporal para no afectar la principal
    final tempApiService = ApiService();
    tempApiService.setAuthToken(_user!.token);
    
    // Verificar con timeout corto
    final userData = await tempApiService.getUserData()
        .timeout(Duration(seconds: 5)); // Timeout de 5 segundos
    
    if (userData.isNotEmpty) {
      print('✅ Token válido confirmado');
      return true;
    } else {
      print('❌ Token inválido');
      return false;
    }
    
  } catch (e) {
    print('❌ Error verificando token silenciosamente: $e');
    return false;
  }
}

// ✅ VERSIÓN SÚPER RÁPIDA de checkAuthStatus (solo para casos especiales)
Future<void> quickAuthCheck() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final rememberSession = prefs.getBool('remember_session') ?? false;
    final userDataString = prefs.getString('user_data');
    
    if (rememberSession && userDataString != null) {
      final userData = json.decode(userDataString);
      final user = User.fromJson(userData);
      
      if (user.token.isNotEmpty) {
        // ✅ Configurar inmediatamente, verificar después
        setQuickUser(user);
        
        // ✅ Verificar en segundo plano
        verifyTokenQuietly().then((isValid) {
          if (!isValid) {
            print('⚠️ Token inválido detectado, cerrando sesión');
            logout();
          }
        });
        
        return;
      }
    }
    
    // No hay sesión válida
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
    
  } catch (e) {
    print('❌ Error en verificación rápida: $e');
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

// ✅ LOGOUT SÚPER RÁPIDO - sin demoras
Future<void> fastLogout() async {
  print('🚪 Logout rápido iniciado...');
  
  // ✅ Limpiar estado INMEDIATAMENTE
  _user = null;
  _authStatus = AuthStatus.unauthenticated;
  _perfilCompleto = false;
  _codigoCorresponsal = null;
  _errorMessage = '';
  _needsTermsAcceptance = false;
  _isLoading = false;
  
  // ✅ Limpiar ApiService inmediatamente
  _apiService.setAuthToken(null);
  
  // ✅ Notificar INMEDIATAMENTE
  notifyListeners();
  
  // ✅ Limpiar en segundo plano (no esperar)
  _cleanupInBackground();
  
  print('⚡ Logout rápido completado');
}

// ✅ LIMPIEZA en segundo plano
Future<void> _cleanupInBackground() async {
  try {
    // Limpiar AuthService
    await _authService.logout();
    
    // Limpiar SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.setBool('is_authenticated', false);
    
    print('🧹 Limpieza en segundo plano completada');
  } catch (e) {
    print('⚠️ Error en limpieza: $e');
  }
}

// ✅ MÉTODO PARA COMPROBAR si hay sesión SIN verificar token
bool hasLocalSession() {
  try {
    // Esto se puede llamar síncronamente para decisiones rápidas
    return _user != null && 
           _user!.token.isNotEmpty && 
           _authStatus == AuthStatus.authenticated;
  } catch (e) {
    return false;
  }
}
}