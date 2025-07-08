// lib/services/report_service.dart - ACTUALIZADO CON MÉTODO DE FECHAS DISPONIBLES
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:riocaja_smart/services/api_service.dart';

class ReportService {
  final ApiService _apiService = ApiService();

  // Configurar contexto y token
  void setContext(context) {
    _apiService.setContext(context);
  }

  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
  }

  // NUEVO: Obtener todas las fechas que tienen comprobantes
  Future<List<String>> getAvailableDates() async {
    try {
      print('Obteniendo fechas disponibles...');
      
      // Obtener todos los comprobantes
      final url = '${_apiService.baseUrl}/receipts/';
      final headers = _apiService.getHeaders();
      
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 60));

      if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      }

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> allReceipts = jsonResponse['data'] ?? [];
        
        // Extraer fechas únicas y ordenarlas
        Set<String> uniqueDates = {};
        
        for (var receipt in allReceipts) {
          String fecha = receipt['fecha'] as String? ?? '';
          if (fecha.isNotEmpty) {
            // Normalizar formato de fecha a dd/MM/yyyy
            String normalizedDate = _normalizeDateFormat(fecha);
            if (normalizedDate.isNotEmpty) {
              uniqueDates.add(normalizedDate);
            }
          }
        }
        
        // Convertir a lista y ordenar de más reciente a más antigua
        List<String> sortedDates = uniqueDates.toList();
        sortedDates.sort((a, b) {
          DateTime? dateA = _parseDate(a);
          DateTime? dateB = _parseDate(b);
          
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA); // Orden descendente (más reciente primero)
        });
        
        print('Fechas disponibles encontradas: ${sortedDates.length}');
        return sortedDates;
      } else {
        print('Error al obtener comprobantes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error al obtener fechas disponibles: $e');
      throw e;
    }
  }

  // Normalizar formato de fecha
  String _normalizeDateFormat(String dateStr) {
    try {
      if (dateStr.contains('-')) {
        // Convertir dd-MM-yyyy a dd/MM/yyyy
        return dateStr.replaceAll('-', '/');
      }
      
      // Validar formato dd/MM/yyyy
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          
          if (day != null && month != null && year != null &&
              day >= 1 && day <= 31 &&
              month >= 1 && month <= 12 &&
              year >= 2020 && year <= 2030) {
            // Formatear con ceros a la izquierda si es necesario
            return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
          }
        }
      }
    } catch (e) {
      print('Error al normalizar fecha: $dateStr - $e');
    }
    return '';
  }

  // Parsear fecha desde string
  DateTime? _parseDate(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // año
            int.parse(parts[1]), // mes
            int.parse(parts[0]), // día
          );
        }
      }
    } catch (e) {
      print('Error al parsear fecha: $dateStr');
    }
    return null;
  }

  // Clasificar ingresos y egresos
  Map<String, dynamic> classifyIncomeAndExpenses(List<dynamic> receipts) {
    // Definir clasificaciones
    Set<String> incomeTypes = {'DEPOSITO', 'PAGO DE SERVICIO', 'RECARGA CLARO', 'ENVIO GIRO'};
    Set<String> expenseTypes = {'RETIRO', 'EFECTIVO MOVIL', 'PAGO GIRO'};

    Map<String, double> incomes = {};
    Map<String, int> incomeCount = {};
    Map<String, double> expenses = {};
    Map<String, int> expenseCount = {};

    double totalIncomes = 0.0;
    double totalExpenses = 0.0;
    int totalIncomeCount = 0;
    int totalExpenseCount = 0;

    for (var receipt in receipts) {
      String tipo = receipt['tipo'] as String? ?? 'Desconocido';
      double valor = _extractValue(receipt['valor_total']);

      if (incomeTypes.contains(tipo.toUpperCase())) {
        // Es un ingreso
        incomes[tipo] = (incomes[tipo] ?? 0.0) + valor;
        incomeCount[tipo] = (incomeCount[tipo] ?? 0) + 1;
        totalIncomes += valor;
        totalIncomeCount++;
      } else if (expenseTypes.contains(tipo.toUpperCase())) {
        // Es un egreso
        expenses[tipo] = (expenses[tipo] ?? 0.0) + valor;
        expenseCount[tipo] = (expenseCount[tipo] ?? 0) + 1;
        totalExpenses += valor;
        totalExpenseCount++;
      }
    }

    return {
      'incomes': incomes,
      'incomeCount': incomeCount,
      'expenses': expenses,
      'expenseCount': expenseCount,
      'totalIncomes': totalIncomes,
      'totalExpenses': totalExpenses,
      'totalIncomeCount': totalIncomeCount,
      'totalExpenseCount': totalExpenseCount,
      'saldoEnCaja': totalIncomes - totalExpenses,
    };
  }

  // Extraer valor numérico
  double _extractValue(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error al convertir valor: $value');
        return 0.0;
      }
    }
    return 0.0;
  }

  // Generar reporte por fecha específica
  Future<Map<String, dynamic>> generateReportByDate(String dateStr) async {
    try {
      print('Generando reporte para fecha: $dateStr');
      
      // Intentar endpoint específico primero
      final url = '${_apiService.baseUrl}/receipts/date/$dateStr';
      final headers = _apiService.getHeaders();
      
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 60));

      if (response.statusCode == 401) {
        return _handleAuthError();
      }

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> receipts = jsonResponse['data'] ?? [];
        
        return _processReceipts(receipts, dateStr);
      } else {
        // Fallback: obtener todos y filtrar
        return await _generateReportFromAllReceipts(dateStr);
      }
    } catch (e) {
      print('Error al generar reporte: $e');
      return _generateReportFromAllReceipts(dateStr);
    }
  }

  // Generar reporte desde todos los comprobantes
  Future<Map<String, dynamic>> _generateReportFromAllReceipts(String dateStr) async {
    try {
      final url = '${_apiService.baseUrl}/receipts/';
      final headers = _apiService.getHeaders();
      
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 60));

      if (response.statusCode == 401) {
        return _handleAuthError();
      }

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> allReceipts = jsonResponse['data'] ?? [];

        // Filtrar por fecha con múltiples formatos
        String fechaConBarras = dateStr.contains('-') ? dateStr.replaceAll('-', '/') : dateStr;
        String fechaConGuiones = dateStr.contains('/') ? dateStr.replaceAll('/', '-') : dateStr;
        
        final List<dynamic> receipts = allReceipts
            .where((receipt) {
              String receiptDate = receipt['fecha'] ?? '';
              return receiptDate == dateStr || 
                     receiptDate == fechaConBarras || 
                     receiptDate == fechaConGuiones;
            })
            .toList();

        return _processReceipts(receipts, dateStr);
      } else {
        return _emptyReport(dateStr);
      }
    } catch (e) {
      print('Error al obtener todos los comprobantes: $e');
      return _emptyReport(dateStr, error: 'Error: $e');
    }
  }

  // Procesar lista de comprobantes
  Map<String, dynamic> _processReceipts(List<dynamic> receipts, String dateStr) {
    if (receipts.isEmpty) {
      return _emptyReport(dateStr);
    }

    final classification = classifyIncomeAndExpenses(receipts);

    return {
      'incomes': classification['incomes'],
      'incomeCount': classification['incomeCount'],
      'expenses': classification['expenses'],
      'expenseCount': classification['expenseCount'],
      'totalIncomes': classification['totalIncomes'],
      'totalExpenses': classification['totalExpenses'],
      'totalIncomeCount': classification['totalIncomeCount'],
      'totalExpenseCount': classification['totalExpenseCount'],
      'saldoEnCaja': classification['saldoEnCaja'],
      'count': receipts.length,
      'date': dateStr,
    };
  }

  // Manejo de error de autenticación
  Map<String, dynamic> _handleAuthError() {
    return {
      'incomes': {},
      'expenses': {},
      'saldoEnCaja': 0.0,
      'count': 0,
      'error': 'Sesión expirada',
      'needsAuth': true,
    };
  }

  // Reporte vacío
  Map<String, dynamic> _emptyReport(String dateStr, {String? error}) {
    return {
      'incomes': {},
      'incomeCount': {},
      'expenses': {},
      'expenseCount': {},
      'totalIncomes': 0.0,
      'totalExpenses': 0.0,
      'totalIncomeCount': 0,
      'totalExpenseCount': 0,
      'saldoEnCaja': 0.0,
      'count': 0,
      'date': dateStr,
      if (error != null) 'error': error,
    };
  }

  // Generar texto del reporte para compartir
  String generateReportText(Map<String, dynamic> reportData, DateTime selectedDate) {
    final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
    final incomes = reportData['incomes'] as Map<dynamic, dynamic>? ?? {};
    final incomeCount = reportData['incomeCount'] as Map<dynamic, dynamic>? ?? {};
    final expenses = reportData['expenses'] as Map<dynamic, dynamic>? ?? {};
    final expenseCount = reportData['expenseCount'] as Map<dynamic, dynamic>? ?? {};
    final totalIncomes = reportData['totalIncomes'] as double? ?? 0.0;
    final totalExpenses = reportData['totalExpenses'] as double? ?? 0.0;
    final totalIncomeCount = reportData['totalIncomeCount'] as int? ?? 0;
    final totalExpenseCount = reportData['totalExpenseCount'] as int? ?? 0;
    final saldoEnCaja = reportData['saldoEnCaja'] as double? ?? 0.0;
    final count = reportData['count'] as int? ?? 0;

    String reportText = 'REPORTE DE CIERRE - RIOCAJA SMART\n\n';
    reportText += 'FECHA: $dateStr\n';
    reportText += 'CNB: BANCO DEL BARRIO\n\n';

    if (count > 0) {
      // INGRESOS
      if (incomes.isNotEmpty) {
        reportText += 'INGRESOS EFECTIVO\n';
        reportText += '                    CANT    VALOR\n';
        incomes.forEach((key, value) {
          String tipo = key.toString().toUpperCase();
          int cantidad = incomeCount[key] ?? 0;
          String valorFormatted = (value as num).toStringAsFixed(2).padLeft(8);
          reportText += '${tipo.padRight(20)} ${cantidad.toString().padLeft(4)} \$${valorFormatted}\n';
        });
        String totalIncomesFormatted = totalIncomes.toStringAsFixed(2).padLeft(8);
        reportText += 'TOTAL INGRESOS      ${totalIncomeCount.toString().padLeft(4)} \$${totalIncomesFormatted}\n\n';
      }

      // EGRESOS
      if (expenses.isNotEmpty) {
        reportText += 'EGRESOS EFECTIVO\n';
        reportText += '                    CANT    VALOR\n';
        expenses.forEach((key, value) {
          String tipo = key.toString().toUpperCase();
          int cantidad = expenseCount[key] ?? 0;
          String valorFormatted = (value as num).toStringAsFixed(2).padLeft(8);
          reportText += '${tipo.padRight(20)} ${cantidad.toString().padLeft(4)} \$${valorFormatted}\n';
        });
        String totalExpensesFormatted = totalExpenses.toStringAsFixed(2).padLeft(8);
        reportText += 'TOTAL EGRESOS       ${totalExpenseCount.toString().padLeft(4)} \$${totalExpensesFormatted}\n\n';
      }

      reportText += 'SALDO EN CAJA                \$${saldoEnCaja.toStringAsFixed(2)}\n';
    } else {
      reportText += 'NO HAY TRANSACCIONES PARA ESTA FECHA.\n';
    }

    reportText += '\nGenerado el: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}';
    return reportText;
  }
}