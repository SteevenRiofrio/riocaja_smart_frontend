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
    
    // Establecer preferencia de "Mantener sesión iniciada"
    await authProvider.setRememberMe(_rememberMe);
    print('LoginScreen: Preferencia de mantener sesión: $_rememberMe');
    
    // Intenta iniciar sesión
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (success) {
      print('LoginScreen: Inicio de sesión exitoso');
      // Imprimir para verificar
      print('LoginScreen: Usuario: ${authProvider.user!.nombre}, Token: ${authProvider.user!.token.substring(0, 10)}...');
      
      // Navegar a la pantalla principal
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Mostrar error
      if (!mounted) return;
      print('LoginScreen: Error - ${authProvider.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
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
                              onPressed: authProvider.isLoading ? null : _login,
                              child: authProvider.isLoading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                                onPressed: () {
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