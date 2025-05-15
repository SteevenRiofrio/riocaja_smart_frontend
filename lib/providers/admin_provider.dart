// lib/providers/admin_provider.dart
import 'package:flutter/material.dart';
import 'package:riocaja_smart/services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = false;
  
  List<Map<String, dynamic>> get pendingUsers => _pendingUsers;
  bool get isLoading => _isLoading;
  
  // Método para establecer el contexto
  void setContext(BuildContext context) {
    _adminService.setContext(context);
  }
  
  // Método para actualizar el token
  void setAuthToken(String? token) {
    _adminService.setAuthToken(token);
  }
  
  // Cargar usuarios pendientes
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
  
  // Aprobar usuario
  Future<bool> approveUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _adminService.approveUser(userId);
      
      if (success) {
        // Actualizar la lista local
        _pendingUsers.removeWhere((user) => user['_id'] == userId);
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
  
  // Rechazar usuario
  Future<bool> rejectUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _adminService.rejectUser(userId);
      
      if (success) {
        // Actualizar la lista local
        _pendingUsers.removeWhere((user) => user['_id'] == userId);
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
  
  // Cambiar rol de usuario
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      final success = await _adminService.changeUserRole(userId, newRole);
      
      if (success) {
        // Podríamos actualizar localmente pero necesitaríamos una lista de todos los usuarios
        // no solo los pendientes
      }
      
      return success;
    } catch (e) {
      print('Error al cambiar rol de usuario: $e');
      return false;
    }
  }
}