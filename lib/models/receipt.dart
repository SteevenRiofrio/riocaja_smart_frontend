// lib/models/receipt.dart - ACTUALIZADO CON CÓDIGO CORRESPONSAL
class Receipt {
  final String fecha;           // dd/MM/yyyy
  final String hora;            // HH:mm:ss
  final String tipo;            // Tipo detectado del escaneo
  final String nroTransaccion;  // Número de transacción
  final double valorTotal;      // Valor del comprobante
  final String fullText;        // Texto completo escaneado
  
  // NUEVOS CAMPOS PARA ADMIN
  final String? codigoCorresponsal;  // Código del corresponsal que escaneó
  final String? nombreCorresponsal;  // Nombre del corresponsal (opcional)
  final String? usuarioId;           // ID del usuario que escaneó

  Receipt({
    required this.fecha,
    required this.hora,
    required this.tipo,
    required this.nroTransaccion,
    required this.valorTotal,
    required this.fullText,
    this.codigoCorresponsal,        // NUEVO
    this.nombreCorresponsal,        // NUEVO
    this.usuarioId,                 // NUEVO
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
      // Los campos de corresponsal se asignan automáticamente en el backend
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
      
      // NUEVOS CAMPOS DEL BACKEND
      codigoCorresponsal: json['codigo_corresponsal'],
      nombreCorresponsal: json['nombre_corresponsal'],
      usuarioId: json['usuario_id'],
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
      case 'RECARGA CLARO':
      case 'RECARGA':
        return 'phone_android';
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
      case 'RECARGA CLARO':
      case 'RECARGA':
        return 'red';
      default: // Pago de Servicio y otros
        return 'blue';
    }
  }
}