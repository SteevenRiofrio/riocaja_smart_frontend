// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

class DateUtils {
  // Configurar los nombres en español para evitar problemas de localización
  static const Map<int, String> _spanishMonths = {
    1: 'Enero',
    2: 'Febrero', 
    3: 'Marzo',
    4: 'Abril',
    5: 'Mayo',
    6: 'Junio',
    7: 'Julio',
    8: 'Agosto',
    9: 'Septiembre',
    10: 'Octubre',
    11: 'Noviembre',
    12: 'Diciembre',
  };

  static const Map<int, String> _spanishWeekdays = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles', 
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  static const Map<int, String> _spanishWeekdaysShort = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue', 
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };

  // Formatear fecha completa en español
  static String formatDateSpanish(DateTime date) {
    final weekday = _spanishWeekdays[date.weekday] ?? '';
    final day = date.day;
    final month = _spanishMonths[date.month] ?? '';
    final year = date.year;
    
    return '$weekday, $day de $month de $year';
  }

  // Formatear fecha corta en español
  static String formatDateShortSpanish(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    
    return '$day/$month/$year';
  }

  // Formatear solo el día de la semana
  static String formatWeekdaySpanish(DateTime date) {
    return _spanishWeekdays[date.weekday] ?? '';
  }

  // Formatear día de la semana corto
  static String formatWeekdayShortSpanish(DateTime date) {
    return _spanishWeekdaysShort[date.weekday] ?? '';
  }

  // Formatear fecha para mostrar en selector
  static String formatDateForSelector(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    
    // Normalizar fechas para comparación (solo día, mes, año)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
    
    if (normalizedDate == normalizedToday) {
      return 'HOY - ${formatDateShortSpanish(date)}';
    } else if (normalizedDate == normalizedYesterday) {
      return 'AYER - ${formatDateShortSpanish(date)}';
    } else {
      return '${formatWeekdayShortSpanish(date).toUpperCase()} - ${formatDateShortSpanish(date)}';
    }
  }

  // Parsear fecha desde string con múltiples formatos
  static DateTime? parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try {
      // Formato dd/MM/yyyy
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      
      // Formato dd-MM-yyyy
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      
      // Formato ISO (yyyy-MM-dd)
      if (dateStr.length == 10 && dateStr.substring(4, 5) == '-') {
        return DateTime.parse(dateStr);
      }
      
    } catch (e) {
      print('Error al parsear fecha: $dateStr - $e');
    }
    
    return null;
  }

  // Convertir fecha al formato de la API (dd-MM-yyyy)
  static String formatDateForApi(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    
    return '$day-$month-$year';
  }

  // Normalizar formato de fecha
  static String normalizeDateFormat(String dateStr) {
    final parsed = parseDate(dateStr);
    if (parsed != null) {
      return formatDateShortSpanish(parsed);
    }
    return dateStr;
  }

  // Verificar si dos fechas son el mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Obtener nombre del mes en español
  static String getMonthNameSpanish(int month) {
    return _spanishMonths[month] ?? 'Mes $month';
  }

  // Obtener diferencia en días de forma legible
  static String getDateDifference(DateTime date) {
    final now = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedNow = DateTime(now.year, now.month, now.day);
    
    final difference = normalizedNow.difference(normalizedDate).inDays;
    
    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference == -1) {
      return 'Mañana';
    } else if (difference > 1) {
      return 'Hace $difference días';
    } else {
      return 'En ${(-difference)} días';
    }
  }
}