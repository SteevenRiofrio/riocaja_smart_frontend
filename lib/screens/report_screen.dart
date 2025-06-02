// lib/screens/report_screen.dart - VERSIÓN ACTUALIZADA CON SELECTOR INTELIGENTE
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/services/report_service.dart';
import 'package:riocaja_smart/services/pdf_service.dart';
import 'package:riocaja_smart/widgets/report_summary_widget.dart';
import 'package:riocaja_smart/widgets/smart_date_picker.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingDates = true;
  Map<String, dynamic> _reportData = {};
  List<String> _availableDates = [];
  
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
    
    // Cargar fechas disponibles primero
    _loadAvailableDates();
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

  // Cargar fechas disponibles con comprobantes
  Future<void> _loadAvailableDates() async {
    setState(() => _isLoadingDates = true);

    try {
      print('Cargando fechas disponibles...');
      
      // Obtener todas las fechas disponibles del servicio
      final availableDates = await _reportService.getAvailableDates();
      
      setState(() {
        _availableDates = availableDates;
        _isLoadingDates = false;
      });
      
      print('Fechas disponibles cargadas: ${availableDates.length}');
      
      // Si hay fechas disponibles y la fecha seleccionada no está en la lista,
      // seleccionar la fecha más reciente
      if (availableDates.isNotEmpty) {
        final currentDateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
        if (!availableDates.contains(currentDateStr)) {
          // Asumir que las fechas están ordenadas, tomar la primera (más reciente)
          final latestDateStr = availableDates.first;
          _selectedDate = _parseDate(latestDateStr) ?? DateTime.now();
        }
        
        // Generar reporte para la fecha seleccionada
        await _generateReport();
      }
    } catch (e) {
      print('Error al cargar fechas disponibles: $e');
      
      // Verificar si es error de autenticación
      if (e.toString().contains('Sesión expirada') || e.toString().contains('Token')) {
        _handleAuthError();
      } else {
        setState(() {
          _availableDates = [];
          _isLoadingDates = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar fechas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Manejar selección de nueva fecha
  void _onDateSelected(DateTime newDate) {
    if (newDate != _selectedDate) {
      setState(() {
        _selectedDate = newDate;
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
            onPressed: (_isLoading || _isLoadingDates) ? null : () {
              _loadAvailableDates(); // Recargar fechas y reporte
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAvailableDates(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector inteligente de fechas
              SmartDatePicker(
                selectedDate: _selectedDate,
                onDateSelected: _onDateSelected,
                availableDates: _availableDates,
                isLoading: _isLoadingDates,
              ),
              
              SizedBox(height: 20),
              
              // Resumen del reporte
              if (_isLoading)
                _buildLoadingWidget()
              else if (_availableDates.isNotEmpty)
                ReportSummaryWidget(
                  reportData: _reportData,
                  selectedDate: _selectedDate,
                  onShareReport: _shareReport,
                  onGeneratePDF: _generatePDF,
                )
              else
                _buildNoDataWidget(),
            ],
          ),
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
                'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget cuando no hay datos
  Widget _buildNoDataWidget() {
    return Card(
      child: Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'No hay comprobantes registrados',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Escanee algunos comprobantes primero',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}