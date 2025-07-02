// lib/providers/admin_provider.dart - VERSIÓN EXTENDIDA
import 'package:flutter/material.dart';
import 'package:riocaja_smart/services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  
  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _allUsers = [];  // NUEVA: Lista de todos los usuarios
  bool _isLoading = false;
  
  List<Map<String, dynamic>> get pendingUsers => _pendingUsers;
  List<Map<String, dynamic>> get allUsers => _allUsers;  // NUEVO getter
  bool get isLoading => _isLoading;
  
  // Método para establecer el contexto
  void setContext(BuildContext context) {
    _adminService.setContext(context);
  }
  
  // Método para actualizar el token
  void setAuthToken(String? token) {
    _adminService.setAuthToken(token);
  }
  
  // Cargar usuarios pendientes (existente)
  Future<void> loadPendingUsers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _pendingUsers = await _adminService.getPendingUsers();
    } catch (e) {
      print('Error al cargar usuarios pendientes: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // NUEVO: Cargar todos los usuarios
  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _allUsers = await _adminService.getAllUsers();
    } catch (e) {
      print('Error al cargar todos los usuarios: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Aprobar usuario (existente, mejorado)
  Future<bool> approveUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _adminService.approveUser(userId);
      
      if (success) {
        // Actualizar ambas listas
        _pendingUsers.removeWhere((user) => user['_id'] == userId);
        await loadAllUsers(); // Recargar todos los usuarios para mostrar el cambio
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error al aprobar usuario: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // NUEVO: Aprobar usuario con código
  Future<bool> approveUserWithCode(String userId, String codigoCorresponsal) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _adminService.approveUserWithCode(userId, codigoCorresponsal);
      
      if (success) {
        // Actualizar ambas listas
        _pendingUsers.removeWhere((user) => user['_id'] == userId);
        await loadAllUsers();
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error al aprobar usuario con código: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Rechazar usuario (existente, mejorado)
  Future<bool> rejectUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _adminService.rejectUser(userId);
      
      if (success) {
        // Actualizar ambas listas
        _pendingUsers.removeWhere((user) => user['_id'] == userId);
        await loadAllUsers();
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error al rechazar usuario: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Cambiar rol de usuario (existente, mejorado)
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      final success = await _adminService.changeUserRole(userId, newRole);
      
      if (success) {
        // Actualizar la lista local de todos los usuarios
        final userIndex = _allUsers.indexWhere((user) => user['_id'] == userId);
        if (userIndex >= 0) {
          _allUsers[userIndex]['rol'] = newRole;
          // Si es admin u asesor, marcar perfil como completo
          if (newRole == 'admin' || newRole == 'asesor') {
            _allUsers[userIndex]['perfil_completo'] = true;
          }
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      print('Error al cambiar rol de usuario: $e');
      return false;
    }
  }
  
  // NUEVO: Cambiar estado del usuario
  Future<bool> changeUserState(String userId, String newState) async {
    try {
      final success = await _adminService.changeUserState(userId, newState);
      
      if (success) {
        // Actualizar la lista local
        final userIndex = _allUsers.indexWhere((user) => user['_id'] == userId);
        if (userIndex >= 0) {
          _allUsers[userIndex]['estado'] = newState;
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      print('Error al cambiar estado de usuario: $e');
      return false;
    }
  }
  
  // NUEVO: Obtener estadísticas de usuarios
  Map<String, int> getUserStats() {
    if (_allUsers.isEmpty) {
      return {
        'total': 0,
        'activos': 0,
        'pendientes': 0,
        'suspendidos': 0,
        'inactivos': 0,
        'admins': 0,
        'asesores': 0,
        'cnbs': 0,
      };
    }
    
    int activos = 0, pendientes = 0, suspendidos = 0, inactivos = 0;
    int admins = 0, asesores  = 0, cnbs  = 0;
    
    for (var user in _allUsers) {
      // Contar por estado
      switch (user['estado']?.toLowerCase()) {
        case 'activo':
          activos++;
          break;
        case 'pendiente':
          pendientes++;
          break;
        case 'suspendido':
          suspendidos++;
          break;
        case 'inactivo':
          inactivos++;
          break;
      }
      
      // Contar por rol
      switch (user['rol']?.toLowerCase()) {
        case 'admin':
          admins++;
          break;
        case 'asesor':
          asesores++;
          break;
        case 'cnb':
        default:
          cnbs++;
          break;
      }
    }
    
    return {
      'total': _allUsers.length,
      'activos': activos,
      'pendientes': pendientes,
      'suspendidos': suspendidos,
      'inactivos': inactivos,
      'admins': admins,
      'asesores': asesores,
      'cnbs': cnbs,
    };
  }
  
  // NUEVO: Buscar usuarios por término
  List<Map<String, dynamic>> searchUsers(String searchTerm) {
    if (searchTerm.isEmpty) return _allUsers;
    
    final term = searchTerm.toLowerCase();
    return _allUsers.where((user) {
      final nombre = (user['nombre'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final codigoCorresponsal = (user['codigo_corresponsal'] ?? '').toLowerCase();
      final nombreLocal = (user['nombre_local'] ?? '').toLowerCase();
      
      return nombre.contains(term) ||
             email.contains(term) ||
             codigoCorresponsal.contains(term) ||
             nombreLocal.contains(term);
    }).toList();
  }
  
  // NUEVO: Filtrar usuarios por estado
  List<Map<String, dynamic>> filterUsersByState(String state) {
    if (state == 'todos') return _allUsers;
    
    return _allUsers.where((user) {
      return (user['estado'] ?? '').toLowerCase() == state.toLowerCase();
    }).toList();
  }
  
  // NUEVO: Filtrar usuarios por rol
  List<Map<String, dynamic>> filterUsersByRole(String role) {
    if (role == 'todos') return _allUsers;
    
    return _allUsers.where((user) {
      return (user['rol'] ?? '').toLowerCase() == role.toLowerCase();
    }).toList();
  }
  
  // NUEVO: Obtener usuario específico por ID
  Map<String, dynamic>? getUserById(String userId) {
    try {
      return _allUsers.firstWhere((user) => user['_id'] == userId);
    } catch (e) {
      return null;
    }
  }
  
  // NUEVO: Recargar todos los datos
  Future<void> refreshAllData() async {
    await Future.wait([
      loadPendingUsers(),
      loadAllUsers(),
    ]);
  }
}