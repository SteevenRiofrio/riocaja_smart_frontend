// lib/screens/verify_reset_code_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:riocaja_smart/services/password_reset_service.dart';
import 'package:riocaja_smart/screens/new_password_screen.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String email;

  const VerifyResetCodeScreen({Key? key, required this.email}) : super(key: key);

  @override
  _VerifyResetCodeScreenState createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordResetService = PasswordResetService();
  
  bool _isLoading = false;
  bool _isCodeValid = false;
  int _timeRemaining = 600; // 10 minutos en segundos
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            _canResend = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  String get _formattedTime {
    int minutes = _timeRemaining ~/ 60;
    int seconds = _timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _validateCode(String value) {
    setState(() {
      _isCodeValid = value.length == 6 && RegExp(r'^\d{6}$').hasMatch(value);
    });
  }

  String? _getCodeError(String value) {
    if (value.isEmpty) return 'El código es requerido';
    if (value.length != 6) return 'El código debe tener 6 dígitos';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'El código solo debe contener números';
    return null;
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _passwordResetService.verifyResetCode(
        widget.email,
        _codeController.text.trim(),
      );

      if (result['success']) {
        // Código verificado correctamente
        _showSuccessMessage();
        
        // Navegar a pantalla de nueva contraseña
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NewPasswordScreen(
              email: widget.email,
              verifiedCode: _codeController.text.trim(),
            ),
          ),
        );
      } else {
        // Error en la verificación
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

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      final result = await _passwordResetService.requestPasswordReset(widget.email);

      if (result['success']) {
        // Reiniciar contador
        setState(() {
          _timeRemaining = 600;
          _canResend = false;
        });
        _startCountdown();

        _showSuccessSnackBar('Nuevo código enviado a tu email');
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Error al reenviar código: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Código verificado correctamente'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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
        title: Text('Verificar Código'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
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
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mail_outline,
                        size: 50,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Revisa tu Email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(text: 'Enviamos un código de 6 dígitos a\n'),
                          TextSpan(
                            text: widget.email,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
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
                    // Campo de código con diseño especial
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCodeValid ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: TextFormField(
                        controller: _codeController,
                        onChanged: _validateCode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          fontFamily: 'monospace',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Código de Verificación',
                          hintText: '123456',
                          hintStyle: TextStyle(
                            letterSpacing: 8,
                            color: Colors.grey.shade400,
                          ),
                          suffixIcon: _codeController.text.isNotEmpty
                              ? Icon(
                                  _isCodeValid ? Icons.check_circle : Icons.error,
                                  color: _isCodeValid ? Colors.green : Colors.red,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        ),
                        validator: (value) => _getCodeError(value ?? ''),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Contador de tiempo
                    if (!_canResend)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: Colors.orange.shade700, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'El código expira en: $_formattedTime',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Botón verificar código
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_isCodeValid) ? null : _verifyCode,
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
                                  Text('Verificando...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified),
                                  SizedBox(width: 8),
                                  Text(
                                    'Verificar Código',
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
                    
                    SizedBox(height: 24),
                    
                    // Botón reenviar código
                    if (_canResend)
                      OutlinedButton(
                        onPressed: _isLoading ? null : _resendCode,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Reenviar Código'),
                          ],
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade700),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Opción para cambiar email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿Email incorrecto?'),
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            Navigator.pop(context);
                          },
                          child: Text('Cambiar Email'),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Información adicional
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
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
                                '¿No ves el email?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Revisa tu carpeta de spam o correo no deseado\n'
                            '• Asegúrate de tener conexión a internet\n'
                            '• El código puede tardar unos minutos en llegar\n'
                            '• Verifica que el email esté escrito correctamente',
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
      ),
    );
  }
}