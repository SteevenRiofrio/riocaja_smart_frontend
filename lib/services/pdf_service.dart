// lib/services/pdf_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfService {
  static const String baseUrl = 'https://riocajasmartbackend-production.up.railway.app/api/v1';

  Future<bool> generateAndSharePdf(Map<String, dynamic> reportData, DateTime selectedDate) async {
    try {
      final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
      final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      final pdf = await _generatePdfDocument(reportData, selectedDate, dateStr, currentTime);

      final tempDir = await getTemporaryDirectory();
      final fechaGuiones = DateFormat('dd-MM-yyyy').format(selectedDate);
      final fileName = 'reporte_cierre_${fechaGuiones}.pdf';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      final results = await Future.wait([
        _shareViaNativeApps(filePath, dateStr),
        _sendPdfByEmail(filePath, fileName, dateStr, reportData),
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

  Future<bool> _sendPdfByEmail(String filePath, String fileName, String dateStr, Map<String, dynamic> reportData) async {
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

      final response = await http.post(
        Uri.parse('$baseUrl/send-pdf-report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipient_email': userEmail,
          'recipient_name': userName,
          'report_date': dateStr,
          'pdf_filename': fileName,
          'pdf_base64': pdfBase64,
          'report_summary': reportSummary,
        }),
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
      print('Error en _sendPdfByEmail: $e');
      return false;
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
      totalIncomeCount += totalIncomeCount += (incomeCount[key] ?? 0) as int;
    });
    expenses.forEach((key, value) {
      totalExpenses += (value as num).toDouble();
      totalExpenseCount += totalExpenseCount += (expenseCount[key] ?? 0) as int;
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
              pw.Expanded(flex: 1, child: pw.Text('$cantidad', textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 2, child: pw.Text('\$${valor.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
            ],
          );
        }).toList(),
        pw.Divider(),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('TOTAL INGRESOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 1, child: pw.Text('$totalIncomeCount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
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
              pw.Expanded(flex: 1, child: pw.Text('$cantidad', textAlign: pw.TextAlign.center)),
              pw.Expanded(flex: 2, child: pw.Text('\$${valor.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
            ],
          );
        }).toList(),
        pw.Divider(),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('TOTAL EGRESOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 1, child: pw.Text('$totalExpenseCount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
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
        color: saldoEnCaja >= 0 ? PdfColors.green100 : PdfColors.red100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SALDO EN CAJA',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          pw.Text(
            '\$${saldoEnCaja.toStringAsFixed(2)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Text(
      '© RIOCAJA SMART ${DateTime.now().year}',
      style: pw.TextStyle(fontSize: 10),
    );
  }
}