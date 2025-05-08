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
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isGenerating = false;
  bool _isLoading = true;
  bool _reportGenerated = false;
  Map<String, dynamic> _reportData = {};
  final ApiService _apiService = ApiService();

   // Lista para almacenar fechas disponibles
  List<DateTime> _availableDates = [];
  bool _loadingDates = true;

  @override
  void initState() {
    super.initState();

    // Inicializar la API con el contexto y verificar autenticación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar si el usuario está autenticado
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        // Si no está autenticado, redirigir a login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión no válida. Inicie sesión para continuar.'),
            backgroundColor: Colors.red,
          ),
        );

        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
        return;
      }

      // Si está autenticado, configurar API y generar reporte
      _apiService.setContext(context);
      if (authProvider.user?.token != null) {
        _apiService.setAuthToken(authProvider.user!.token);
        print(
          'Token configurado: ${authProvider.user!.token.substring(0, 10)}...',
        );
      }

      // Cargar fechas disponibles y luego generar reporte para la fecha actual
      _loadAvailableDates();
    });
  }
  
  // Método para cargar las fechas disponibles
  Future<void> _loadAvailableDates() async {
    setState(() {
      _loadingDates = true;
    });
    
    try {
      // Obtener todos los comprobantes para extraer las fechas únicas
      final provider = Provider.of<ReceiptsProvider>(context, listen: false);
      provider.setContext(context);
      await provider.loadReceipts();
      
      // Extraer fechas únicas
      final receipts = provider.receipts;
      Set<String> uniqueDates = {};
      
      for (final receipt in receipts) {
        if (receipt.fecha.isNotEmpty) {
          uniqueDates.add(receipt.fecha);
        }
      }
      
      // Convertir strings de fecha a objetos DateTime
      List<DateTime> dates = [];
      for (final dateStr in uniqueDates) {
        try {
          // Formato esperado: dd/MM/yyyy
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            dates.add(DateTime(year, month, day));
          }
        } catch (e) {
          print('Error al parsear fecha: $dateStr - $e');
        }
      }
      
      // Ordenar fechas de más reciente a más antigua
      dates.sort((a, b) => b.compareTo(a));
      
      setState(() {
        _availableDates = dates;
        _loadingDates = false;
        
        // Si hay fechas disponibles, seleccionar la más reciente
        if (dates.isNotEmpty) {
          _selectedDate = dates.first;
        }
        
        // Generar reporte para la fecha seleccionada
        _generateReport();
      });
    } catch (e) {
      print('Error al cargar fechas disponibles: $e');
      setState(() {
        _loadingDates = false;
        // Generar reporte para la fecha actual de todos modos
        _generateReport();
      });
    }
  }

  void _selectDate(BuildContext context) async {
    if (_loadingDates) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cargando fechas disponibles...'),
        ),
      );
      return;
    }
    
    // Si no hay fechas disponibles, mostrar un calendario normal
    if (_availableDates.isEmpty) {
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
      return;
    }
    
    // Mostrar un diálogo con las fechas disponibles
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleccionar Fecha'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                final isSelected = date.year == _selectedDate.year &&
                                  date.month == _selectedDate.month &&
                                  date.day == _selectedDate.day;
                
                return ListTile(
                  title: Text(DateFormat('dd/MM/yyyy').format(date)),
                  trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (date != _selectedDate) {
                      setState(() {
                        _selectedDate = date;
                        _reportGenerated = false;
                      });
                      // Generar nuevo reporte para la fecha seleccionada
                      _generateReport();
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Permitir seleccionar cualquier fecha del calendario
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
              },
              child: Text('Otra fecha'),
            ),
          ],
        );
      },
    );
  }

void _generateReport() {
  setState(() {
    _isGenerating = true;
    _reportGenerated = false;
  });

  // Usar formato con barras diagonales para la URL del endpoint
  String formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
  print('Generando reporte para la fecha: $formattedDate');

  // Construir reporte manualmente
  _buildManualReport(formattedDate)
      .then((reportData) {
        setState(() {
          _reportData = reportData;
          _isLoading = false;
          _isGenerating = false;
          _reportGenerated = true;

          print('Reporte manual generado: $reportData');
        });
      })
      .catchError((error) {
        print('Error al generar reporte manual: $error');
        setState(() {
          _isLoading = false;
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
    // Obtener comprobantes por fecha directamente usando el formato con guiones
    final url = '${_apiService.baseUrl}/receipts/date/$dateStr';
    print('Obteniendo comprobantes para reporte manual: $url');

    // Usamos el método público getHeaders
    final headers = _apiService.getHeaders();
    print('Headers de autenticación: $headers');

    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: 60));

    print('Código de respuesta: ${response.statusCode}');

    // Verificar si el token ha expirado y manejarlo adecuadamente
    if (response.statusCode == 401) {
      print('Error 401: Token expirado o no válido');
      // Mostrar mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sesión expirada. Inicie sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );

      // Cerrar sesión para refrescar token
      Provider.of<AuthProvider>(context, listen: false).logout();

      // Navegar a pantalla de login después de un retraso
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });

      return {
        'summary': {},
        'total': 0.0,
        'date': dateStr,
        'count': 0,
        'error': 'Sesión expirada',
      };
    }

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
        // MODIFICADO: Ahora sumar Retiro y EFECTIVO MOVIL juntos
        if (tipo == 'Retiro' || tipo == 'EFECTIVO MOVIL') {
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
        'Total calculado: Pagos ($totalPagos) - Retiros y Efectivo Móvil ($totalRetiros) = $total',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Generando PDF...')));

      // Crear el PDF
      final pdf = pw.Document();

      // Mantener formato con barras para visualización
      final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
      final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      // Obtener datos del reporte
      final summary = _reportData['summary'] as Map<dynamic, dynamic>? ?? {};
      final total = _reportData['total'] as double? ?? 0.0;
      final count = _reportData['count'] as int? ?? 0;
      final totalPagos = _reportData['totalPagos'] as double? ?? 0.0;
      final totalRetiros = _reportData['totalRetiros'] as double? ?? 0.0;

      // Agregar contenido al PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RíoCaja Smart - Reporte de Cierre',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
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
                          pw.Text(
                            '${DateFormat('dd/MM/yyyy').format(DateTime.now())} $currentTime',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Resumen de transacciones
                pw.Text(
                  'Resumen de Transacciones',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
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
                            child: pw.Text(
                              'Tipo',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(5),
                            child: pw.Text(
                              'Valor',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
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
                      pw.Text(
                        'TOTAL:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],

                pw.SizedBox(height: 40),

                pw.Text(
                  '© RíoCaja Smart ${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      // Guardar el PDF usando formato con guiones para el nombre del archivo
      // pero mantener formato con barras para la visualización
      final tempDir = await getTemporaryDirectory();
      final fechaGuiones = DateFormat('dd-MM-yyyy').format(_selectedDate);
      final filePath = '${tempDir.path}/reporte_cierre_${fechaGuiones}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Compartir el PDF
      await Share.shareXFiles([
        XFile(filePath),
      ], subject: 'Reporte de Cierre - $dateStr');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF generado y compartido')));
    } catch (e) {
      print('Error al generar PDF: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
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

      reportText +=
          '\nGenerado el: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}';

      // Compartir el texto
      await Share.share(reportText, subject: 'Reporte de Cierre - $dateStr');
    } catch (e) {
      print('Error al compartir reporte: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al compartir reporte: $e')));
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

    // Usamos los headers del ApiService que ya incluyen el token
    final headers = _apiService.getHeaders();
    print('Headers para todos los comprobantes: $headers');

    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: 60));

    // Verificar si el token ha expirado y manejarlo adecuadamente
    if (response.statusCode == 401) {
      print(
        'Error 401: Token expirado o no válido en obtención de todos los comprobantes',
      );
      // Mostrar mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sesión expirada. Inicie sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );

      // Cerrar sesión
      Provider.of<AuthProvider>(context, listen: false).logout();

      // Navegar a pantalla de login después de un retraso
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });

      return {
        'summary': {},
        'total': 0.0,
        'date': dateStr,
        'count': 0,
        'error': 'Sesión expirada',
      };
    }

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> allReceipts = jsonResponse['data'] ?? [];

      print('Total de comprobantes obtenidos: ${allReceipts.length}');

      // Si dateStr tiene guiones (como se espera para las llamadas a la API)
      String fechaConBarras = dateStr;
      if (dateStr.contains('-')) {
        fechaConBarras = dateStr.replaceAll('-', '/');
      }

      // Filtrar por fecha - intentar con ambos formatos para mayor seguridad
      final List<dynamic> receipts =
          allReceipts
              .where(
                (receipt) =>
                    receipt['fecha'] == dateStr ||
                    receipt['fecha'] == fechaConBarras,
              )
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
        // MODIFICADO: Ahora sumar Retiro y EFECTIVO MOVIL juntos
        if (tipo == 'Retiro' || tipo == 'EFECTIVO MOVIL') {
          totalRetiros += valor;
        } else {
          totalPagos += valor;
        }

        // Depuración: Mostrar datos del comprobante
        print(
          'Comprobante ${receipt['nro_transaccion']}: Tipo=$tipo, Valor=$valor',
        );
      }

      // Calcular el total final (Pagos de Servicio - Retiros y Efectivo Móvil)
      double total = totalPagos - totalRetiros;
      print(
        'Total calculado: Pagos ($totalPagos) - Retiros y Efectivo Móvil ($totalRetiros) = $total',
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
      appBar: AppBar(
        title: Text('Reporte de Cierre'),
        actions: [
          if (_reportGenerated)
            IconButton(
              icon: Icon(Icons.share),
              tooltip: 'Compartir',
              onPressed: _shareReport,
            ),
          if (_reportGenerated)
            IconButton(
              icon: Icon(Icons.download),
              tooltip: 'Descargar PDF',
              onPressed: _generateAndDownloadPDF,
            ),
        ],
      ),
      body: _isLoading || _loadingDates
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _generateReport();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selección de fecha con indicador de fechas disponibles
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha del Reporte',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today),
                                    SizedBox(width: 12),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            if (_availableDates.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${_availableDates.length} fechas disponibles',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Resumen del reporte
                    _buildReportSummary(),
                    
                    // Si aún no se ha generado el reporte y no está cargando
                    if (!_reportGenerated && !_isGenerating)
                      Center(
                        child: ElevatedButton(
                          onPressed: _generateReport,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text('Generar Reporte'),
                        ),
                      ),
                      
                    // Si se está generando el reporte
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
                  ],
                ),
              ),
            ),
      floatingActionButton: _reportGenerated
          ? FloatingActionButton(
              onPressed: _generateAndDownloadPDF,
              child: Icon(Icons.picture_as_pdf),
              tooltip: 'Generar PDF',
            )
          : null,
    );
  }
  
  // Método para construir el resumen del reporte
  Widget _buildReportSummary() {
    if (!_reportGenerated) {
      return SizedBox.shrink();
    }
    
    final summary = _reportData['summary'] as Map<dynamic, dynamic>? ?? {};
    final total = _reportData['total'] as double? ?? 0.0;
    final count = _reportData['count'] as int? ?? 0;
    final totalPagos = _reportData['totalPagos'] as double? ?? 0.0;
    final totalRetiros = _reportData['totalRetiros'] as double? ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reporte del Día',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            
            if (count == 0) ...[
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                    SizedBox(height: 16),
                    Text('No hay transacciones en esta fecha'),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ] else ...[
              // Resumen por tipo de comprobante
              Text(
                'Resumen por Tipo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              
              ...summary.entries.map((entry) {
                IconData icon;
                Color iconColor;
                
                switch (entry.key) {
                  case 'Retiro':
                    icon = Icons.money_off;
                    iconColor = Colors.orange;
                    break;
                  case 'EFECTIVO MOVIL':
                    icon = Icons.mobile_friendly;
                    iconColor = Colors.purple;
                    break;
                  case 'DEPOSITO':
                    icon = Icons.savings;
                    iconColor = Colors.green;
                    break;
                  case 'RECARGA CLARO':
                    icon = Icons.phone_android;
                    iconColor = Colors.red;
                    break;
                  default:
                    icon = Icons.payment;
                    iconColor = Colors.blue;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 16),
                      SizedBox(width: 8),
                      Text(entry.key.toString()),
                      Spacer(),
                      Text('\$${(entry.value as num).toStringAsFixed(2)}'),
                    ],
                  ),
                );
              }).toList(),
              
              Divider(),
              
              // Totales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Pagos:'),
                  Text('\$${totalPagos.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Retiros:'),
                  Text('\$${totalRetiros.toStringAsFixed(2)}'),
                ],
              ),
              Divider(),
              Row(


                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              
              // Número de transacciones
              Center(
                child: Text(
                  'Total de transacciones: $count',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
            
            SizedBox(height: 16),
            
            // Botones de acción
            if (count > 0) ...[
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _shareReport,
                    icon: Icon(Icons.share),
                    label: Text('Compartir'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _generateAndDownloadPDF,
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('Generar PDF'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}