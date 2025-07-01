// lib/services/password_reset_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riocaja_smart/services/api_service.dart';

class PasswordResetService {
  final ApiService _apiService = ApiService();
  
  // Solicitar código de recuperación
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final url = '${_apiService.baseUrl}/password-reset/forgot-password';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      ).timeout(Duration(seconds: 30));
      
      print('Request Password Reset - Status: ${response.statusCode}');
      print('Request Password Reset - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Código enviado',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al enviar código',
        };
      }
    } catch (e) {
      print('Error en requestPasswordReset: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Verificar código de recuperación
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final url = '${_apiService.baseUrl}/password-reset/verify-reset-code';

      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        }),
      ).timeout(Duration(seconds: 30));
      
      print('Verify Reset Code - Status: ${response.statusCode}');
      print('Verify Reset Code - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Código verificado',
          'reset_id': responseData['reset_id'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Código inválido',
        };
      }
    } catch (e) {
      print('Error en verifyResetCode: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Cambiar contraseña
  Future<Map<String, dynamic>> resetPassword(
    String email, 
    String code, 
    String newPassword
  ) async {
    try {
      final url = '${_apiService.baseUrl}/password-reset/reset-password';

      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'new_password': newPassword,
        }),
      ).timeout(Duration(seconds: 30));
      
      print('Reset Password - Status: ${response.statusCode}');
      print('Reset Password - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? false,
          'message': responseData['message'] ?? 'Contraseña actualizada',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al cambiar contraseña',
        };
      }
    } catch (e) {
      print('Error en resetPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Obtener estadísticas de reset
  Future<Map<String, dynamic>> getResetStats(String email) async {
    try {
      final url = '${_apiService.baseUrl}/password-reset/reset-stats/${Uri.encodeComponent(email)}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));
      
      print('Reset Stats - Status: ${response.statusCode}');
      print('Reset Stats - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener estadísticas',
        };
      }
    } catch (e) {
      print('Error en getResetStats: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}