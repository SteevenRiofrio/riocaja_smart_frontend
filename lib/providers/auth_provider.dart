// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:riocaja_smart/models/user.dart';
import 'package:riocaja_smart/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _authStatus = AuthStatus.uninitialized;
  User? _user;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _rememberMe = true; // Por defecto activado
  
  // Getters
  AuthStatus get authStatus => _authStatus;
  User? get user => _user;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  bool get rememberMe => _rememberMe;
  
  // Constructor - inicializar el proveedor
  AuthProvider() {
    print('Inicializando AuthProvider...');
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Cargar preferencia de "Recordar sesión"
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
      
      final result = await _authService.login(email, password);
      
      _isLoading = false;
      
      if (result['success']) {
        _user = User.fromJson(result['user']);
        _authStatus = AuthStatus.authenticated;
        
        // Guardar preferencia de "Recordar sesión"
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
  
  // Establecer la preferencia de "Recordar sesión"
  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    await _authService.setRememberMe(value);
    notifyListeners();
  }
  
  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.logout();
    
    _user = null;
    _authStatus = AuthStatus.unauthenticated;
    _isLoading = false;
    
    notifyListeners();
  }
  
  // Actualizar URL del API
  void updateBaseUrl(String newUrl) {
    _authService.updateBaseUrl(newUrl);
  }
  
  // Verificar si el usuario tiene cierto rol
  bool hasRole(String role) {
    if (_user == null) return false;
    return _user!.rol == role;
  }
}