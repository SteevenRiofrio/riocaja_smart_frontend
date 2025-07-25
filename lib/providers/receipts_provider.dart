import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:provider/provider.dart';

int min(int a, int b) => a < b ? a : b;

class ReceiptsProvider with ChangeNotifier {
  List<Receipt> _receipts = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  
  List<Receipt> get receipts => _receipts;
  bool get isLoading => _isLoading;
  
  // Método para configurar el contexto
  void setContext(BuildContext context) {
    // Pasar el contexto al ApiService para que pueda acceder al AuthProvider
    _apiService.setContext(context);
    
    // Configurar el token actual
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      _apiService.setAuthToken(authProvider.user?.token);
    }
  }

  // ✅ NUEVO: Método para establecer el token de autenticación directamente
  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
    print('ReceiptsProvider: Token establecido: ${token != null ? token.substring(0, min(10, token.length)) : "null"}...');
  }
  
  // Cargar todos los comprobantes
// Cargar todos los comprobantes
Future<void> loadReceipts() async {
  _isLoading = true;
  notifyListeners();
  
  try {
    print("Intentando cargar comprobantes desde el backend...");
    
    // ✅ CORRECCIÓN: Obtener los datos como Map y convertirlos a Receipt
    final receiptsData = await _apiService.getAllReceipts();
    
    // Convertir cada Map a un objeto Receipt
    _receipts = receiptsData.map((receiptMap) {
      return Receipt.fromJson(receiptMap);
    }).toList();
    
    print("Comprobantes cargados exitosamente: ${_receipts.length}");
    
  } catch (e) {
    print('Error loading receipts: $e');
    _receipts = []; // Lista vacía en caso de error
  }
  
  _isLoading = false;
  notifyListeners();
}
  


  // Añadir un nuevo comprobante
  Future<bool> addReceipt(Receipt receipt) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      bool success = await _apiService.saveReceipt(receipt);
      
      if (success) {
        await loadReceipts(); // Recargar lista desde el backend
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error adding receipt: $e');
      return false;
    }
  }
  
  // Eliminar un comprobante
  Future<bool> deleteReceipt(String transactionNumber) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      bool success = await _apiService.deleteReceipt(transactionNumber);
      
      if (success) {
        _receipts.removeWhere((receipt) => receipt.nroTransaccion == transactionNumber);
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error deleting receipt: $e');
      return false;
    }
  }
  
  // Obtener comprobantes por fecha
  List<Receipt> getReceiptsByDate(DateTime date) {
    // MODIFICADO: Usar la misma lógica que la API para buscar por fecha (dd/MM/yyyy)
    // Ya que en la aplicación los comprobantes tienen el formato con barras
    String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    
    // Filtrar por fecha
    return _receipts.where((receipt) => receipt.fecha == dateStr).toList();
  }
  
  // Generar reporte de cierre para una fecha específica
  Future<Map<String, dynamic>> generateClosingReport(DateTime date) async {
    try {
      return await _apiService.getClosingReport(date);
    } catch (e) {
      print('Error generating closing report: $e');
      
      // Valor por defecto si hay error
      return {
        'summary': {},
        'total': 0.0,
        'date': date.toString(),
        'count': 0,
      };
    }
  }
}