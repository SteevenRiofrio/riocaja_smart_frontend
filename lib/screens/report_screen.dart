// lib/screens/report_screen.dart - VERSIÓN REFACTORIZADA Y SIMPLIFICADA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/services/report_service.dart';
import 'package:riocaja_smart/services/pdf_service.dart';
import 'package:riocaja_smart/widgets/report_summary_widget.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic> _reportData = {};
  
  // Servicios
  final ReportService _reportService = ReportService();
  final PdfService _pdfService = PdfService();

  @override
  void initState() {
    super.initState();
    // Configurar locale en español
    Intl.defaultLocale = 'es_ES';
    
    // Verificar autenticación
    _checkAuthentication();
    
    // Configurar servicios
    _setupServices();
    
    // Generar reporte inicial
    _generateReport();
  }

  // Verificar autenticación
  void _checkAuthentication() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  // Configurar servicios con contexto y token
  void _setupServices() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Configurar ReportService
    _reportService.setContext(context);
    if (authProvider.isAuthenticated) {
      _reportService.setAuthToken(authProvider.user?.token);
    }
    
    print('Servicios configurados correctamente');
  }

  // Generar reporte para la fecha seleccionada
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    try {
      print('Generando reporte para: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
      
      // Convertir fecha al formato esperado por la API (dd-MM-yyyy)
      final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate);
      
      // Generar reporte usando el servicio
      final reportData = await _reportService.generateReportByDate(dateStr);
      
      // Verificar si hay error de autenticación
      if (reportData['needsAuth'] == true) {
        _handleAuthError();
        return;
      }
      
      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
      
      print('Reporte generado exitosamente: ${reportData['count']} comprobantes');
    } catch (e) {
      print('Error al generar reporte: $e');
      
      // Verificar si es error de autenticación
      if (e.toString().contains('Sesión expirada') || e.toString().contains('Token')) {
        _handleAuthError();
      } else {
        setState(() {
          _reportData = {};
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Manejar errores de autenticación
  void _handleAuthError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sesión expirada. Inicie sesión nuevamente.'),
        backgroundColor: Colors.red,
      ),
    );
    
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  // Seleccionar fecha
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Locale('es', 'ES'),
      helpText: 'Seleccionar fecha del reporte',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      fieldLabelText: 'Ingrese fecha',
      fieldHintText: 'dd/mm/aaaa',
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      await _generateReport();
    }
  }

  // Navegar a fecha anterior
  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(Duration(days: 1));
    });
    _generateReport();
  }

  // Navegar a fecha siguiente
  void _nextDay() {
    final tomorrow = _selectedDate.add(Duration(days: 1));
    if (tomorrow.isBefore(DateTime.now().add(Duration(days: 1)))) {
      setState(() {
        _selectedDate = tomorrow;
      });
      _generateReport();
    }
  }

  // Compartir reporte como texto
  Future<void> _shareReport() async {
    try {
      if (_reportData.isEmpty || (_reportData['count'] as int? ?? 0) == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay datos para compartir')),
        );
        return;
      }

      final reportText = _reportService.generateReportText(_reportData, _selectedDate);
      await Share.share(
        reportText,
        subject: 'Reporte de Cierre - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
      );
    } catch (e) {
      print('Error al compartir reporte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir reporte'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Generar y compartir PDF
  Future<void> _generatePDF() async {
    try {
      if (_reportData.isEmpty || (_reportData['count'] as int? ?? 0) == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay datos para generar PDF')),
        );
        return;
      }

      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Generando PDF...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      final success = await _pdfService.generateAndSharePDF(_reportData, _selectedDate);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generado y compartido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al generar PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar autenticación en tiempo de renderizado
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text('Error de Autenticación')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Sesión no válida',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Por favor inicie sesión nuevamente'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Ir a Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes de Cierre'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _generateReport,
            tooltip: 'Actualizar reporte',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _generateReport,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de fecha
              _buildDateSelector(),
              SizedBox(height: 20),
              
              // Resumen del reporte
              if (_isLoading)
                _buildLoadingWidget()
              else
                ReportSummaryWidget(
                  reportData: _reportData,
                  selectedDate: _selectedDate,
                  onShareReport: _shareReport,
                  onGeneratePDF: _generatePDF,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget selector de fecha
  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Fecha',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            // Navegación de fechas
            Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _previousDay,
                  icon: Icon(Icons.chevron_left),
                  tooltip: 'Día anterior',
                ),
                
                Expanded(
                  child: InkWell(
                    onTap: _isLoading ? null : _selectDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 20),
                          SizedBox(width: 8),
                          Text(
                            _formatDateInSpanish(_selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                IconButton(
                  onPressed: (_isLoading || _selectedDate.isAfter(DateTime.now().subtract(Duration(days: 1)))) 
                      ? null 
                      : _nextDay,
                  icon: Icon(Icons.chevron_right),
                  tooltip: 'Día siguiente',
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Botones de acceso rápido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _generateReport();
                  },
                  child: Text('Hoy'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _selectedDate = DateTime.now().subtract(Duration(days: 1));
                    });
                    _generateReport();
                  },
                  child: Text('Ayer'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _selectedDate = DateTime.now().subtract(Duration(days: 7));
                    });
                    _generateReport();
                  },
                  child: Text('Hace 7 días'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget de carga
  Widget _buildLoadingWidget() {
    return Card(
      child: Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generando reporte...'),
              SizedBox(height: 8),
              Text(
                'Fecha: ${_formatDateInSpanish(_selectedDate)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Formatear fecha en español
  String _formatDateInSpanish(DateTime date) {
    final formatter = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'es_ES');
    return formatter.format(date);
  }
}