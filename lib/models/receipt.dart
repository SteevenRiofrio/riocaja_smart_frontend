// lib/models/receipt.dart
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
    return Receipt(
      banco: json['banco'] ?? 'Banco del Barrio | Banco Guayaquil',
      fecha: json['fecha'] ?? '',
      hora: json['hora'] ?? '',
      tipo: json['tipo'] ?? 'Pago de Servicio',
      nroTransaccion:
          json['nro_transaccion'] ?? '', // Nombre del campo según el backend
      nroControl:
          json['nro_control'] ?? '', // Nombre del campo según el backend
      local: json['local'] ?? '',
      fechaAlternativa:
          json['fecha_alternativa'] ?? '', // Nombre del campo según el backend
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
