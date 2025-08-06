import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:riocaja_smart/services/excel_report_service.dart';

class PdfService {
  static const String baseUrl = 'https://riocajasmartbackend-production.up.railway.app/api/v1';
  
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
    print('📧 PDF Service: Contexto configurado');
  }

  Future<bool> generateAndSharePdf(Map<String, dynamic> reportData, DateTime selectedDate) async {
    try {
      final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
      final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      // ✅ GENERAR PDF CON TU FORMATO ORIGINAL
      final pdf = await _generatePdfDocument(reportData, selectedDate, dateStr, currentTime);

      final tempDir = await getTemporaryDirectory();
      final fechaGuiones = DateFormat('dd-MM-yyyy').format(selectedDate);
      final fileName = 'reporte_cierre_${fechaGuiones}.pdf';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      // ✅ GENERAR EXCEL SIMPLE
       final excelFilePath = await _generateRealExcel(reportData, selectedDate);
      if (excelFilePath != null) {
        print('📊 Excel generado correctamente: $excelFilePath');
      } else {
        print('⚠️ No se pudo generar Excel, continuando solo con PDF');
      }

      final results = await Future.wait([
        _shareViaNativeApps(filePath, dateStr),
        _sendReportByEmail(filePath, excelFilePath, dateStr, reportData),
      ]);

      bool shareSuccess = results[0];
      bool emailSuccess = results[1];

      if (shareSuccess && emailSuccess) {
        return true;
      } else if (shareSuccess && !emailSuccess) {
        print('PDF compartido exitosamente, pero falló el envío por correo');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error en generateAndSharePdf: $e');
      return false;
    }
  }

  Future<bool> _shareViaNativeApps(String filePath, String dateStr) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Reporte de Cierre - $dateStr'
      );
      return true;
    } catch (e) {
      print('Error al compartir PDF: $e');
      return false;
    }
  }

  Future<bool> _sendReportByEmail(String filePath, String? excelFilePath, String dateStr, Map<String, dynamic> reportData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? '';
      final userName = prefs.getString('user_name') ?? 'Usuario';
      final token = prefs.getString('auth_token') ?? '';

      if (userEmail.isEmpty) {
        print('Email del usuario no disponible');
        return false;
      }
      if (token.isEmpty) {
        print('Token de autenticación no disponible');
        return false;
      }

      final file = File(filePath);
      final pdfBytes = await file.readAsBytes();
      final pdfBase64 = base64Encode(pdfBytes);

      final reportSummary = _generateReportSummary(reportData);

      Map<String, dynamic> emailData = {
        'recipient_email': userEmail,
        'recipient_name': userName,
        'report_date': dateStr,
        'pdf_filename': file.path.split('/').last,
        'pdf_base64': pdfBase64,
        'report_summary': reportSummary,
      };

      // ✅ AGREGAR EXCEL SI EXISTE
      if (excelFilePath != null) {
        final excelFile = File(excelFilePath);
        if (await excelFile.exists()) {
          final excelBytes = await excelFile.readAsBytes();
          final excelBase64 = base64Encode(excelBytes);
          
          emailData['excel_filename'] = excelFile.path.split('/').last;
          emailData['excel_base64'] = excelBase64;
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/send-pdf-report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print('PDF enviado por correo exitosamente');
        return true;
      } else {
        print('Error al enviar PDF por correo: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en _sendReportByEmail: $e');
      return false;
    }
  }

  // ✅ REEMPLAZAR EXCEL SIMPLE POR TU EXCEL REAL
  Future<String?> _generateRealExcel(Map<String, dynamic> reportData, DateTime selectedDate) async {
    try {
      final ExcelReportService _excelReportService = ExcelReportService();
      
      // Configurar el servicio con contexto y token
      if (_context != null) {
        _excelReportService.setContext(_context!);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        _excelReportService.setAuthToken(token);
      }
      
      // ✅ USAR EXACTAMENTE EL MISMO MÉTODO QUE EN "EXCEL REPORTS"
      final success = await _excelReportService.generateDailyReport(selectedDate);
      
      if (success) {
        // Buscar el archivo generado
        final tempDir = await getTemporaryDirectory();
        final documentsDir = await getApplicationDocumentsDirectory();
        final fileName = 'Reporte_Diario_${DateFormat('dd-MM-yyyy').format(selectedDate)}.xlsx';
        
        // Buscar en varias ubicaciones posibles
        final possiblePaths = [
          '${tempDir.path}/$fileName',
          '${documentsDir.path}/$fileName',
          '${tempDir.path}/Download/$fileName',
        ];
        
        for (String path in possiblePaths) {
          final file = File(path);
          if (await file.exists()) {
            print('📊 Excel encontrado en: $path');
            return path;
          }
        }
        
        print('⚠️ Excel generado pero no encontrado en las rutas esperadas');
        return null;
      } else {
        print('❌ Error generando Excel con ExcelReportService');
        return null;
      }
    } catch (e) {
      print('❌ Error en _generateRealExcel: $e');
      return null;
    }
  }

  String _formatConceptName(String key) {
    switch (key.toLowerCase()) {
      case 'pago_servicios':
        return 'PAGO SERVICIOS';
      case 'recarga_claro':
        return 'RECARGA CLARO';
      case 'deposito':
        return 'DEPOSITO';
      case 'retiro':
        return 'RETIRO';
      case 'efectivo_movil':
        return 'EFECTIVO MOVIL';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  Map<String, dynamic> _generateReportSummary(Map<String, dynamic> reportData) {
    try {
      final Map incomes = reportData['incomes'] ?? {};
      final Map expenses = reportData['expenses'] ?? {};

      double totalIncomes = 0;
      double totalExpenses = 0;
      int totalTransactions = reportData['count'] as int? ?? 0;

      incomes.forEach((key, value) {
        totalIncomes += (value as num).toDouble();
      });
      expenses.forEach((key, value) {
        totalExpenses += (value as num).toDouble();
      });

      double saldoEnCaja = totalIncomes - totalExpenses;

      return {
        'total_ingresos': totalIncomes,
        'total_egresos': totalExpenses,
        'saldo_en_caja': saldoEnCaja,
        'total_transacciones': totalTransactions,
        'estado_caja': saldoEnCaja >= 0 ? 'POSITIVO' : 'NEGATIVO',
      };
    } catch (e) {
      print('Error al generar resumen: $e');
      return {};
    }
  }

  // ✅ TU FORMATO ORIGINAL EXACTO - SIN CAMBIOS
  Future<pw.Document> _generatePdfDocument(Map<String, dynamic> reportData, DateTime selectedDate, String dateStr, String currentTime) async {
    final pdf = pw.Document();

    final Map incomes = reportData['incomes'] ?? {};
    final Map expenses = reportData['expenses'] ?? {};
    final Map incomeCount = reportData['incomeCount'] ?? {};
    final Map expenseCount = reportData['expenseCount'] ?? {};

    double totalIncomes = 0;
    double totalExpenses = 0;
    int totalIncomeCount = 0;
    int totalExpenseCount = 0;

    incomes.forEach((key, value) {
      totalIncomes += (value as num).toDouble();
      totalIncomeCount += (incomeCount[key] ?? 0) as int;
    });
    expenses.forEach((key, value) {
      totalExpenses += (value as num).toDouble();
      totalExpenseCount += (expenseCount[key] ?? 0) as int;
    });

    double saldoEnCaja = totalIncomes - totalExpenses;
    int count = reportData['count'] as int? ?? 0;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(dateStr, currentTime),
              pw.SizedBox(height: 20),
              if (count > 0) ...[
                if (incomes.isNotEmpty) ...[
                  _buildPdfIncomeSection(incomes, incomeCount, totalIncomes, totalIncomeCount),
                  pw.SizedBox(height: 20),
                ],
                if (expenses.isNotEmpty) ...[
                  _buildPdfExpenseSection(expenses, expenseCount, totalExpenses, totalExpenseCount),
                  pw.SizedBox(height: 20),
                ],
                _buildPdfBalanceSection(saldoEnCaja),
              ] else ...[
                pw.Container(
                  padding: pw.EdgeInsets.all(20),
                  alignment: pw.Alignment.center,
                  child: pw.Text('NO HAY TRANSACCIONES PARA ESTA FECHA'),
                ),
              ],
              pw.SizedBox(height: 40),
              _buildPdfFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfHeader(String dateStr, String currentTime) {
    return pw.Column(
      children: [
        pw.Text(
          'RIOCAJA SMART - REPORTE DE CIERRE',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FECHA DE REPORTE:'),
                  pw.Text('CNB:'),
                  pw.Text('GENERADO EL:'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(dateStr),
                  pw.Text('BANCO DEL BARRIO'),
                  pw.Text('${DateFormat('dd/MM/yyyy').format(DateTime.now())} $currentTime'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfIncomeSection(Map incomes, Map incomeCount, double totalIncomes, int totalIncomeCount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INGRESOS EFECTIVO',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('')),
            pw.Expanded(flex: 1, child: pw.Text('CANT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('VALOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          ],
        ),
        ...incomes.entries.map((entry) {
          String tipo = entry.key.toString().toUpperCase();
          double valor = (entry.value as num).toDouble();
          int cantidad = incomeCount[entry.key] ?? 0;
          
          return pw.Row(
            children: [
              pw.Expanded(flex: 3, child: pw.Text(tipo)),
              pw.Expanded(flex: 1, child: pw.Text(cantidad.toString())),
              pw.Expanded(flex: 2, child: pw.Text('\$${valor.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
            ],
          );
        }).toList(),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('TOTAL INGRESOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 1, child: pw.Text(totalIncomeCount.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('\$${totalIncomes.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfExpenseSection(Map expenses, Map expenseCount, double totalExpenses, int totalExpenseCount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'EGRESOS EFECTIVO',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('')),
            pw.Expanded(flex: 1, child: pw.Text('CANT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('VALOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          ],
        ),
        ...expenses.entries.map((entry) {
          String tipo = entry.key.toString().toUpperCase();
          double valor = (entry.value as num).toDouble();
          int cantidad = expenseCount[entry.key] ?? 0;
          
          return pw.Row(
            children: [
              pw.Expanded(flex: 3, child: pw.Text(tipo)),
              pw.Expanded(flex: 1, child: pw.Text(cantidad.toString())),
              pw.Expanded(flex: 2, child: pw.Text('\$${valor.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
            ],
          );
        }).toList(),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('TOTAL EGRESOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 1, child: pw.Text(totalExpenseCount.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('\$${totalExpenses.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfBalanceSection(double saldoEnCaja) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Center(
        child: pw.Text(
          'SALDO EN CAJA \$${saldoEnCaja.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, 
            fontSize: 16,
            // ✅ AGREGAR COLOR: VERDE si positivo, ROJO si negativo
            color: saldoEnCaja >= 0 ? PdfColors.green : PdfColors.red,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        '© RIOCAJA SMART 2025',
        style: pw.TextStyle(fontSize: 10),
      ),
    );
  }
}