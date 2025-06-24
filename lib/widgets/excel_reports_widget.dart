// lib/widgets/excel_reports_widget.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/services/excel_report_service.dart';
import 'package:riocaja_smart/screens/excel_reports_screen.dart';
import 'package:intl/intl.dart';

class ExcelReportsWidget extends StatefulWidget {
  @override
  _ExcelReportsWidgetState createState() => _ExcelReportsWidgetState();
}

class _ExcelReportsWidgetState extends State<ExcelReportsWidget> {
  final ExcelReportService _reportService = ExcelReportService();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
  }

  void _initializeService() {
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _reportService.setContext(context);
      if (authProvider.isAuthenticated) {
        _reportService.setAuthToken(authProvider.user?.token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.table_chart,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reportes Excel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Exporta tus datos a Excel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExcelReportsScreen(),
                      ),
                    );
                  },
                  child: Text('Ver Más'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Botones de acceso rápido
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Hoy',
                    Icons.today,
                    Colors.blue,
                    () => _generateTodayReport(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Esta Semana',
                    Icons.view_week,
                    Colors.orange,
                    () => _generateThisWeekReport(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Este Mes',
                    Icons.calendar_month,
                    Colors.purple,
                    () => _generateThisMonthReport(),
                  ),
                ),
              ],
            ),
            
            if (_isGenerating) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Generando reporte Excel...',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 12),
            
            // Información adicional
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade700, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Características de los reportes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Datos completos con todos los campos\n'
                    '• Formato profesional con colores y estilos\n'
                    '• Resúmenes automáticos y totales\n'
                    '• Compatible con Excel y Google Sheets',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 70,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.shade100,
          foregroundColor: color.shade700,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.shade200),
          ),
          padding: EdgeInsets.all(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Métodos para generar reportes rápidos
  Future<void> _generateTodayReport() async {
    if (!mounted) return;
    
    setState(() => _isGenerating = true);
    try {
      await _reportService.generateDailyReport(DateTime.now());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateThisWeekReport() async {
    if (!mounted) return;
    
    setState(() => _isGenerating = true);
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      await _reportService.generateWeeklyReport(startOfWeek);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateThisMonthReport() async {
    if (!mounted) return;
    
    setState(() => _isGenerating = true);
    try {
      await _reportService.generateMonthlyReport(DateTime.now());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}