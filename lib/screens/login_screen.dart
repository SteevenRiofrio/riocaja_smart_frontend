// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/register_screen.dart';
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
  bool _rememberMe = true; // Por defecto activado
  bool _isLoading = false; // Estado para mostrar indicador de carga

  @override
  void initState() {
    super.initState();
    // Cargar preferencia de "Mantener sesión iniciada"
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
      
      // Mostrar indicador de carga mientras se inicia sesión
      setState(() {
        _isLoading = true;
      });
      
      // Establecer preferencia de "Mantener sesión iniciada"
      await authProvider.setRememberMe(_rememberMe);
      
      // Intenta iniciar sesión
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Ocultar indicador de carga
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inicio de sesión exitoso'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Navegar a la pantalla principal después de un breve retraso
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        });
      } else {
        // Comprobar si el error es debido a que la cuenta está pendiente
        if (authProvider.errorMessage.contains('pendiente') || 
            authProvider.errorMessage.contains('pendientes') ||
            authProvider.errorMessage.contains('aprobación')) {
          // Mostrar un mensaje específico para cuentas pendientes
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
          // Si el error está relacionado con el token
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
          // Mostrar error general
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
                          SizedBox(height: 16),
                          
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