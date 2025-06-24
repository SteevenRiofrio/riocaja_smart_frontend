// lib/screens/complete_profile_screen.dart - CORREGIDO
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String? codigoCorresponsal;

  const CompleteProfileScreen({Key? key, this.codigoCorresponsal}) : super(key: key);

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreLocalController = TextEditingController();
  
  bool _isLoading = false;
  String? _codigoCorresponsal;

  @override
  void initState() {
    super.initState();
    // El código de corresponsal viene del backend cuando el admin aprueba al usuario
    _codigoCorresponsal = widget.codigoCorresponsal;
    print('Código de corresponsal recibido: $_codigoCorresponsal');
  }

  @override
  void dispose() {
    _nombreLocalController.dispose();
    super.dispose();
  }

  Future<void> _completarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_codigoCorresponsal == null || _codigoCorresponsal!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró el código de corresponsal. Contacte al administrador.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      print('Completando perfil con código: $_codigoCorresponsal');
      
      // Solo enviamos el nombre del local, el resto de datos ya están en el backend
      final success = await authProvider.completeProfile(
        codigoCorresponsal: _codigoCorresponsal!,
        nombreLocal: _nombreLocalController.text.trim(),
        nombreCompleto: authProvider.user?.nombre ?? '', // Ya está guardado
        password: '', // No cambiamos la contraseña
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar perfil. ${authProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al completar perfil: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Completar Perfil'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header informativo
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Complete la información de su local',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Su cuenta ha sido aprobada. Solo falta completar algunos datos.',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Código de corresponsal (solo lectura, asignado por admin)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code, color: Colors.green.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Código de Corresponsal*',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _codigoCorresponsal ?? 'No asignado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Este código fue asignado por el administrador',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Nombre del local (único campo editable)
                TextFormField(
                  controller: _nombreLocalController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Local*',
                    hintText: 'Ej: Farmacia San Juan, Tienda El Ahorro',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                    helperText: 'Nombre comercial de su establecimiento',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre del local es requerido';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Email (solo lectura, ya registrado)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.grey.shade600),
                          SizedBox(width: 8),
                          Text(
                            'Correo Electrónico',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        authProvider.user?.email ?? 'No disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Email registrado (no se puede modificar)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Nombre completo (solo lectura, ya registrado)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey.shade600),
                          SizedBox(width: 8),
                          Text(
                            'Nombre Completo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        authProvider.user?.nombre ?? 'No disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nombre registrado (no se puede modificar)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Botón para completar perfil
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.0,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Completando perfil...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text(
                                'Completar Perfil',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 16),

                // Nota informativa
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.green.shade700, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Información:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Su cuenta ya ha sido aprobada por un administrador\n'
                        '• Solo necesita completar el nombre de su local\n'
                        '• Una vez completado, tendrá acceso completo al sistema\n'
                        '• Su código de corresponsal es único e intransferible',
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}