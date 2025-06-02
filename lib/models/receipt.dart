class Receipt {
  final String fecha;           // dd/MM/yyyy
  final String hora;            // HH:mm:ss
  final String tipo;            // Tipo detectado del escaneo
  final String nroTransaccion;  // Número de transacción
  final double valorTotal;      // Valor del comprobante
  final String fullText;        // Texto completo escaneado

  Receipt({
    required this.fecha,
    required this.hora,
    required this.tipo,
    required this.nroTransaccion,
    required this.valorTotal,
    required this.fullText,
  });

  // Convertir a Map para envío al backend
  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'hora': hora,
      'tipo': tipo,
      'nro_transaccion': nroTransaccion,
      'valor_total': valorTotal,
      'full_text': fullText,
    };
  }

  // Crear objeto desde Map (del backend)
  factory Receipt.fromJson(Map<String, dynamic> json) {
    // Manejar formato de fecha (convertir guiones a barras para consistencia visual)
    String fechaStr = json['fecha'] ?? '';
    if (fechaStr.contains('-')) {
      fechaStr = fechaStr.replaceAll('-', '/');
    }
    
    return Receipt(
      fecha: fechaStr,
      hora: json['hora'] ?? '',
      tipo: json['tipo'] ?? '',
      nroTransaccion: json['nro_transaccion'] ?? '',
      valorTotal: (json['valor_total'] is num) 
          ? json['valor_total'].toDouble() 
          : 0.0,
      fullText: json['full_text'] ?? '',
    );
  }

  // Método para obtener icono según el tipo
  static String getIconForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return 'money_off';
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return 'mobile_friendly';
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return 'savings';
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return 'send';
      case 'PAGO GIRO':
        return 'receipt';
      default: // Pago de Servicio y otros
        return 'payment';
    }
  }

  // Método para obtener color según el tipo
  static String getColorForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return 'orange';
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return 'purple';
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return 'green';
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return 'indigo';
      case 'PAGO GIRO':
        return 'teal';
      default: // Pago de Servicio y otros
        return 'blue';
    }
  }
}