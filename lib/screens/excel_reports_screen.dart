// lib/screens/excel_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/services/excel_report_service.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:riocaja_smart/utils/date_utils.dart' as DateUtilsCustom;

class ExcelReportsScreen extends StatefulWidget {
  @override
  _ExcelReportsScreenState createState() => _ExcelReportsScreenState();
}

class _ExcelReportsScreenState extends State<ExcelReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExcelReportService _reportService = ExcelReportService();
  
  // Estados de carga
  bool _isGeneratingDaily = false;
  bool _isGeneratingRange = false;
  bool _isGeneratingWeekly = false;
  bool _isGeneratingMonthly = false;
  
  // Fechas seleccionadas
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  DateTime _selectedWeek = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupService();
    _checkAuthentication();
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupService() {
    _reportService.setContext(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      _reportService.setAuthToken(authProvider.user?.token);
    }
  }

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

  @override
  Widget build(BuildContext context) {
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
              Text('Sesión no válida', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Por favor inicie sesión nuevamente'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                ),
                child: Text('Ir a Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes Excel'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.today), text: 'Diario'),
            Tab(icon: Icon(Icons.date_range), text: 'Rango'),
            Tab(icon: Icon(Icons.view_week), text: 'Semanal'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Mensual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTab(),
          _buildRangeTab(),
          _buildWeeklyTab(),
          _buildMonthlyTab(),
        ],
      ),
    );
  }

  // Tab de reporte diario
  Widget _buildDailyTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Reporte Diario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Genera un reporte completo de todas las transacciones de un día específico.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  
                  // Selector de fecha
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('Fecha seleccionada'),
                    subtitle: Text(DateUtilsCustom.DateUtils.formatDateSpanish(_selectedDate)),
                    trailing: Icon(Icons.edit),
                    onTap: () => _selectDate(context, (date) {
                      setState(() => _selectedDate = date);
                    }),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botón de generar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingDaily ? null : _generateDailyReport,
                      icon: _isGeneratingDaily 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.file_download),
                      label: Text(_isGeneratingDaily ? 'Generando...' : 'Generar Reporte Diario'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          _buildReportInfoCard([
            'Incluye todas las transacciones del día',
            'Resumen ejecutivo con totales',
            'Detalle completo de cada transacción',
            'Información del corresponsal (Admin/Operador)',
          ]),
        ],
      ),
    );
  }

  // Tab de reporte por rango
  Widget _buildRangeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.orange.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Reporte por Rango de Fechas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Genera un reporte de múltiples días con resumen diario y totales generales.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  
                  // Selector de fecha inicio
                  ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Fecha de inicio'),
                    subtitle: Text(DateUtilsCustom.DateUtils.formatDateShortSpanish(_startDate)),
                    trailing: Icon(Icons.edit),
                    onTap: () => _selectDate(context, (date) {
                      setState(() {
                        _startDate = date;
                        if (_endDate.isBefore(_startDate)) {
                          _endDate = _startDate;
                        }
                      });
                    }),
                  ),
                  
                  // Selector de fecha fin
                  ListTile(
                    leading: Icon(Icons.stop),
                    title: Text('Fecha de fin'),
                    subtitle: Text(DateUtilsCustom.DateUtils.formatDateShortSpanish(_endDate)),
                    trailing: Icon(Icons.edit),
                    onTap: () => _selectDate(context, (date) {
                      setState(() {
                        _endDate = date;
                        if (_startDate.isAfter(_endDate)) {
                          _startDate = _endDate;
                        }
                      });
                    }),
                  ),
                  
                  // Mostrar días seleccionados
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Días incluidos: ${_endDate.difference(_startDate).inDays + 1}',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botones de rango rápido
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickRangeButton('Últimos 7 días', () {
                        setState(() {
                          _endDate = DateTime.now();
                          _startDate = _endDate.subtract(Duration(days: 6));
                        });
                      }),
                      _buildQuickRangeButton('Últimos 15 días', () {
                        setState(() {
                          _endDate = DateTime.now();
                          _startDate = _endDate.subtract(Duration(days: 14));
                        });
                      }),
                      _buildQuickRangeButton('Último mes', () {
                        setState(() {
                          _endDate = DateTime.now();
                          _startDate = _endDate.subtract(Duration(days: 29));
                        });
                      }),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botón de generar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingRange ? null : _generateRangeReport,
                      icon: _isGeneratingRange 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.file_download),
                      label: Text(_isGeneratingRange ? 'Generando...' : 'Generar Reporte por Rango'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          _buildReportInfoCard([
            'Resumen por cada día del rango',
            'Comparación entre días',
            'Totales y promedios del período',
            'Detalle completo de todas las transacciones',
          ]),
        ],
      ),
    );
  }

  // Tab de reporte semanal
  Widget _buildWeeklyTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.view_week, color: Colors.green.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Reporte Semanal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Genera un reporte semanal con análisis día por día de lunes a domingo.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  
                  // Selector de semana
                  ListTile(
                    leading: Icon(Icons.calendar_view_week),
                    title: Text('Semana seleccionada'),
                    subtitle: Text(_getWeekRangeText(_selectedWeek)),
                    trailing: Icon(Icons.edit),
                    onTap: () => _selectWeek(context),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botones de semana rápida
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedWeek = _getStartOfWeek(DateTime.now());
                            });
                          },
                          child: Text('Esta semana'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedWeek = _getStartOfWeek(DateTime.now().subtract(Duration(days: 7)));
                            });
                          },
                          child: Text('Semana pasada'),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botón de generar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingWeekly ? null : _generateWeeklyReport,
                      icon: _isGeneratingWeekly 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.file_download),
                      label: Text(_isGeneratingWeekly ? 'Generando...' : 'Generar Reporte Semanal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          _buildReportInfoCard([
            'Análisis por días de la semana',
            'Identificación de patrones semanales',
            'Resumen de lunes a domingo',
            'Comparación entre días laborables y fines de semana',
          ]),
        ],
      ),
    );
  }

  // Tab de reporte mensual
  Widget _buildMonthlyTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.purple.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Reporte Mensual',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Genera un reporte completo del mes con análisis por semanas y tipos de transacción.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  
                  // Selector de mes
                  ListTile(
                    leading: Icon(Icons.calendar_month),
                    title: Text('Mes seleccionado'),
                    subtitle: Text(DateFormat('MMMM yyyy', 'es_ES').format(_selectedMonth)),
                    trailing: Icon(Icons.edit),
                    onTap: () => _selectMonth(context),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botones de mes rápido
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime.now();
                            });
                          },
                          child: Text('Este mes'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              final now = DateTime.now();
                              _selectedMonth = DateTime(now.year, now.month - 1, 1);
                            });
                          },
                          child: Text('Mes pasado'),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botón de generar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingMonthly ? null : _generateMonthlyReport,
                      icon: _isGeneratingMonthly 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.file_download),
                      label: Text(_isGeneratingMonthly ? 'Generando...' : 'Generar Reporte Mensual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          _buildReportInfoCard([
            'Análisis detallado del mes completo',
            'Desglose por semanas del mes',
            'Resumen por tipos de transacción',
            'Estadísticas y promedios mensuales',
            'Tendencias y patrones del período',
          ]),
        ],
      ),
    );
  }

  // Widget para información del reporte
  Widget _buildReportInfoCard(List<String> features) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                SizedBox(width: 8),
                Text(
                  'Contenido del reporte:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  // Widget para botones de rango rápido
  Widget _buildQuickRangeButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  // Métodos para generar reportes
  Future<void> _generateDailyReport() async {
    setState(() => _isGeneratingDaily = true);
    try {
      await _reportService.generateDailyReport(_selectedDate);
    } finally {
      setState(() => _isGeneratingDaily = false);
    }
  }

  Future<void> _generateRangeReport() async {
    setState(() => _isGeneratingRange = true);
    try {
      await _reportService.generateRangeReport(_startDate, _endDate);
    } finally {
      setState(() => _isGeneratingRange = false);
    }
  }

  Future<void> _generateWeeklyReport() async {
    setState(() => _isGeneratingWeekly = true);
    try {
      await _reportService.generateWeeklyReport(_selectedWeek);
    } finally {
      setState(() => _isGeneratingWeekly = false);
    }
  }

  Future<void> _generateMonthlyReport() async {
    setState(() => _isGeneratingMonthly = true);
    try {
      await _reportService.generateMonthlyReport(_selectedMonth);
    } finally {
      setState(() => _isGeneratingMonthly = false);
    }
  }

  // Métodos auxiliares para selección de fechas
  Future<void> _selectDate(BuildContext context, Function(DateTime) onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Locale('es', 'ES'),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _selectWeek(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeek,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Locale('es', 'ES'),
      helpText: 'Seleccionar una fecha de la semana',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    
    if (picked != null) {
      setState(() {
        _selectedWeek = _getStartOfWeek(picked);
      });
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Locale('es', 'ES'),
      helpText: 'Seleccionar mes',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  // Utilidades para fechas
  DateTime _getStartOfWeek(DateTime date) {
    int weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _getWeekRangeText(DateTime weekStart) {
    final weekEnd = weekStart.add(Duration(days: 6));
    final startStr = DateFormat('dd/MM').format(weekStart);
    final endStr = DateFormat('dd/MM/yyyy').format(weekEnd);
    return '$startStr - $endStr';
  }

}