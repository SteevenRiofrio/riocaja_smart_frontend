import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  // Estados de validación en tiempo real
  bool _isNombreValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validación en tiempo real del nombre
  void _validateNombre(String value) {
    setState(() {
      _isNombreValid = _isValidNombre(value);
    });
  }

  // Validación en tiempo real del email
  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = _isValidEmail(value);
    });
  }

  // Validación en tiempo real de la contraseña
  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = _isValidPassword(value);
      // Re-validar confirmación si ya tiene contenido
      if (_confirmPasswordController.text.isNotEmpty) {
        _isConfirmPasswordValid = _confirmPasswordController.text == value;
      }
    });
  }

  // Validación en tiempo real de confirmación
  void _validateConfirmPassword(String value) {
    setState(() {
      _isConfirmPasswordValid = value == _passwordController.text && value.isNotEmpty;
    });
  }

  // Métodos de validación
  bool _isValidNombre(String nombre) {
    if (nombre.isEmpty) return false;
    
    // Debe tener al menos 2 palabras (nombre y apellido)
    final palabras = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.length < 2) return false;
    
    // Solo letras, espacios, acentos y apostrofes
    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s']+$");
    if (!regex.hasMatch(nombre)) return false;
    
    // Longitud mínima y máxima
    if (nombre.length < 3 || nombre.length > 50) return false;
    
    return true;
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Regex más estricto para email
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) return false;
    
    // Longitud máxima
    if (email.length > 100) return false;
    
    // No debe empezar o terminar con punto
    if (email.startsWith('.') || email.endsWith('.')) return false;
    
    // No debe tener puntos consecutivos
    if (email.contains('..')) return false;
    
    return true;
  }

  bool _isValidPassword(String password) {
    if (password.isEmpty) return false;
    
    // Longitud mínima
    if (password.length < 8) return false;
    
    // Longitud máxima
    if (password.length > 50) return false;
    
    // Debe contener al menos una letra
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) return false;
    
    // Debe contener al menos un número
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    
    // Debe contener al menos un carácter especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    
    // No debe contener espacios
    if (password.contains(' ')) return false;
    
    return true;
  }

  // Obtener mensaje de error para nombre
  String? _getNombreError(String value) {
    if (value.isEmpty) return 'El nombre completo es requerido';
    
    final palabras = value.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.length < 2) return 'Ingrese nombre y apellido completos';
    
    if (value.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (value.length > 50) return 'El nombre no puede exceder 50 caracteres';
    
    final regex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s']+$");
    if (!regex.hasMatch(value)) return 'Solo se permiten letras, espacios y apostrofes';
    
    return null;
  }

  // Obtener mensaje de error para email
  String? _getEmailError(String value) {
    if (value.isEmpty) return 'El correo electrónico es requerido';
    
    if (value.length > 100) return 'El correo no puede exceder 100 caracteres';
    
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) return 'Ingrese un correo electrónico válido';
    
    if (value.startsWith('.') || value.endsWith('.')) {
      return 'El correo no puede empezar o terminar con punto';
    }
    
    if (value.contains('..')) return 'El correo no puede tener puntos consecutivos';
    
    return null;
  }

  // Obtener mensaje de error para contraseña
  String? _getPasswordError(String value) {
    if (value.isEmpty) return 'La contraseña es requerida';
    
    if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    if (value.length > 50) return 'La contraseña no puede exceder 50 caracteres';
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un número';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un carácter especial';
    }
    
    if (value.contains(' ')) {
      return 'La contraseña no puede contener espacios';
    }
    
    return null;
  }

  // Widget para mostrar indicadores de fortaleza de contraseña
  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return SizedBox.shrink();
    
    List<bool> criteria = [
      _passwordController.text.length >= 8,
      RegExp(r'[a-zA-Z]').hasMatch(_passwordController.text),
      RegExp(r'[0-9]').hasMatch(_passwordController.text),
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text),
      !_passwordController.text.contains(' '),
    ];
    
    List<String> labels = [
      'Al menos 8 caracteres',
      'Contiene letras',
      'Contiene números',
      'Contiene símbolos especiales',
      'Sin espacios',
    ];
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de contraseña:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          ...List.generate(criteria.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    criteria[index] ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: criteria[index] ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: criteria[index] ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      setState(() => _isLoading = true);
      
      try {
        final success = await authProvider.register(
          _nombreController.text.trim(),
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );
        
        if (success) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Registro Exitoso'),
                ],
              ),
              content: Text(
                'Su cuenta ha sido creada y está pendiente de aprobación por parte de un administrador. '
                'Recibirá notificación una vez que su cuenta sea aprobada.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pop(); // Volver a pantalla de login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Entendido'),
                ),
              ],
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Crear una cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Completa la información para registrarte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo de nombre completo
                        TextFormField(
                          controller: _nombreController,
                          onChanged: _validateNombre,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s']")),
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo*',
                            hintText: 'Ej: Juan Carlos Pérez García',
                            prefixIcon: Icon(Icons.person),
                            suffixIcon: _nombreController.text.isNotEmpty
                                ? Icon(
                                    _isNombreValid ? Icons.check_circle : Icons.error,
                                    color: _isNombreValid ? Colors.green : Colors.red,
                                  )
                                : null,
                            border: OutlineInputBorder(),
                            helperText: 'Ingrese su nombre y apellidos completos',
                          ),
                          validator: (value) => _getNombreError(value ?? ''),
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de email
                        TextFormField(
                          controller: _emailController,
                          onChanged: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
                            LengthLimitingTextInputFormatter(100),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico*',
                            hintText: 'ejemplo@correo.com',
                            prefixIcon: Icon(Icons.email),
                            suffixIcon: _emailController.text.isNotEmpty
                                ? Icon(
                                    _isEmailValid ? Icons.check_circle : Icons.error,
                                    color: _isEmailValid ? Colors.green : Colors.red,
                                  )
                                : null,
                            border: OutlineInputBorder(),
                            helperText: 'Será usado para iniciar sesión',
                          ),
                          validator: (value) => _getEmailError(value ?? ''),
                        ),
                        SizedBox(height: 16),
                        
                        // Campo de contraseña
                        TextFormField(
                          controller: _passwordController,
                          onChanged: _validatePassword,
                          obscureText: _obscurePassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Contraseña*',
                            hintText: 'Mínimo 8 caracteres',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_passwordController.text.isNotEmpty)
                                  Icon(
                                    _isPasswordValid ? Icons.check_circle : Icons.error,
                                    color: _isPasswordValid ? Colors.green : Colors.red,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => _getPasswordError(value ?? ''),
                        ),
                        
                        // Indicador de fortaleza de contraseña
                        _buildPasswordStrengthIndicator(),
                        SizedBox(height: 16),
                        
                        // Campo de confirmar contraseña
                        TextFormField(
                          controller: _confirmPasswordController,
                          onChanged: _validateConfirmPassword,
                          obscureText: _obscureConfirmPassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña*',
                            hintText: 'Repita la contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_confirmPasswordController.text.isNotEmpty)
                                  Icon(
                                    _isConfirmPasswordValid ? Icons.check_circle : Icons.error,
                                    color: _isConfirmPasswordValid ? Colors.green : Colors.red,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(),
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
                        SizedBox(height: 32),
                        
                        // Botón de registro
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !_isNombreValid || !_isEmailValid || !_isPasswordValid || !_isConfirmPasswordValid) 
                                ? null 
                                : _register,
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
                                      Text('Registrando...'),
                                    ],
                                  )
                                : Text(
                                    'Registrarse',
                                    style: TextStyle(fontSize: 16),
                                  ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green.shade700,
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Opción para volver a login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¿Ya tienes una cuenta?'),
                            TextButton(
                              onPressed: _isLoading ? null : () {
                                Navigator.pop(context);
                              },
                              child: Text('Inicia sesión'),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        
                        // Información adicional
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, 
                                       color: Colors.blue.shade700, 
                                       size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Información importante',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• Tu cuenta será revisada por un administrador\n'
                                '• Recibirás notificación cuando sea aprobada\n'
                                '• Mantén tus datos actualizados\n'
                                '• Contacta al administrador si tienes dudas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}