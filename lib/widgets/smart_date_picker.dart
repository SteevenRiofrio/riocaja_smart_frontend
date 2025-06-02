// lib/widgets/smart_date_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riocaja_smart/utils/date_utils.dart' as DateUtilsCustom;

class SmartDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<String> availableDates; // Fechas que tienen comprobantes
  final bool isLoading;

  const SmartDatePicker({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availableDates,
    this.isLoading = false,
  }) : super(key: key);

  @override
  _SmartDatePickerState createState() => _SmartDatePickerState();
}

class _SmartDatePickerState extends State<SmartDatePicker> {
  late PageController _pageController;
  late List<DateTime> _availableDateObjects;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _processAvailableDates();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(SmartDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableDates != widget.availableDates) {
      _processAvailableDates();
    }
  }

  void _processAvailableDates() {
    // Convertir las fechas de string a DateTime y ordenarlas
    _availableDateObjects = widget.availableDates
        .map((dateStr) => DateUtilsCustom.DateUtils.parseDate(dateStr))
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();
    
    // Ordenar de más reciente a más antigua
    _availableDateObjects.sort((a, b) => b.compareTo(a));
    
    // Encontrar el índice de la fecha seleccionada
    _currentIndex = _availableDateObjects.indexWhere(
      (date) => DateUtilsCustom.DateUtils.isSameDay(date, widget.selectedDate),
    );
    
    if (_currentIndex == -1 && _availableDateObjects.isNotEmpty) {
      _currentIndex = 0;
      // Si la fecha seleccionada no está en las disponibles, seleccionar la primera
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDateSelected(_availableDateObjects[0]);
      });
    }
  }

  DateTime? _parseDate(String dateStr) {
    return DateUtilsCustom.DateUtils.parseDate(dateStr);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return DateUtilsCustom.DateUtils.isSameDay(date1, date2);
  }

  String _formatDateSpanish(DateTime date) {
    return DateUtilsCustom.DateUtils.formatDateSpanish(date);
  }

  String _formatDateShort(DateTime date) {
    return DateUtilsCustom.DateUtils.formatDateShortSpanish(date);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Card(
        child: Container(
          height: 120,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Cargando fechas disponibles...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_availableDateObjects.isEmpty) {
      return Card(
        child: Container(
          height: 120,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, 
                     size: 48, 
                     color: Colors.grey.shade400),
                SizedBox(height: 8),
                Text(
                  'No hay fechas con comprobantes',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fechas Disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} de ${_availableDateObjects.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Navegador de fechas
            Container(
              height: 80,
              child: Row(
                children: [
                  // Botón anterior
                  IconButton(
                    onPressed: _currentIndex > 0 ? () {
                      setState(() {
                        _currentIndex--;
                      });
                      _pageController.animateToPage(
                        _currentIndex,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      widget.onDateSelected(_availableDateObjects[_currentIndex]);
                    } : null,
                    icon: Icon(Icons.chevron_left),
                    tooltip: 'Fecha anterior',
                  ),
                  
                  // Área de fecha actual
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _availableDateObjects.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        widget.onDateSelected(_availableDateObjects[index]);
                      },
                      itemBuilder: (context, index) {
                        final date = _availableDateObjects[index];
                        final isToday = _isSameDay(date, DateTime.now());
                        final isYesterday = _isSameDay(
                          date, 
                          DateTime.now().subtract(Duration(days: 1))
                        );
                        
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isToday)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8, 
                                    vertical: 2
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'HOY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isYesterday)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8, 
                                    vertical: 2
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'AYER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              
                              SizedBox(height: 4),
                              
                              Text(
                                _formatDateShort(date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              
                              SizedBox(height: 2),
                              
                              Text(
                                DateUtilsCustom.DateUtils.formatWeekdayShortSpanish(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Botón siguiente
                  IconButton(
                    onPressed: _currentIndex < _availableDateObjects.length - 1 ? () {
                      setState(() {
                        _currentIndex++;
                      });
                      _pageController.animateToPage(
                        _currentIndex,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      widget.onDateSelected(_availableDateObjects[_currentIndex]);
                    } : null,
                    icon: Icon(Icons.chevron_right),
                    tooltip: 'Fecha siguiente',
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            // Indicador de puntos
            if (_availableDateObjects.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _availableDateObjects.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex 
                          ? Colors.blue.shade700 
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}