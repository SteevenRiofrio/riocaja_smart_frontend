// lib/providers/receipts_provider.dart
import 'package:flutter/foundation.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:riocaja_smart/services/api_service.dart';

class ReceiptsProvider with ChangeNotifier {
  List<Receipt> _receipts = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  
  List<Receipt> get receipts => _receipts;
  bool get isLoading => _isLoading;
  
  // Cargar todos los comprobantes
  Future<void> loadReceipts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
       print("Intentando cargar comprobantes desde el backend...");
      _receipts = await _apiService.getAllReceipts();
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
    // Formato de fecha esperado: dd/MM/yyyy
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