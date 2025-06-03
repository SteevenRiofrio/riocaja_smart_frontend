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
// lib/screens/complete_profile_screen.dart - CORRECCIÓN PARA VERIFICACIÓN DE CÓDIGO

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
    // Si viene con código pre-asignado, marcarlo como verificado automáticamente
    if (widget.codigoCorresponsal != null && widget.codigoCorresponsal!.isNotEmpty) {
      _codigoController.text = widget.codigoCorresponsal!;
      _codigoVerificado = true; // ✅ MARCARLO COMO VERIFICADO AUTOMÁTICAMENTE
      print('Código pre-asignado: ${widget.codigoCorresponsal}, marcado como verificado');
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
      // ✅ VERIFICAR QUE TENEMOS TOKEN ANTES DE HACER LA VERIFICACIÓN
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.isAuthenticated || authProvider.user?.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación. Por favor inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Verificando código: ${_codigoController.text} con token disponible');
      
      final isValid = await authProvider.verifyCorresponsalCode(_codigoController.text.trim());
      
      setState(() {
        _codigoVerificado = isValid;
      });

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de corresponsal inválido o no coincide con su cuenta'),
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
      
      // ✅ MEJORAR MANEJO DE ERRORES ESPECÍFICOS
      String errorMessage = 'Error al verificar código. Intente nuevamente.';
      
      if (e.toString().contains('token')) {
        errorMessage = 'Error de autenticación. El código será verificado al completar el perfil.';
        // En este caso, no marcar como error crítico
        setState(() {
          _codigoVerificado = true; // Permitir continuar
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: e.toString().contains('token') ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _completarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ✅ PERMITIR CONTINUAR INCLUSO SI LA VERIFICACIÓN FALLÓ POR TOKEN
    // La verificación real se hará en el backend
    final codigoLimpio = _codigoController.text.trim();
    
    if (codigoLimpio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debe ingresar el código de corresponsal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      print('Completando perfil con código: $codigoLimpio');
      
      final success = await authProvider.completeProfile(
        codigoCorresponsal: codigoLimpio,
        nombreLocal: _nombreLocalController.text.trim(),
        nombreCompleto: _nombreCompletoController.text.trim(),
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
            content: Text('Error al completar perfil. Verifique que el código sea correcto.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error al completar perfil: $e');
      
      String errorMessage = 'Error: $e';
      if (e.toString().contains('codigo incorrecto') || e.toString().contains('código incorrecto')) {
        errorMessage = 'El código de corresponsal no es válido para su cuenta.';
      } else if (e.toString().contains('token')) {
        errorMessage = 'Error de autenticación. Por favor inicie sesión nuevamente.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
                        'Complete su perfil para continuar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use el código de corresponsal que le proporcionó el administrador',
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
                            _codigoVerificado ? Icons.check_circle : Icons.help_outline,
                            color: _codigoVerificado ? Colors.green : Colors.orange,
                          ),
                        if (!_codigoVerificado && _codigoController.text.isNotEmpty)
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
                    helperText: widget.codigoCorresponsal != null 
                        ? 'Este código fue asignado por el administrador'
                        : 'La verificación se realizará al completar el perfil',
                    helperStyle: TextStyle(color: Colors.blue.shade600),
                  ),
                  readOnly: widget.codigoCorresponsal != null, // ✅ Solo lectura si viene pre-asignado
                  onChanged: (value) {
                    // Solo permitir cambios si no viene pre-asignado
                    if (widget.codigoCorresponsal == null) {
                      setState(() {
                        _codigoVerificado = false;
                      });
                    }
                  },
                  onFieldSubmitted: (value) {
                    if (widget.codigoCorresponsal == null) {
                      _verificarCodigo();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El código de corresponsal es requerido';
                    }
                    if (value.length < 2) {
                      return 'El código debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Resto de campos igual que antes...
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
                        '• El código será verificado automáticamente al completar el perfil\n'
                        '• Una vez completado, tendrá acceso completo al sistema\n'
                        '• Contacte al administrador si tiene problemas',
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