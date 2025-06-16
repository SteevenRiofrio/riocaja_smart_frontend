// lib/screens/new_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riocaja_smart/services/password_reset_service.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String verifiedCode;

  const NewPasswordScreen({
    Key? key, 
    required this.email, 
    required this.verifiedCode
  }) : super(key: key);

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordResetService = PasswordResetService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validación en tiempo real de la contraseña
  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = _isValidPassword(value);
      // Re-validar confirmación si ya tiene contenido
      if (_confirmPasswordController.text.isNotEmpty) {
        _isConfirmPasswordValid = _confirmPasswordController.text == value && value.isNotEmpty;
      }
    });
  }

  // Validación en tiempo real de confirmación
  void _validateConfirmPassword(String value) {
    setState(() {
      _isConfirmPasswordValid = value == _passwordController.text && value.isNotEmpty;
    });
  }

  bool _isValidPassword(String password) {
    if (password.isEmpty) return false;
    if (password.length < 8) return false;
    if (password.length > 50) return false;
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    if (password.contains(' ')) return false;
    return true;
  }

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
                  Expanded(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: criteria[index] ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
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

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _passwordResetService.resetPassword(
        widget.email,
        widget.verifiedCode,
        _passwordController.text,
      );

      if (result['success']) {
        // Contraseña cambiada exitosamente
        _showSuccessDialog();
      } else {
        // Error al cambiar contraseña
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('¡Contraseña Actualizada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu contraseña ha sido cambiada exitosamente. '
              'Ya puedes iniciar sesión con tu nueva contraseña.',
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por seguridad, también enviamos una confirmación a tu email.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              // Ir al login y limpiar historial
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Ir al Login'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Contraseña'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No permitir volver atrás
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              
              // Icono y título
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 50,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Crear Nueva Contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Crea una contraseña segura para proteger tu cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo de nueva contraseña
                    TextFormField(
                      controller: _passwordController,
                      onChanged: _validatePassword,
                      obscureText: _obscurePassword,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No espacios
                        LengthLimitingTextInputFormatter(50),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña*',
                        hintText: 'Mínimo 8 caracteres',
                        prefixIcon: Icon(Icons.lock_outline),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        labelText: 'Confirmar Nueva Contraseña*',
                        hintText: 'Repite la contraseña',
                        prefixIcon: Icon(Icons.lock),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme su nueva contraseña';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Botón cambiar contraseña
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_isPasswordValid || !_isConfirmPasswordValid) 
                            ? null 
                            : _changePassword,
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
                                  Text('Cambiando contraseña...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cambiar Contraseña',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green.shade700,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Información de seguridad
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, 
                                   color: Colors.green.shade700, 
                                   size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Consejos de seguridad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Usa una contraseña única que no hayas usado antes\n'
                            '• Combina letras, números y símbolos especiales\n'
                            '• No compartas tu contraseña con nadie\n'
                            '• Guárdala en un lugar seguro\n'
                            '• Cambia tu contraseña periódicamente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Información del email
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.email_outlined, 
                                   color: Colors.blue.shade700, 
                                   size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Cuenta:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Una vez cambiada tu contraseña, recibirás una confirmación en este email.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
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
      ),
    );
  }
}