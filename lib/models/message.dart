// lib/models/message.dart
class Message {
  final String id;
  final String titulo;
  final String contenido;
  final String tipo;
  final DateTime fechaCreacion;
  final String creadoPor;
  final DateTime? visibleHasta;
  final List<String>? destinatarios;
  final List<String> leidoPor;
  
  Message({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.tipo,
    required this.fechaCreacion,
    required this.creadoPor,
    this.visibleHasta,
    this.destinatarios,
    required this.leidoPor,
  });
  
  // Verificar si el mensaje ha sido leído por un usuario específico
  bool isReadBy(String userId) {
    return leidoPor.contains(userId);
  }
  
  // Verificar si el mensaje ha expirado
  bool get isExpired {
    if (visibleHasta == null) return false;
    return DateTime.now().isAfter(visibleHasta!);
  }
  
  // Convertir a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'tipo': tipo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'creadoPor': creadoPor,
      'visibleHasta': visibleHasta?.toIso8601String(),
      'destinatarios': destinatarios,
      'leidoPor': leidoPor,
    };
  }
  
  // Crear desde Map
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      tipo: json['tipo'] ?? 'informativo',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : DateTime.now(),
      creadoPor: json['creado_por'] ?? '',
      visibleHasta: json['visible_hasta'] != null 
          ? DateTime.parse(json['visible_hasta']) 
          : null,
      destinatarios: json['destinatarios'] != null 
          ? List<String>.from(json['destinatarios']) 
          : null,
      leidoPor: json['leido_por'] != null 
          ? List<String>.from(json['leido_por']) 
          : [],
    );
  }
}