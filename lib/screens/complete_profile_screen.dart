// lib/screens/complete_profile_screen.dart - PARTE 1 (Líneas 1-300)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/services/auth_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String? codigoCorresponsal;

  const CompleteProfileScreen({Key? key, this.codigoCorresponsal}) : super(key: key);

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreLocalController = TextEditingController();
  final _nombreCompletoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _codigoVerificado = false;

  @override
  void initState() {
    super.initState();
    // Si viene con código pre-asignado, verificarlo
    if (widget.codigoCorresponsal != null) {
      _codigoController.text = widget.codigoCorresponsal!;
      _verificarCodigo();
    }
    
    // Pre-llenar email y nombre si están disponibles
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _nombreCompletoController.text = authProvider.user!.nombre;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreLocalController.dispose();
    _nombreCompletoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verificarCodigo() async {
    if (_codigoController.text.isEmpty) return;

    try {
      final authService = AuthService();
      final isValid = await authService.verifyCorresponsalCode(_codigoController.text);
      setState(() {
        _codigoVerificado = isValid;
      });

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de corresponsal inválido'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código verificado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error verificando código: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar código. Intente nuevamente.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _completarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_codigoVerificado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debe verificar el código de corresponsal primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.completeProfile(
        codigoCorresponsal: _codigoController.text,
        nombreLocal: _nombreLocalController.text,
        nombreCompleto: _nombreCompletoController.text,
        password: _passwordController.text,
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
            content: Text('Error al completar perfil. Verifique los datos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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
        automaticallyImplyLeading: false, // No permitir volver atrás
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
                        'Complete su perfil para continuar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Necesita completar esta información antes de usar la aplicación',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Código de corresponsal
                TextFormField(
                  controller: _codigoController,
                  decoration: InputDecoration(
                    labelText: 'Código de Corresponsal*',
                    hintText: 'Ingrese el código asignado por el administrador',
                    prefixIcon: Icon(Icons.qr_code),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_codigoController.text.isNotEmpty)
                          Icon(
                            _codigoVerificado ? Icons.check_circle : Icons.error,
                            color: _codigoVerificado ? Colors.green : Colors.red,
                          ),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: _verificarCodigo,
                          tooltip: 'Verificar código',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: _codigoVerificado ? Colors.green.shade50 : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    setState(() {
                      _codigoVerificado = false;
                    });
                  },
                  onFieldSubmitted: (value) => _verificarCodigo(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El código de corresponsal es requerido';
                    }
                    if (value.length < 3) {
                      return 'El código debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Nombre del local
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

                // Email (solo lectura)
                TextFormField(
                  initialValue: authProvider.user?.email ?? '',
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    helperText: 'Email registrado (no se puede modificar)',
                  ),
                  enabled: false,
                ),
                SizedBox(height: 16),

                // Nombre completo
                TextFormField(
                  controller: _nombreCompletoController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo*',
                    hintText: 'Su nombre completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    helperText: 'Nombre y apellidos completos',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre completo es requerido';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Nueva contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña*',
                    hintText: 'Mínimo 8 caracteres',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(),
                    helperText: 'Contraseña segura para acceder al sistema',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    // Validaciones adicionales de seguridad
                    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                      return 'La contraseña debe contener letras y números';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña*',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(),
                    helperText: 'Confirme la contraseña ingresada arriba',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme su contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Indicador de progreso
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progreso de completación:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _getCompletionProgress(),
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(_getCompletionProgress() * 100).toInt()}% completado',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Botón para completar perfil
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_codigoVerificado) ? null : _completarPerfil,
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

                // Botón de verificar código (si no está verificado)
                if (!_codigoVerificado && _codigoController.text.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _verificarCodigo,
                      icon: Icon(Icons.verified_user),
                      label: Text('Verificar Código'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                      ),
                    ),
                  ),
                
                if (!_codigoVerificado && _codigoController.text.isNotEmpty)
                  SizedBox(height: 16),

                // Nota informativa
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información importante:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• El código de corresponsal debe ser proporcionado por un administrador\n'
                                  '• Una vez completado el perfil, no podrá modificar estos datos\n'
                                  '• Contacte al administrador si no tiene el código o hay problemas',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Información de contacto (opcional)
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
                          Icon(Icons.support_agent, color: Colors.green.shade700, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '¿Necesita ayuda?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Si tiene problemas para completar su perfil, contacte al administrador del sistema.',
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

  // Método para calcular el progreso de completación
  double _getCompletionProgress() {
    int completedFields = 0;
    int totalFields = 5;

    if (_codigoVerificado) completedFields++;
    if (_nombreLocalController.text.isNotEmpty) completedFields++;
    if (_nombreCompletoController.text.isNotEmpty) completedFields++;
    if (_passwordController.text.isNotEmpty) completedFields++;
    if (_confirmPasswordController.text.isNotEmpty && 
        _confirmPasswordController.text == _passwordController.text) completedFields++;

    return completedFields / totalFields;
  }
}