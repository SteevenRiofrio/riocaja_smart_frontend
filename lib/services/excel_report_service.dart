// lib/services/excel_report_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:riocaja_smart/models/receipt.dart';

class ExcelReportService {
  final ApiService _apiService = ApiService();
  BuildContext? _context;
  
  void setContext(BuildContext context) {
    _context = context;
    _apiService.setContext(context);
  }
  
  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
  }

  // Generar reporte por día específico
  Future<bool> generateDailyReport(DateTime date) async {
    try {
      final receipts = await _getReceiptsByDate(date);
      if (receipts.isEmpty) {
        _showMessage('No hay comprobantes para la fecha seleccionada');
        return false;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Reporte Diario'];
      
      await _buildDailyReportSheet(sheet, receipts, date);
      
      final fileName = 'Reporte_Diario_${DateFormat('dd-MM-yyyy').format(date)}.xlsx';
      return await _saveAndShareExcel(excel, fileName);
    } catch (e) {
      _showError('Error generando reporte diario: $e');
      return false;
    }
  }

  // Generar reporte por rango de fechas
  Future<bool> generateRangeReport(DateTime startDate, DateTime endDate) async {
    try {
      final receipts = await _getReceiptsByDateRange(startDate, endDate);
      if (receipts.isEmpty) {
        _showMessage('No hay comprobantes para el rango de fechas seleccionado');
        return false;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Reporte Rango'];
      
      await _buildRangeReportSheet(sheet, receipts, startDate, endDate);
      
      final startStr = DateFormat('dd-MM-yyyy').format(startDate);
      final endStr = DateFormat('dd-MM-yyyy').format(endDate);
      final fileName = 'Reporte_Rango_${startStr}_al_${endStr}.xlsx';
      
      return await _saveAndShareExcel(excel, fileName);
    } catch (e) {
      _showError('Error generando reporte por rango: $e');
      return false;
    }
  }

  // Generar reporte semanal
  Future<bool> generateWeeklyReport(DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(Duration(days: 6));
      final receipts = await _getReceiptsByDateRange(weekStart, weekEnd);
      
      if (receipts.isEmpty) {
        _showMessage('No hay comprobantes para la semana seleccionada');
        return false;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Reporte Semanal'];
      
      await _buildWeeklyReportSheet(sheet, receipts, weekStart, weekEnd);
      
      final startStr = DateFormat('dd-MM-yyyy').format(weekStart);
      final fileName = 'Reporte_Semanal_${startStr}.xlsx';
      
      return await _saveAndShareExcel(excel, fileName);
    } catch (e) {
      _showError('Error generando reporte semanal: $e');
      return false;
    }
  }

  // Generar reporte mensual
  Future<bool> generateMonthlyReport(DateTime month) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      final receipts = await _getReceiptsByDateRange(startDate, endDate);
      
      if (receipts.isEmpty) {
        _showMessage('No hay comprobantes para el mes seleccionado');
        return false;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Reporte Mensual'];
      
      await _buildMonthlyReportSheet(sheet, receipts, month);
      
      final monthStr = DateFormat('MM-yyyy').format(month);
      final fileName = 'Reporte_Mensual_${monthStr}.xlsx';
      
      return await _saveAndShareExcel(excel, fileName);
    } catch (e) {
      _showError('Error generando reporte mensual: $e');
      return false;
    }
  }

  // Obtener comprobantes por fecha específica
  Future<List<Receipt>> _getReceiptsByDate(DateTime date) async {
    final allReceipts = await _apiService.getAllReceipts();
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    
    return allReceipts.where((receipt) => receipt.fecha == dateStr).toList();
  }

  // Obtener comprobantes por rango de fechas
  Future<List<Receipt>> _getReceiptsByDateRange(DateTime startDate, DateTime endDate) async {
    final allReceipts = await _apiService.getAllReceipts();
    
    return allReceipts.where((receipt) {
      final receiptDate = _parseDate(receipt.fecha);
      if (receiptDate == null) return false;
      
      return receiptDate.isAfter(startDate.subtract(Duration(days: 1))) &&
             receiptDate.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
  }

  // Construir hoja de reporte diario
  Future<void> _buildDailyReportSheet(Sheet sheet, List<Receipt> receipts, DateTime date) async {
    // Configurar ancho de columnas
    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 25);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 20);
    
    int row = 0;
    
    // HEADER DEL REPORTE
    _addHeaderCell(sheet, 0, row, 'REPORTE DIARIO - RIOCAJA SMART', isTitle: true);
    row += 2;
    
    _addCell(sheet, 0, row, 'Fecha:');
    _addCell(sheet, 1, row, DateFormat('dd/MM/yyyy').format(date));
    row++;
    
    _addCell(sheet, 0, row, 'Generado:');
    _addCell(sheet, 1, row, DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()));
    row++;
    
    final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
    _addCell(sheet, 0, row, 'Usuario:');
    _addCell(sheet, 1, row, authProvider.user?.nombre ?? 'Sistema');
    row += 2;

    // RESUMEN EJECUTIVO
    final summary = _generateSummary(receipts);
    _addHeaderCell(sheet, 0, row, 'RESUMEN EJECUTIVO');
    row++;
    
    _addCell(sheet, 0, row, 'Total Transacciones:');
    _addCell(sheet, 1, row, receipts.length.toString());
    row++;
    
    _addCell(sheet, 0, row, 'Total Ingresos:');
    _addCell(sheet, 1, row, '\$${summary['totalIncomes'].toStringAsFixed(2)}');
    row++;
    
    _addCell(sheet, 0, row, 'Total Egresos:');
    _addCell(sheet, 1, row, '\$${summary['totalExpenses'].toStringAsFixed(2)}');
    row++;
    
    _addCell(sheet, 0, row, 'Saldo en Caja:');
    _addCell(sheet, 1, row, '\$${summary['balance'].toStringAsFixed(2)}');
    row += 2;

    // DETALLE DE TRANSACCIONES
    _addHeaderCell(sheet, 0, row, 'DETALLE DE TRANSACCIONES');
    row++;
    
    // Headers de tabla
    _addHeaderCell(sheet, 0, row, 'FECHA');
    _addHeaderCell(sheet, 1, row, 'HORA');
    _addHeaderCell(sheet, 2, row, 'TIPO');
    _addHeaderCell(sheet, 3, row, 'TRANSACCIÓN');
    _addHeaderCell(sheet, 4, row, 'VALOR');
    if (authProvider.hasRole('admin') || authProvider.hasRole('operador')) {
      _addHeaderCell(sheet, 5, row, 'CORRESPONSAL');
    }
    row++;

    // Datos de comprobantes
    for (final receipt in receipts) {
      _addCell(sheet, 0, row, receipt.fecha);
      _addCell(sheet, 1, row, receipt.hora);
      _addCell(sheet, 2, row, receipt.tipo);
      _addCell(sheet, 3, row, receipt.nroTransaccion);
      _addCurrencyCell(sheet, 4, row, receipt.valorTotal);
      
      if (authProvider.hasRole('admin') || authProvider.hasRole('operador')) {
        _addCell(sheet, 5, row, receipt.codigoCorresponsal ?? 'N/A');
      }
      row++;
    }
  }

  // Construir hoja de reporte por rango
  Future<void> _buildRangeReportSheet(Sheet sheet, List<Receipt> receipts, DateTime startDate, DateTime endDate) async {
    int row = 0;
    
    // HEADER
    _addHeaderCell(sheet, 0, row, 'REPORTE POR RANGO - RIOCAJA SMART', isTitle: true);
    row += 2;
    
    _addCell(sheet, 0, row, 'Desde:');
    _addCell(sheet, 1, row, DateFormat('dd/MM/yyyy').format(startDate));
    row++;
    
    _addCell(sheet, 0, row, 'Hasta:');
    _addCell(sheet, 1, row, DateFormat('dd/MM/yyyy').format(endDate));
    row++;
    
    _addCell(sheet, 0, row, 'Días incluidos:');
    _addCell(sheet, 1, row, endDate.difference(startDate).inDays + 1);
    row += 2;

    // RESUMEN POR DÍAS
    final dailySummary = _generateDailySummary(receipts);
    _addHeaderCell(sheet, 0, row, 'RESUMEN POR DÍAS');
    row++;
    
    _addHeaderCell(sheet, 0, row, 'FECHA');
    _addHeaderCell(sheet, 1, row, 'TRANSACCIONES');
    _addHeaderCell(sheet, 2, row, 'INGRESOS');
    _addHeaderCell(sheet, 3, row, 'EGRESOS');
    _addHeaderCell(sheet, 4, row, 'SALDO');
    row++;

    for (final day in dailySummary.entries) {
      _addCell(sheet, 0, row, day.key);
      _addCell(sheet, 1, row, day.value['count'].toString());
      _addCurrencyCell(sheet, 2, row, day.value['incomes']);
      _addCurrencyCell(sheet, 3, row, day.value['expenses']);
      _addCurrencyCell(sheet, 4, row, day.value['balance']);
      row++;
    }
    
    row += 2;
    await _addDetailedTransactions(sheet, receipts, row);
  }

  // Construir hoja de reporte semanal
  Future<void> _buildWeeklyReportSheet(Sheet sheet, List<Receipt> receipts, DateTime weekStart, DateTime weekEnd) async {
    int row = 0;
    
    _addHeaderCell(sheet, 0, row, 'REPORTE SEMANAL - RIOCAJA SMART', isTitle: true);
    row += 2;
    
    _addCell(sheet, 0, row, 'Semana del:');
    _addCell(sheet, 1, row, '${DateFormat('dd/MM/yyyy').format(weekStart)} al ${DateFormat('dd/MM/yyyy').format(weekEnd)}');
    row += 2;

    // RESUMEN POR DÍAS DE LA SEMANA
    final weeklyData = _generateWeeklyData(receipts, weekStart);
    _addHeaderCell(sheet, 0, row, 'RESUMEN POR DÍAS');
    row++;
    
    _addHeaderCell(sheet, 0, row, 'DÍA');
    _addHeaderCell(sheet, 1, row, 'FECHA');
    _addHeaderCell(sheet, 2, row, 'TRANSACCIONES');
    _addHeaderCell(sheet, 3, row, 'TOTAL');
    row++;

    final daysOfWeek = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    for (int i = 0; i < 7; i++) {
      final currentDate = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('dd/MM/yyyy').format(currentDate);
      final dayData = weeklyData[dateStr] ?? {'count': 0, 'total': 0.0};
      
      _addCell(sheet, 0, row, daysOfWeek[i]);
      _addCell(sheet, 1, row, dateStr);
      _addCell(sheet, 2, row, dayData['count'].toString());
      _addCurrencyCell(sheet, 3, row, dayData['total']);
      row++;
    }
    
    row += 2;
    await _addDetailedTransactions(sheet, receipts, row);
  }

  // Construir hoja de reporte mensual
  Future<void> _buildMonthlyReportSheet(Sheet sheet, List<Receipt> receipts, DateTime month) async {
    int row = 0;
    
    _addHeaderCell(sheet, 0, row, 'REPORTE MENSUAL - RIOCAJA SMART', isTitle: true);
    row += 2;
    
    _addCell(sheet, 0, row, 'Mes:');
    _addCell(sheet, 1, row, DateFormat('MMMM yyyy', 'es_ES').format(month));
    row += 2;

    // RESUMEN POR SEMANAS
    final weeklyBreakdown = _generateMonthlyWeeklyBreakdown(receipts, month);
    _addHeaderCell(sheet, 0, row, 'RESUMEN POR SEMANAS');
    row++;
    
    _addHeaderCell(sheet, 0, row, 'SEMANA');
    _addHeaderCell(sheet, 1, row, 'PERIODO');
    _addHeaderCell(sheet, 2, row, 'TRANSACCIONES');
    _addHeaderCell(sheet, 3, row, 'TOTAL');
    row++;

    for (final week in weeklyBreakdown) {
      _addCell(sheet, 0, row, week['name']);
      _addCell(sheet, 1, row, week['period']);
      _addCell(sheet, 2, row, week['count'].toString());
      _addCurrencyCell(sheet, 3, row, week['total']);
      row++;
    }
    
    // RESUMEN POR TIPOS
    row += 2;
    final typeSummary = _generateTypeSummary(receipts);
    _addHeaderCell(sheet, 0, row, 'RESUMEN POR TIPOS DE TRANSACCIÓN');
    row++;
    
    _addHeaderCell(sheet, 0, row, 'TIPO');
    _addHeaderCell(sheet, 1, row, 'CANTIDAD');
    _addHeaderCell(sheet, 2, row, 'VALOR TOTAL');
    _addHeaderCell(sheet, 3, row, 'PROMEDIO');
    row++;

    for (final type in typeSummary.entries) {
      final data = type.value;
      _addCell(sheet, 0, row, type.key);
      _addCell(sheet, 1, row, data['count'].toString());
      _addCurrencyCell(sheet, 2, row, data['total']);
      _addCurrencyCell(sheet, 3, row, data['average']);
      row++;
    }
    
    row += 2;
    await _addDetailedTransactions(sheet, receipts, row);
  }

  // Agregar transacciones detalladas
  Future<void> _addDetailedTransactions(Sheet sheet, List<Receipt> receipts, int startRow) async {
    int row = startRow;
    
    _addHeaderCell(sheet, 0, row, 'DETALLE COMPLETO DE TRANSACCIONES');
    row++;
    
    final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
    final isAdminOrOperator = authProvider.hasRole('admin') || authProvider.hasRole('operador');
    
    // Headers
    _addHeaderCell(sheet, 0, row, 'FECHA');
    _addHeaderCell(sheet, 1, row, 'HORA');
    _addHeaderCell(sheet, 2, row, 'TIPO');
    _addHeaderCell(sheet, 3, row, 'TRANSACCIÓN');
    _addHeaderCell(sheet, 4, row, 'VALOR');
    if (isAdminOrOperator) {
      _addHeaderCell(sheet, 5, row, 'CORRESPONSAL');
      _addHeaderCell(sheet, 6, row, 'CLASIFICACIÓN');
    } else {
      _addHeaderCell(sheet, 5, row, 'CLASIFICACIÓN');
    }
    row++;

    // Ordenar por fecha y hora
    receipts.sort((a, b) {
      final dateComparison = a.fecha.compareTo(b.fecha);
      if (dateComparison != 0) return dateComparison;
      return a.hora.compareTo(b.hora);
    });

    // Datos
    for (final receipt in receipts) {
      _addCell(sheet, 0, row, receipt.fecha);
      _addCell(sheet, 1, row, receipt.hora);
      _addCell(sheet, 2, row, receipt.tipo);
      _addCell(sheet, 3, row, receipt.nroTransaccion);
      _addCurrencyCell(sheet, 4, row, receipt.valorTotal);
      
      if (isAdminOrOperator) {
        _addCell(sheet, 5, row, receipt.codigoCorresponsal ?? 'N/A');
        _addCell(sheet, 6, row, _classifyTransaction(receipt.tipo));
      } else {
        _addCell(sheet, 5, row, _classifyTransaction(receipt.tipo));
      }
      row++;
    }
  }

  // Métodos auxiliares para análisis de datos
  Map<String, dynamic> _generateSummary(List<Receipt> receipts) {
    double totalIncomes = 0.0;
    double totalExpenses = 0.0;
    
    final incomeTypes = {'DEPOSITO', 'PAGO DE SERVICIO', 'RECARGA CLARO', 'ENVIO GIRO'};
    
    for (final receipt in receipts) {
      if (incomeTypes.contains(receipt.tipo.toUpperCase())) {
        totalIncomes += receipt.valorTotal;
      } else {
        totalExpenses += receipt.valorTotal;
      }
    }
    
    return {
      'totalIncomes': totalIncomes,
      'totalExpenses': totalExpenses,
      'balance': totalIncomes - totalExpenses,
    };
  }

  Map<String, Map<String, dynamic>> _generateDailySummary(List<Receipt> receipts) {
    final Map<String, Map<String, dynamic>> summary = {};
    
    for (final receipt in receipts) {
      final date = receipt.fecha;
      if (!summary.containsKey(date)) {
        summary[date] = {
          'count': 0,
          'incomes': 0.0,
          'expenses': 0.0,
          'balance': 0.0,
        };
      }
      
      summary[date]!['count']++;
      
      final incomeTypes = {'DEPOSITO', 'PAGO DE SERVICIO', 'RECARGA CLARO', 'ENVIO GIRO'};
      if (incomeTypes.contains(receipt.tipo.toUpperCase())) {
        summary[date]!['incomes'] += receipt.valorTotal;
      } else {
        summary[date]!['expenses'] += receipt.valorTotal;
      }
      
      summary[date]!['balance'] = summary[date]!['incomes'] - summary[date]!['expenses'];
    }
    
    return summary;
  }

  Map<String, Map<String, dynamic>> _generateWeeklyData(List<Receipt> receipts, DateTime weekStart) {
    final Map<String, Map<String, dynamic>> weekData = {};
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      weekData[dateStr] = {'count': 0, 'total': 0.0};
    }
    
    for (final receipt in receipts) {
      if (weekData.containsKey(receipt.fecha)) {
        weekData[receipt.fecha]!['count']++;
        weekData[receipt.fecha]!['total'] += receipt.valorTotal;
      }
    }
    
    return weekData;
  }

  List<Map<String, dynamic>> _generateMonthlyWeeklyBreakdown(List<Receipt> receipts, DateTime month) {
    final List<Map<String, dynamic>> weeks = [];
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    DateTime weekStart = firstDay;
    int weekNumber = 1;
    
    while (weekStart.isBefore(lastDay) || weekStart.isAtSameMomentAs(lastDay)) {
      final weekEnd = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + 6,
      );
      
      final effectiveEnd = weekEnd.isAfter(lastDay) ? lastDay : weekEnd;
      
      final weekReceipts = receipts.where((receipt) {
        final receiptDate = _parseDate(receipt.fecha);
        return receiptDate != null &&
               receiptDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
               receiptDate.isBefore(effectiveEnd.add(Duration(days: 1)));
      }).toList();
      
      final total = weekReceipts.fold(0.0, (sum, receipt) => sum + receipt.valorTotal);
      
      weeks.add({
        'name': 'Semana $weekNumber',
        'period': '${DateFormat('dd/MM').format(weekStart)} - ${DateFormat('dd/MM').format(effectiveEnd)}',
        'count': weekReceipts.length,
        'total': total,
      });
      
      weekStart = weekStart.add(Duration(days: 7));
      weekNumber++;
    }
    
    return weeks;
  }

  Map<String, Map<String, dynamic>> _generateTypeSummary(List<Receipt> receipts) {
    final Map<String, Map<String, dynamic>> summary = {};
    
    for (final receipt in receipts) {
      final type = receipt.tipo;
      if (!summary.containsKey(type)) {
        summary[type] = {
          'count': 0,
          'total': 0.0,
          'average': 0.0,
        };
      }
      
      summary[type]!['count']++;
      summary[type]!['total'] += receipt.valorTotal;
    }
    
    // Calcular promedios
    for (final type in summary.keys) {
      summary[type]!['average'] = summary[type]!['total'] / summary[type]!['count'];
    }
    
    return summary;
  }

  String _classifyTransaction(String tipo) {
    final incomeTypes = {'DEPOSITO', 'PAGO DE SERVICIO', 'RECARGA CLARO', 'ENVIO GIRO'};
    return incomeTypes.contains(tipo.toUpperCase()) ? 'INGRESO' : 'EGRESO';
  }

  // Métodos auxiliares para Excel
  void _addCell(Sheet sheet, int col, int row, dynamic value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value is num ? TextCellValue(value.toString()) : TextCellValue(value.toString());
  }

  void _addHeaderCell(Sheet sheet, int col, int row, String value, {bool isTitle = false}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    
    // Aplicar formato de header
    cell.cellStyle = CellStyle(
      backgroundColorHex: isTitle ? ExcelColor.blue : ExcelColor.grey,
      fontColorHex: isTitle ? ExcelColor.white : ExcelColor.black,
      bold: true,
      fontSize: isTitle ? 14 : 12,
    );
  }

void _addCurrencyCell(Sheet sheet, int col, int row, double value) {
  final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
  // Formatear como texto con símbolo de moneda
  cell.value = TextCellValue('\$${value.toStringAsFixed(2)}');
}

  // Guardar y compartir Excel
  Future<bool> _saveAndShareExcel(Excel excel, String fileName) async {
    try {
      final bytes = excel.save();
      if (bytes == null) return false;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Reporte Excel - RíoCaja Smart',
        text: 'Reporte generado desde RíoCaja Smart',
      );

      _showMessage('Reporte Excel generado y compartido exitosamente');
      return true;
    } catch (e) {
      _showError('Error al guardar Excel: $e');
      return false;
    }
  }

  // Utilidades
  DateTime? _parseDate(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (e) {
      print('Error parsing date: $dateStr');
    }
    return null;
  }

  void _showMessage(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showError(String error) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
    print(error);
  }
}