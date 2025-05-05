// lib/models/user.dart
class User {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String token;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.token,
  });

  // Convertir a Map para almacenamiento local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'token': token,
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
    );
  }
}