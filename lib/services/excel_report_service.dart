// lib/services/excel_report_service.dart - CÓDIGO COMPLETO Y LIMPIO
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

  // ✅ MÉTODO PRINCIPAL CON PARÁMETRO autoShare
  Future<bool> generateDailyReport(DateTime date, {bool autoShare = true}) async {
    try {
      final dateStr = _formatDate(date);
      final receipts = await _getReceiptsByDate(dateStr);
      if (receipts.isEmpty) {
        if (autoShare) _showMessage('No hay comprobantes para la fecha seleccionada');
        return false;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Reporte Diario'];
      
      await _buildDailyReportSheet(sheet, receipts, date);
      
      final fileName = 'Reporte_Diario_${DateFormat('dd-MM-yyyy').format(date)}.xlsx';
      
      // ✅ COMPORTAMIENTO DIFERENTE SEGÚN autoShare
      if (autoShare) {
        // Compartir automáticamente (comportamiento actual)
        return await _saveAndShareExcel(excel, fileName);
      } else {
        // SOLO guardar sin compartir (para uso interno del PDF)
        return await _saveExcelOnly(excel, fileName);
      }
    } catch (e) {
      if (autoShare) _showError('Error generando reporte diario: $e');
      print('Error generando reporte diario: $e');
      return false;
    }
  }

  // ✅ SOLO GUARDAR SIN COMPARTIR
  Future<bool> _saveExcelOnly(Excel excel, String fileName) async {
    try {
      final bytes = excel.save();
      if (bytes == null) return false;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      print('📊 Excel guardado para correo: ${file.path}');
      return true;
    } catch (e) {
      print('Error al guardar Excel: $e');
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

  // ✅ OBTENER COMPROBANTES POR FECHA
  Future<List<Receipt>> _getReceiptsByDate(String dateStr) async {
    try {
      print('🔍 Buscando comprobantes para la fecha: $dateStr');
      final allReceiptsData = await _apiService.getAllReceipts();
      final allReceipts = allReceiptsData.map((receiptMap) {
        return Receipt.fromJson(receiptMap);
      }).toList();
      final filteredReceipts = allReceipts.where((receipt) {
        return receipt.fecha == dateStr;
      }).toList();
      print('📋 Encontrados ${filteredReceipts.length} comprobantes para $dateStr');
      return filteredReceipts;
    } catch (e) {
      print('❌ Error obteniendo comprobantes por fecha: $e');
      return [];
    }
  }

  // ✅ OBTENER COMPROBANTES POR RANGO DE FECHAS
  Future<List<Receipt>> _getReceiptsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      print('🔍 Buscando comprobantes desde ${startDate.day}/${startDate.month}/${startDate.year} hasta ${endDate.day}/${endDate.month}/${endDate.year}');
      final allReceiptsData = await _apiService.getAllReceipts();
      final allReceipts = allReceiptsData.map((receiptMap) {
        return Receipt.fromJson(receiptMap);
      }).toList();
      final filteredReceipts = allReceipts.where((receipt) {
        final receiptDate = _parseDate(receipt.fecha);
        if (receiptDate == null) return false;
        return receiptDate.isAfter(startDate.subtract(Duration(days: 1))) &&
               receiptDate.isBefore(endDate.add(Duration(days: 1)));
      }).toList();
      print('📋 Encontrados ${filteredReceipts.length} comprobantes en el rango especificado');
      return filteredReceipts;
    } catch (e) {
      print('❌ Error obteniendo comprobantes por rango de fechas: $e');
      return [];
    }
  }

  // ✅ CONSTRUIR REPORTE DIARIO
  Future<void> _buildDailyReportSheet(Sheet sheet, List<Receipt> receipts, DateTime date) async {
    try {
      print('📊 Construyendo reporte diario para ${_formatDate(date)}');
      // Configurar ancho de columnas
      sheet.setColumnWidth(0, 12); // Fecha
      sheet.setColumnWidth(1, 12); // Hora
      sheet.setColumnWidth(2, 20); // Tipo
      sheet.setColumnWidth(3, 18); // Nro Transacción
      sheet.setColumnWidth(4, 15); // Valor
      sheet.setColumnWidth(5, 20); // Corresponsal

      // Headers
      final List<String> headers = [
        'Fecha',
        'Hora',
        'Tipo de Servicio',
        'Nro. Transacción',
        'Valor Total'
      ];
      if (receipts.any((r) => r.codigoCorresponsal != null)) {
        headers.add('Código Corresponsal');
      }

      // Escribir headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
      }

      // Escribir datos
      for (int i = 0; i < receipts.length; i++) {
        final receipt = receipts[i];
        final rowIndex = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
            TextCellValue(receipt.fecha);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
            TextCellValue(receipt.hora);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
            TextCellValue(receipt.tipo);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
            TextCellValue(receipt.nroTransaccion);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value =
            DoubleCellValue(receipt.valorTotal);

        if (headers.length > 5 && receipt.codigoCorresponsal != null) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value =
              TextCellValue(receipt.codigoCorresponsal!);
        }
      }

      // Agregar totales al final
      final totalRow = receipts.length + 2;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRow)).value = TextCellValue('TOTAL:');
      final total = receipts.fold<double>(0.0, (sum, receipt) => sum + receipt.valorTotal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow)).value = DoubleCellValue(total);
      print('✅ Reporte diario construido exitosamente con ${receipts.length} comprobantes');
    } catch (e) {
      print('❌ Error construyendo reporte diario: $e');
      throw Exception('Error construyendo reporte: $e');
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
    final isAdminOrOperator = authProvider.hasRole('admin') || authProvider.hasRole('asesor');
    
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

  // MÉTODOS AUXILIARES PARA ANÁLISIS DE DATOS
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

  // MÉTODOS AUXILIARES PARA EXCEL
  void _addCell(Sheet sheet, int col, int row, dynamic value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = value is String ? TextCellValue(value) : 
                 value is int ? IntCellValue(value) :
                 value is double ? DoubleCellValue(value) :
                 TextCellValue(value.toString());
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
    cell.value = TextCellValue('\$${value.toStringAsFixed(2)}');
  }

  // ✅ GUARDAR Y COMPARTIR EXCEL
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

  // UTILIDADES
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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