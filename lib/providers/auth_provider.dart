// lib/providers/auth_provider.dart - CORREGIDO PARA ADMIN
import 'package:flutter/foundation.dart';
import 'package:riocaja_smart/models/user.dart';
import 'package:riocaja_smart/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  needsProfileCompletion, // Solo para usuarios normales
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
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
  bool get needsProfileCompletion => _authStatus == AuthStatus.needsProfileCompletion;
  
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
  
  // Registro de usuario
  Future<bool> register(String nombre, String email, String password, {String rol = 'lector'}) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
      
      final result = await _authService.register(nombre, email, password, rol: rol);
      
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
  
  // Login de usuario 
  Future<bool> login(String email, String password) async {
  try {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    await logout();
    
    final result = await _authService.login(email, password);
    
    _isLoading = false;
    
    if (result['success']) {
      _user = User.fromJson(result['user']);
      _perfilCompleto = result['perfil_completo'] ?? false;
      _codigoCorresponsal = result['codigo_corresponsal']; // ESTE ES EL CÓDIGO ASIGNADO
      
      // Admin y operador siempre van directamente
      if (_user!.rol == 'admin' || _user!.rol == 'operador') {
        _authStatus = AuthStatus.authenticated;
        print('AuthProvider: Admin/Operador - acceso directo');
      } else {
        // Solo usuarios normales necesitan completar perfil
        if (_perfilCompleto) {
          _authStatus = AuthStatus.authenticated;
        } else {
          // VERIFICAR QUE TIENE CÓDIGO ASIGNADO ANTES DE COMPLETAR PERFIL
          if (_codigoCorresponsal != null && _codigoCorresponsal!.isNotEmpty) {
            _authStatus = AuthStatus.needsProfileCompletion;
          } else {
            // Si no tiene código, mostrar mensaje apropiado
            _errorMessage = 'Su cuenta está aprobada pero aún no tiene código de corresponsal asignado. Contacte al administrador.';
            _authStatus = AuthStatus.unauthenticated;
            notifyListeners();
            return false;
          }
        }
        print('AuthProvider: Usuario normal - perfil completo: $_perfilCompleto, código: $_codigoCorresponsal');
      }
      
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
        
        if (_user != null) {
          _user = User(
            id: _user!.id,
            nombre: nombreCompleto,
            email: _user!.email,
            rol: _user!.rol,
            token: _user!.token,
            perfilCompleto: true,
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

  // Verificar y renovar token - CORREGIDO
  Future<bool> checkAndRefreshToken() async {
    if (_user == null || _user!.token.isEmpty) {
      return false;
    }
    
    try {
      final userData = await _authService.getUserData();
      if (userData['success']) {
        final userInfo = userData['data'];
        
        // Solo verificar perfil completo para usuarios normales
        if (_user!.rol != 'admin' && _user!.rol != 'operador') {
          _perfilCompleto = userInfo['perfil_completo'] ?? false;
          
          if (!_perfilCompleto && _authStatus == AuthStatus.authenticated) {
            _authStatus = AuthStatus.needsProfileCompletion;
            notifyListeners();
          } else if (_perfilCompleto && _authStatus == AuthStatus.needsProfileCompletion) {
            _authStatus = AuthStatus.authenticated;
            notifyListeners();
          }
        }
        
        return true;
      }
      
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        return true;
      }
      
      await logout();
      return false;
    } catch (e) {
      print('Error al verificar token: $e');
      return false;
    }
  }
  
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    await _authService.setRememberMe(value);
    notifyListeners();
  }
  
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.logout();
    
    _user = null;
    _authStatus = AuthStatus.unauthenticated;
    _perfilCompleto = false;
    _codigoCorresponsal = null;
    _isLoading = false;
    
    notifyListeners();
  }
  
  void updateBaseUrl(String newUrl) {
    _authService.updateBaseUrl(newUrl);
  }
  
  bool hasRole(String role) {
    if (_user == null) return false;
    return _user!.rol == role;
  }
}