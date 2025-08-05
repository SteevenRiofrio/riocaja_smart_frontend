// lib/services/pdf_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:riocaja_smart_frontend/services/auth_service.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  final AuthService _authService = AuthService();
  static const String baseUrl = 'https://tu-backend-url.com/api';

  // Generar y compartir PDF + enviar por correo
  Future<bool> generateAndSharePDF(Map<String, dynamic> reportData, DateTime selectedDate) async {
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
      final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      // Extraer datos del reporte
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

      // Crear página del PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildPdfHeader(dateStr, currentTime),
                pw.SizedBox(height: 20),

                if (count > 0) ...[
                  // Contenido del reporte
                  if (incomes.isNotEmpty) ...[
                    _buildPdfIncomeSection(incomes, incomeCount, totalIncomes, totalIncomeCount),
                    pw.SizedBox(height: 20),
                  ],
                  
                  if (expenses.isNotEmpty) ...[
                    _buildPdfExpenseSection(expenses, expenseCount, totalExpenses, totalExpenseCount),
                    pw.SizedBox(height: 20),
                  ],

                  // Saldo en caja
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

      // Guardar PDF temporalmente
      final tempDir = await getTemporaryDirectory();
      final fechaGuiones = DateFormat('dd-MM-yyyy').format(selectedDate);
      final filePath = '${tempDir.path}/reporte_cierre_${fechaGuiones}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Compartir por apps nativas
      final shareResult = await Share.shareXFiles([XFile(filePath)], subject: 'Reporte de Cierre - $dateStr');

      // Enviar por correo automático
      final emailResult = await _sendPdfByEmail(filePath, 'reporte_cierre_${fechaGuiones}.pdf', dateStr, reportData);

      return emailResult; // true si el correo fue exitoso
    } catch (e) {
      print('Error al generar PDF: $e');
      return false;
    }
  }

  // Enviar PDF por correo usando backend
  Future<bool> _sendPdfByEmail(String filePath, String fileName, String dateStr, Map<String, dynamic> reportData) async {
    try {
      final userInfo = await _authService.getCurrentUserInfo();
      if (userInfo == null) return false;
      final userEmail = userInfo['email'] ?? '';
      final userName = userInfo['nombre'] ?? 'Usuario';
      if (userEmail.isEmpty) return false;

      final file = File(filePath);
      final pdfBytes = await file.readAsBytes();
      final pdfBase64 = base64Encode(pdfBytes);

      final reportSummary = {
        'total_ingresos': reportData['totalIncomes'] ?? 0,
        'total_egresos': reportData['totalExpenses'] ?? 0,
        'saldo_en_caja': reportData['saldoEnCaja'] ?? 0,
        'total_transacciones': reportData['count'] ?? 0,
        'estado_caja': (reportData['saldoEnCaja'] ?? 0) >= 0 ? 'POSITIVO' : 'NEGATIVO',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/send-pdf-report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _authService.getToken()}',
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

      return response.statusCode == 200;
    } catch (e) {
      print('Error en _sendPdfByEmail: $e');
      return false;
    }
  }

  // Header del PDF
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

  // Sección de ingresos
  pw.Widget _buildPdfIncomeSection(Map incomes, Map incomeCount, double totalIncomes, int totalIncomeCount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INGRESOS EFECTIVO',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 10),
        
        // Header de tabla
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('')),
            pw.Expanded(flex: 1, child: pw.Text('CANT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('VALOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          ],
        ),

        // Items de ingresos
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

        // Total ingresos
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

  // Sección de egresos
  pw.Widget _buildPdfExpenseSection(Map expenses, Map expenseCount, double totalExpenses, int totalExpenseCount) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'EGRESOS EFECTIVO',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 10),

        // Header de tabla
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text('')),
            pw.Expanded(flex: 1, child: pw.Text('CANT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Expanded(flex: 2, child: pw.Text('VALOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          ],
        ),

        // Items de egresos
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

        // Total egresos
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

  // Sección de saldo
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

  // Footer del PDF
  pw.Widget _buildPdfFooter() {
    return pw.Text(
      '© RIOCAJA SMART ${DateTime.now().year}',
      style: pw.TextStyle(fontSize: 10),
    );
  }
}