// lib/models/user.dart - CON REFRESH TOKEN Y SIN ROL POR DEFECTO
class User {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String token;
  final String? refreshToken;     
  final String estado;
  final String? codigoCorresponsal;
  final String? nombreLocal;
  final bool perfilCompleto;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.token,
    this.refreshToken,            
    this.estado = 'activo',
    this.codigoCorresponsal,
    this.nombreLocal,
    this.perfilCompleto = false,
  });

  // Convertir a Map para almacenamiento local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'token': token,
      'refresh_token': refreshToken, 
      'estado': estado,
      'codigo_corresponsal': codigoCorresponsal,
      'nombre_local': nombreLocal,
      'perfil_completo': perfilCompleto,
    };
  }

  // ✅ CORREGIDO: Crear objeto desde Map SIN valor por defecto para rol
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'],  // ← SIN valor por defecto - usa el que viene del backend
      token: json['token'] ?? '',
      refreshToken: json['refresh_token'], 
      estado: json['estado'] ?? 'activo',
      codigoCorresponsal: json['codigo_corresponsal'],
      nombreLocal: json['nombre_local'],
      perfilCompleto: json['perfil_completo'] ?? false,
    );
  }
  
  // Método para crear una copia con nuevos valores
  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? rol,
    String? token,
    String? refreshToken,          
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
      refreshToken: refreshToken ?? this.refreshToken,  
      estado: estado ?? this.estado,
      codigoCorresponsal: codigoCorresponsal ?? this.codigoCorresponsal,
      nombreLocal: nombreLocal ?? this.nombreLocal,
      perfilCompleto: perfilCompleto ?? this.perfilCompleto,
    );
  }
}