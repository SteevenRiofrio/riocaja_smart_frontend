// lib/widgets/excel_reports_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/services/excel_report_service.dart';
import 'package:riocaja_smart/models/excel_report_models.dart';
import 'package:intl/intl.dart';

class ExcelReportsWidget extends StatefulWidget {
  @override
  _ExcelReportsWidgetState createState() => _ExcelReportsWidgetState();
}

class _ExcelReportsWidgetState extends State<ExcelReportsWidget> {
  final ExcelReportService _reportService = ExcelReportService();
  
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _reportType = 'general';
  String? _selectedCorresponsal;
  
  bool _isLoading = false;
  bool _isGenerating = false;
  
  List<DateRangeOption> _dateOptions = [];
  List<ReportTemplate> _templates = [];
  List<CorresponsalOption> _corresponsales = [];
  ReportStatistics? _currentStats;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadDateOptions();
    _loadTemplates();
    _loadCorresponsales();
  }

  void _initializeService() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _reportService.setContext(context);
    if (authProvider.isAuthenticated) {
      _reportService.setAuthToken(authProvider.user?.token);
    }
  }

  Future<void> _loadDateOptions() async {
    try {
      setState(() => _isLoading = true);
      final options = await _reportService.getDateRangeOptions();
      setState(() {
        _dateOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando opciones de fecha: $e');
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _reportService.getReportTemplates();
      setState(() {
        _templates = templates;