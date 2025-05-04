// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isGenerating = false;
  bool _reportGenerated = false;
  Map<String, dynamic> _reportData = {};
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Generar reporte al iniciar para la fecha actual
    _generateReport();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _reportGenerated = false;
      });
      // Generar nuevo reporte para la fecha seleccionada
      _generateReport();
    }
  }

  void _generateReport() {
    setState(() {
      _isGenerating = true;
      _reportGenerated = false;
    });

    // Formato de la fecha para mostrar
    String formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    print('Generando reporte para la fecha: $formattedDate');

    // Construir reporte manualmente
    _buildManualReport(formattedDate)
        .then((reportData) {
          setState(() {
            _reportData = reportData;
            _isGenerating = false;
            _reportGenerated = true;

            print('Reporte manual generado: $reportData');
          });
        })
        .catchError((error) {
          print('Error al generar reporte manual: $error');
          setState(() {
            _isGenerating = false;
            // Mostrar mensaje de error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al generar el reporte: $error')),
            );
          });
        });
  }

  // Método para construir el reporte manualmente
  Future<Map<String, dynamic>> _buildManualReport(String dateStr) async {
    try {
      // Obtener comprobantes por fecha directamente
      final url = '${_apiService.baseUrl}/receipts/date/$dateStr';
      print('Obteniendo comprobantes para reporte manual: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: 60));

      print('Código de respuesta: ${response.statusCode}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        print(
          'Respuesta recibida: ${response.body.substring(0, min(200, response.body.length))}...',
        );

        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> receipts = jsonResponse['data'] ?? [];
        final int count = receipts.length;

        print('Comprobantes encontrados: $count');

        if (count == 0) {
          return {'summary': {}, 'total': 0.0, 'date': dateStr, 'count': 0};
        }

        // Inicializar valores
        double totalPagos = 0.0;
        double totalRetiros = 0.0;
        Map<String, double> summary = {};

        for (var receipt in receipts) {
          // Obtener el valor total del comprobante
          double valor = 0.0;
          if (receipt['valor_total'] != null) {
            if (receipt['valor_total'] is int) {
              valor = (receipt['valor_total'] as int).toDouble();
            } else if (receipt['valor_total'] is double) {
              valor = receipt['valor_total'];
            } else if (receipt['valor_total'] is String) {
              try {
                valor = double.parse(receipt['valor_total']);
              } catch (e) {
                print(
                  'Error al convertir valor_total: ${receipt['valor_total']}',
                );
              }
            }
          }

          // Agrupar por tipo
          String tipo = receipt['tipo'] as String? ?? 'Desconocido';
          summary[tipo] = (summary[tipo] ?? 0.0) + valor;

          // Sumar según el tipo
          if (tipo == 'Retiro') {
            totalRetiros += valor;
          } else {
            totalPagos += valor;
          }

          // Depuración: Mostrar datos del comprobante
          print(
            'Comprobante ${receipt['nro_transaccion']}: Tipo=$tipo, Valor=$valor',
          );
        }

        // Calcular el total final (Pagos de Servicio - Retiros)
        double total = totalPagos - totalRetiros;
        print(
          'Total calculado: Pagos ($totalPagos) - Retiros ($totalRetiros) = $total',
        );

        return {
          'summary': summary,
          'total': total,
          'date': dateStr,
          'count': count,
          'totalPagos': totalPagos,
          'totalRetiros': totalRetiros,
        };
      } else {
        // Intentar obtener los comprobantes directamente de la lista completa y filtrar por fecha
        return _buildReportFromAllReceipts(dateStr);
      }
    } catch (e) {
      print('Error al construir reporte manual: $e');

      // En caso de error, intentar obtener todos los comprobantes y filtrar
      return _buildReportFromAllReceipts(dateStr);
    }
  }

 // Método para generar y compartir un reporte en PDF
Future<void> _generateAndDownloadPDF() async {
  try {
    // Mostrar indicador de progreso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generando PDF...')),
    );

    // Crear el PDF
    final pdf = pw.Document();
    
    // Formato de la fecha 
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    
    // Obtener datos del reporte
    final summary = _reportData['summary'] as Map<dynamic, dynamic>? ?? {};
    final total = _reportData['total'] as double? ?? 0.0;
    final count = _reportData['count'] as int? ?? 0;
    final totalPagos = _reportData['totalPagos'] as double? ?? 0.0;
    final totalRetiros = _reportData['totalRetiros'] as double? ?? 0.0;
    
    // Agregar contenido al PDF
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('RíoCaja Smart - Reporte de Cierre',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            
            // Información del reporte
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
                      pw.Text('Fecha de reporte:'),
                      pw.Text('CNB:'),
                      pw.Text('Generado el:'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(dateStr),
                      pw.Text('Banco del Barrio'),
                      pw.Text('${DateFormat('dd/MM/yyyy').format(DateTime.now())} $currentTime'),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Resumen de transacciones
            pw.Text('Resumen de Transacciones',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            
            if (count > 0) ...[
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                children: [
                  // Encabezados
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Tipo', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(5),
                        child: pw.Text('Valor', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold), 
                          textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  
                  // Filas de datos
                  ...summary.entries.map((entry) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(entry.key.toString()),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '\$${(entry.value as num).toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ] else ...[
              pw.Container(
                padding: pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text('No hay transacciones para esta fecha'),
              ),
            ],
            
            pw.SizedBox(height: 20),
            
            // Totales
            if (count > 0) ...[
              pw.Divider(color: PdfColors.grey),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Pagos:'),
                  pw.Text('\$${totalPagos.toStringAsFixed(2)}'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Retiros:'),
                  pw.Text('\$${totalRetiros.toStringAsFixed(2)}'),
                ],
              ),
              pw.Divider(color: PdfColors.grey),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
            
            pw.SizedBox(height: 40),
            
            pw.Text('© RíoCaja Smart ${DateTime.now().year}',
              style: pw.TextStyle(fontSize: 10)),
          ],
        );
      },
    ));

    // Guardar el PDF en un directorio temporal
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/reporte_cierre_${dateStr.replaceAll('/', '_')}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    // Compartir el PDF
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Reporte de Cierre - $dateStr',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF generado y compartido')),
    );
  } catch (e) {
    print('Error al generar PDF: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al generar PDF: $e')),
    );
  }
}

// Método para compartir el reporte como texto
Future<void> _shareReport() async {
  try {
    // Generar el contenido del reporte en formato de texto
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final summary = _reportData['summary'] as Map<dynamic, dynamic>? ?? {};
    final total = _reportData['total'] as double? ?? 0.0;
    final count = _reportData['count'] as int? ?? 0;
    final totalPagos = _reportData['totalPagos'] as double? ?? 0.0;
    final totalRetiros = _reportData['totalRetiros'] as double? ?? 0.0;
    
    // Construir el texto del reporte
    String reportText = 'REPORTE DE CIERRE - RÍOCAJA SMART\n\n';
    reportText += 'Fecha: $dateStr\n';
    reportText += 'CNB: Banco del Barrio\n\n';
    
    reportText += 'TRANSACCIONES:\n';
    if (count > 0) {
      summary.forEach((key, value) {
        reportText += '- $key: \$${(value as num).toStringAsFixed(2)}\n';
      });
      
      reportText += '\nTotal Pagos: \$${totalPagos.toStringAsFixed(2)}\n';
      reportText += 'Total Retiros: \$${totalRetiros.toStringAsFixed(2)}\n';
      reportText += '\nTOTAL: \$${total.toStringAsFixed(2)}\n';
    } else {
      reportText += 'No hay transacciones para esta fecha.\n';
    }
    
    reportText += '\nGenerado el: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}';
    
    // Compartir el texto
    await Share.share(reportText, subject: 'Reporte de Cierre - $dateStr');
  } catch (e) {
    print('Error al compartir reporte: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al compartir reporte: $e')),
    );
  }
}


  // Método auxiliar para obtener mínimo de dos números
  int min(int a, int b) {
    return (a < b) ? a : b;
  }

  // Método alternativo: obtener todos los comprobantes y filtrar por fecha
  Future<Map<String, dynamic>> _buildReportFromAllReceipts(
    String dateStr,
  ) async {
    try {
      print(
        'Intentando construir reporte a partir de todos los comprobantes...',
      );

      // Obtener todos los comprobantes
      final url = '${_apiService.baseUrl}/receipts/';
      print('URL: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: 60));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> allReceipts = jsonResponse['data'] ?? [];

        print('Total de comprobantes obtenidos: ${allReceipts.length}');

        // Filtrar por fecha
        final List<dynamic> receipts =
            allReceipts
                .where((receipt) => receipt['fecha'] == dateStr)
                .toList();

        print('Comprobantes con fecha $dateStr: ${receipts.length}');

        if (receipts.isEmpty) {
          return {'summary': {}, 'total': 0.0, 'date': dateStr, 'count': 0};
        }

        // Inicializar valores
        double totalPagos = 0.0;
        double totalRetiros = 0.0;
        Map<String, double> summary = {};

        for (var receipt in receipts) {
          // Obtener el valor total del comprobante
          double valor = 0.0;
          if (receipt['valor_total'] != null) {
            if (receipt['valor_total'] is int) {
              valor = (receipt['valor_total'] as int).toDouble();
            } else if (receipt['valor_total'] is double) {
              valor = receipt['valor_total'];
            } else if (receipt['valor_total'] is String) {
              try {
                valor = double.parse(receipt['valor_total']);
              } catch (e) {
                print(
                  'Error al convertir valor_total: ${receipt['valor_total']}',
                );
              }
            }
          }

          // Agrupar por tipo
          String tipo = receipt['tipo'] as String? ?? 'Desconocido';
          summary[tipo] = (summary[tipo] ?? 0.0) + valor;

          // Sumar según el tipo
          if (tipo == 'Retiro') {
            totalRetiros += valor;
          } else {
            totalPagos += valor;
          }

          // Depuración: Mostrar datos del comprobante
          print(
            'Comprobante ${receipt['nro_transaccion']}: Tipo=$tipo, Valor=$valor',
          );
        }

        // Calcular el total final (Pagos de Servicio - Retiros)
        double total = totalPagos - totalRetiros;
        print(
          'Total calculado: Pagos ($totalPagos) - Retiros ($totalRetiros) = $total',
        );

        return {
          'summary': summary,
          'total': total,
          'date': dateStr,
          'count': receipts.length,
          'totalPagos': totalPagos,
          'totalRetiros': totalRetiros,
        };
      } else {
        print('Error o respuesta vacía: ${response.statusCode}');
        return {
          'summary': {},
          'total': 0.0,
          'date': dateStr,
          'count': 0,
          'error': 'Error en la respuesta: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error al construir reporte desde todos los comprobantes: $e');
      return {
        'summary': {},
        'total': 0.0,
        'date': dateStr,
        'count': 0,
        'error': 'Error: $e',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reporte de Cierre')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selección de fecha
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Cambiar'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Botón para generar reporte o indicador de carga
            if (!_reportGenerated && !_isGenerating)
              ElevatedButton(
                onPressed: _generateReport,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Generar Reporte de Cierre'),
              ),

            if (_isGenerating)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generando reporte...'),
                  ],
                ),
              ),

            // Reporte generado
            if (_reportGenerated && !_isGenerating) ...[
              Text(
                'Resumen del Cierre',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fecha y CNB
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text('Fecha:'), Text('CNB:')],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Banco del Barrio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Resumen por tipo
                        Text(
                          'Transacciones por tipo:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Expanded(child: _buildSummaryList()),

                        // Añadir antes del Total final
                        if (_reportData.containsKey('totalPagos') &&
                            _reportData.containsKey('totalRetiros')) ...[
                          Divider(thickness: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pagos:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '\$${(_reportData['totalPagos'] as double? ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Retiros:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '\$${(_reportData['totalRetiros'] as double? ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Total
                        Divider(thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${(_reportData['total'] as double? ?? 0.0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                // Cambiar el color según si es positivo o negativo
                                color:
                                    (_reportData['total'] as double? ?? 0.0) >=
                                            0
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareReport,
                      icon: Icon(Icons.share),
                      label: Text('Compartir'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateAndDownloadPDF,
                      icon: Icon(Icons.download),
                      label: Text('Descargar PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Método para construir la lista de tipos de transacciones con sus totales
  Widget _buildSummaryList() {
    // Verificar si hay datos
    final summary = _reportData['summary'];
    final int count = _reportData['count'] as int? ?? 0;

    if (summary == null || (summary is Map && summary.isEmpty) || count == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay transacciones para esta fecha',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Asegurémonos de que summary es un Map
    final Map summaryMap = summary is Map ? summary : {};

    // Construir la lista de tipos con sus totales
    return ListView.builder(
      itemCount: summaryMap.length,
      itemBuilder: (context, index) {
        final type = summaryMap.keys.elementAt(index).toString();
        final amount = summaryMap.values.elementAt(index);

        // Determinar icono según el tipo
        IconData typeIcon;
        Color typeColor;

        if (type == 'Retiro') {
          typeIcon = Icons.money_off;
          typeColor = Colors.orange;
        } else if (type == 'Pago de Servicio') {
          typeIcon = Icons.payment;
          typeColor = Colors.blue;
        } else {
          typeIcon = Icons.receipt_long;
          typeColor = Colors.grey;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(typeIcon, color: typeColor, size: 20),
              SizedBox(width: 8),
              Text(type),
              Spacer(),
              Text(
                '\$${(amount is num ? amount : 0.0).toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
