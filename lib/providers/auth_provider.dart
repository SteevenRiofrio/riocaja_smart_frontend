import 'package:flutter/foundation.dart';
import 'package:riocaja_smart/models/user.dart';
import 'package:riocaja_smart/services/auth_service.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

        // Sincronizar tokens con ApiService
        _syncTokensWithApiService();

        print('AuthProvider: Usuario autenticado: ${_user!.nombre}');
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
      _apiService.setAuthToken(_user!.token);
      _apiService.setAuthService(_authService); // Para refresh automático
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

  // Login de usuario con refresh tokens
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Cerrar sesión anterior si existe
      await logout();

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
          print('AuthProvider: Admin/Operador autenticado - acceso completo');
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
    _isLoading = true;
    notifyListeners();

    // Limpiar AuthService
    await _authService.logout();

    // Limpiar ApiService
    _apiService.setAuthToken(null);

    // Limpiar estado local
    _user = null;
    _authStatus = AuthStatus.unauthenticated;
    _perfilCompleto = false;
    _codigoCorresponsal = null;
    _errorMessage = '';
    _isLoading = false;

    print('AuthProvider: Logout completo - todos los tokens eliminados');
    notifyListeners();
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

  // Verificar si el token está próximo a expirar
  Future<bool> isTokenNearExpiration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTime = prefs.getInt(AuthService.TOKEN_EXPIRY_KEY) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesFromNow = now + (5 * 60 * 1000); // 5 minutos

      return expiryTime > 0 && expiryTime <= fiveMinutesFromNow;
    } catch (e) {
      print('Error verificando expiración de token: $e');
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
        final userInfo = userData['data']['data'];
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

  // Actualizar el método checkAndRefreshToken existente
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
        final userInfo = userData['data']['data'];

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
}
