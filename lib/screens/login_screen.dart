// lib/screens/login_screen.dart - ACTUALIZADO CON ENLACE DE RECUPERACIÓN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/register_screen.dart';
import 'package:riocaja_smart/screens/complete_profile_screen.dart';
import 'package:riocaja_smart/screens/forgot_password_screen.dart';  // NUEVA IMPORTACIÓN
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      setState(() {
        _isLoading = true;
      });
      
      await authProvider.setRememberMe(_rememberMe);
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inicio de sesión exitoso'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            if (authProvider.user?.rol == 'admin' || authProvider.user?.rol == 'operador') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            } else if (authProvider.needsProfileCompletion) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CompleteProfileScreen(
                    codigoCorresponsal: authProvider.codigoCorresponsal,
                  ),
                ),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }
          }
        });
      } else {
        if (authProvider.errorMessage.contains('pendiente') || 
            authProvider.errorMessage.contains('pendientes') ||
            authProvider.errorMessage.contains('aprobación')) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Cuenta Pendiente de Aprobación'),
                content: Text(
                  'Su cuenta aún no ha sido aprobada por un administrador. '
                  'Por favor, espere a que un administrador revise y apruebe su solicitud.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Entendido'),
                  ),
                ],
              ),
            );
          }
        } else if (authProvider.errorMessage.toLowerCase().contains('token')) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Error de Autenticación'),
                content: Text(
                  'Hubo un problema con la autenticación. Por favor, intente nuevamente.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Entendido'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo y título
                    SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 60,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'RíoCaja Smart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Iniciar Sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 40),
                    
                    // Formulario
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Campo de email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Correo Electrónico',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su correo electrónico';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Ingrese un correo electrónico válido';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Campo de contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su contraseña';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 8),
                          
                          // NUEVO: Enlace "¿Olvidaste tu contraseña?"
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: (_isLoading || authProvider.isLoading) ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Opción "Mantener sesión iniciada"
                          SwitchListTile(
                            title: Text('Mantener sesión iniciada'),
                            subtitle: Text(
                              'No cerrar sesión al salir de la aplicación',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _rememberMe,
                            onChanged: (bool value) {
                              setState(() {
                                _rememberMe = value;
                              });
                            },
                            activeColor: Colors.green.shade700,
                          ),
                          SizedBox(height: 24),
                          
                          // Botón de inicio de sesión
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_isLoading || authProvider.isLoading) ? null : _login,
                              child: (_isLoading || authProvider.isLoading)
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
                                        Text('Iniciando sesión...'),
                                      ],
                                    )
                                  : Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(fontSize: 16),
                                    ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green.shade700,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Opción para registrarse
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('¿No tienes una cuenta?'),
                              TextButton(
                                onPressed: (_isLoading || authProvider.isLoading) ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text('Regístrate'),
                              ),
                            ],
                          ),
                          
                          // Mostrar mensaje de error si existe
                          if (authProvider.errorMessage.isNotEmpty && !authProvider.isLoading && !_isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  authProvider.errorMessage,
                                  style: TextStyle(color: Colors.red.shade900),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          
                          // Información adicional para usuarios nuevos
                          SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.all(12),
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
                                      'Información para nuevos usuarios',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Los nuevos usuarios deben ser aprobados por un administrador\n'
                                  '• Después de la aprobación, completará su perfil con el código de corresponsal\n'
                                  '• Contacte al administrador si tiene dudas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Versión de la aplicación
                          SizedBox(height: 40),
                          Center(
                            child: Text(
                              'Versión 1.0.0',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
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
        },
      ),
    );
  }
}