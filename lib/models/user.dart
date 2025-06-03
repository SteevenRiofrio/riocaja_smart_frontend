// lib/models/user.dart - ACTUALIZADO
class User {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String token;
  final String estado;
  final String? codigoCorresponsal;  // NUEVO
  final String? nombreLocal;        // NUEVO
  final bool perfilCompleto;        // NUEVO

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.token,
    this.estado = 'activo',
    this.codigoCorresponsal,        // NUEVO
    this.nombreLocal,               // NUEVO
    this.perfilCompleto = false,    // NUEVO
  });

  // Convertir a Map para almacenamiento local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'token': token,
      'estado': estado,
      'codigo_corresponsal': codigoCorresponsal,  // NUEVO
      'nombre_local': nombreLocal,                // NUEVO
      'perfil_completo': perfilCompleto,          // NUEVO
    };
  }

  // Crear objeto desde Map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'lector',
      token: json['token'] ?? '',
      estado: json['estado'] ?? 'activo',
      codigoCorresponsal: json['codigo_corresponsal'],        // NUEVO
      nombreLocal: json['nombre_local'],                      // NUEVO
      perfilCompleto: json['perfil_completo'] ?? false,       // NUEVO
    );
  }
  
  // NUEVO: Método para crear una copia con nuevos valores
  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? rol,
    String? token,
    String? estado,
    String? codigoCorresponsal,
    String? nombreLocal,
    bool? perfilCompleto,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      token: token ?? this.token,
      estado: estado ?? this.estado,
      codigoCorresponsal: codigoCorresponsal ?? this.codigoCorresponsal,
      nombreLocal: nombreLocal ?? this.nombreLocal,
      perfilCompleto: perfilCompleto ?? this.perfilCompleto,
    );
  }
}