import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riocaja_smart/models/receipt.dart';

class StorageService {
  static const String RECEIPTS_KEY = 'receipts';
  
  // Guardar un nuevo comprobante
  Future<bool> saveReceipt(Receipt receipt) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Obtener lista existente
      List<String> receiptsJson = prefs.getStringList(RECEIPTS_KEY) ?? [];
      
      // Agregar nuevo comprobante
      receiptsJson.add(jsonEncode(receipt.toJson()));
      
      // Guardar lista actualizada
      return await prefs.setStringList(RECEIPTS_KEY, receiptsJson);
    } catch (e) {
      print('Error saving receipt: $e');
      return false;
    }
  }
  
  // Obtener todos los comprobantes
  Future<List<Receipt>> getAllReceipts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Obtener lista guardada
      List<String> receiptsJson = prefs.getStringList(RECEIPTS_KEY) ?? [];
      
      // Convertir a objetos Receipt
      return receiptsJson
          .map((json) => Receipt.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error getting receipts: $e');
      return [];
    }
  }
  
  // Eliminar un comprobante
  Future<bool> deleteReceipt(String transactionNumber) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Obtener lista existente
      List<String> receiptsJson = prefs.getStringList(RECEIPTS_KEY) ?? [];
      
      // Filtrar para eliminar el comprobante
      List<String> updatedReceipts = receiptsJson.where((json) {
        Map<String, dynamic> receipt = jsonDecode(json);
        return receipt['nroTransaccion'] != transactionNumber;
      }).toList();
      
      // Guardar lista actualizada
      return await prefs.setStringList(RECEIPTS_KEY, updatedReceipts);
    } catch (e) {
      print('Error deleting receipt: $e');
      return false;
    }
  }
  
  // Obtener comprobantes por fecha
  Future<List<Receipt>> getReceiptsByDate(DateTime date) async {
    try {
      List<Receipt> allReceipts = await getAllReceipts();
      
      // Formato de fecha esperado: dd/MM/yyyy
      String dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      
      // Filtrar por fecha - buscar en el campo 'fecha' de los comprobantes
      return allReceipts.where((receipt) => receipt.fecha == dateStr).toList();
    } catch (e) {
      print('Error getting receipts by date: $e');
      return [];
    }
  }
  
  // Limpiar todos los comprobantes (para pruebas)
  Future<bool> clearAllReceipts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.remove(RECEIPTS_KEY);
    } catch (e) {
      print('Error clearing receipts: $e');
      return false;
    }
  }
}