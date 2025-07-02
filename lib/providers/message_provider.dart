// lib/providers/message_provider.dart
import 'package:flutter/material.dart';
import 'package:riocaja_smart/models/message.dart';
import 'package:riocaja_smart/services/message_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  
  // Obtener solo mensajes no leídos
  List<Message> get unreadMessages {
    if (_messages.isEmpty) return [];
    
    return _messages.where((message) {
      // Si el usuario actual tiene un ID almacenado en otro lugar,
      // deberías verificar si el mensaje ya fue leído por ese usuario
      String? currentUserId = getCurrentUserId();
      if (currentUserId == null) return true; // Si no hay ID, mostrar todos
      
      return !message.isReadBy(currentUserId);
    }).toList();
  }
  
  // Método para establecer el contexto
  void setContext(BuildContext context) {
    _messageService.setContext(context);
  }
  
  // Método para actualizar el token
  void setAuthToken(String? token) {
    _messageService.setAuthToken(token);
  }
  
  // Cargar mensajes
  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _messages = await _messageService.getMessages();
    } catch (e) {
      print('Error al cargar mensajes: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Marcar mensaje como leído
  Future<void> markAsRead(String messageId) async {
    try {
      final success = await _messageService.markMessageAsRead(messageId);
      
      if (success) {
        // Actualizar localmente
        String? currentUserId = getCurrentUserId();
        if (currentUserId != null) {
          final index = _messages.indexWhere((m) => m.id == messageId);
          if (index >= 0) {
            _messages[index].leidoPor.add(currentUserId);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error al marcar mensaje como leído: $e');
    }
  }
  
  // Crear mensaje (solo admin/asesor)
  Future<bool> createMessage(String titulo, String contenido, String tipo,
                           {DateTime? visibleHasta, List<String>? destinatarios}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _messageService.createMessage(
        titulo, contenido, tipo,
        visibleHasta: visibleHasta,
        destinatarios: destinatarios
      );
      
      if (success) {
        await loadMessages(); // Recargar mensajes
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('Error al crear mensaje: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Eliminar mensaje (solo admin/asesor)
  Future<bool> deleteMessage(String messageId) async {
    try {
      final success = await _messageService.deleteMessage(messageId);
      
      if (success) {
        // Eliminar localmente
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('Error al eliminar mensaje: $e');
      return false;
    }
  }
  
  // NOTA: Este método debería obtener el ID del usuario actual
  // desde el AuthProvider en una implementación real
  String? getCurrentUserId() {
    // Implementar acceso al ID del usuario actual
    // Por ejemplo: return Provider.of<AuthProvider>(context, listen: false).user?.id;
    return null; // Placeholder
  }
}