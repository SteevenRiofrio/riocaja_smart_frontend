// lib/models/receipt.dart
// MODIFICADO: Actualizado para manejar formatos de fecha

class Receipt {
  final String banco;
  final String fecha;
  final String hora;
  final String tipo;
  final String nroTransaccion;
  final String nroControl;
  final String local;
  final String fechaAlternativa;
  final String corresponsal;
  final String tipoCuenta;
  final double valorTotal;
  final String fullText;

  Receipt({
    required this.banco,
    required this.fecha,
    required this.hora,
    required this.tipo, 
    required this.nroTransaccion,
    required this.nroControl,
    required this.local,
    required this.fechaAlternativa,
    required this.corresponsal,
    required this.tipoCuenta,
    required this.valorTotal,
    required this.fullText,
  });

  // Convertir a Map para almacenamiento local o envío al backend
  Map<String, dynamic> toJson() {
    return {
      'banco': banco,
      'fecha': fecha,
      'hora': hora,
      'tipo': tipo,
      'nro_transaccion': nroTransaccion, // Cambiado de 'nroTransaccion'
      'nro_control': nroControl, // Cambiado de 'nroControl'
      'local': local,
      'fecha_alternativa': fechaAlternativa, // Cambiado de 'fechaAlternativa'
      'corresponsal': corresponsal,
      'tipo_cuenta': tipoCuenta, // Cambiado de 'tipoCuenta'
      'valor_total': valorTotal, // Cambiado de 'valorTotal'
      'full_text': fullText, // Cambiado de 'fullText'
    };
  }

  // Crear objeto desde Map
  factory Receipt.fromJson(Map<String, dynamic> json) {
    // MODIFICADO: Mejorar el manejo de formatos de fecha
    String fechaStr = json['fecha'] ?? '';
    
    // Si el formato es con guiones, convertir a formato con barras para mantener la 
    // consistencia en la visualización en la app (el backend espera guiones al enviar)
    if (fechaStr.contains('-')) {
      fechaStr = fechaStr.replaceAll('-', '/');
    }
    
    // Hacer lo mismo con fecha alternativa
    String fechaAlt = json['fecha_alternativa'] ?? '';
    if (fechaAlt.contains('-')) {
      fechaAlt = fechaAlt.replaceAll('-', '/');
    }
    
    return Receipt(
      banco: json['banco'] ?? 'Banco del Barrio | Banco Guayaquil',
      fecha: fechaStr,
      hora: json['hora'] ?? '',
      tipo: json['tipo'] ?? '',
      nroTransaccion:
          json['nro_transaccion'] ?? '', // Nombre del campo según el backend
      nroControl:
          json['nro_control'] ?? '', // Nombre del campo según el backend
      local: json['local'] ?? '',
      fechaAlternativa: fechaAlt, // Nombre del campo según el backend
      corresponsal: json['corresponsal'] ?? '',
      tipoCuenta:
          json['tipo_cuenta'] ?? '', // Nombre del campo según el backend
      valorTotal:
          (json['valor_total'] is num)
              ? json['valor_total'].toDouble()
              : 0.0, // Mejor manejo de tipos
      fullText: json['full_text'] ?? '', // Nombre del campo según el backend
    );
  }
}