// lib/screens/login_screen.dart - ACTUALIZADO CON TEXT CONSTANTS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/register_screen.dart';
import 'package:riocaja_smart/screens/complete_profile_screen.dart';
import 'package:riocaja_smart/screens/forgot_password_screen.dart';
import 'package:riocaja_smart/utils/text_constants.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

if (success) {
  // NOTIFICACIÓN MEJORADA
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Bienvenido! Sesión iniciada'),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text(
                'Se envió notificación a tu correo',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    ),
  );

print('🔑 LOGIN SCREEN DEBUG:');
print('   Usuario: ${authProvider.user?.nombre}');
print('   Rol: "${authProvider.user?.rol}"');
print('   Perfil completo: ${authProvider.user?.perfilCompleto}');
print('   Rol == admin: ${authProvider.user?.rol == 'admin'}');
print('   Rol == asesor: ${authProvider.user?.rol == 'asesor'}');

  // Navegación después de un pequeño delay
  Future.delayed(Duration(milliseconds: 800), () {
    // 🚨 PRIORIDAD: Admin y Asesor SIEMPRE van directo al dashboard
    if (authProvider.user?.rol == 'admin' || authProvider.user?.rol == 'asesor') {
      print('🔑 LoginScreen: ${authProvider.user?.rol} detectado - directo al dashboard');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } 
    // Solo usuarios CNB verifican perfil completo
    else if (authProvider.user?.perfilCompleto == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CompleteProfileScreen(
            codigoCorresponsal: authProvider.codigoCorresponsal,
          ),
        ),
      );
    }
  });
} else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? TextConstants.credencialesInvalidas),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TextConstants.errorGeneral}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Header con logo
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              TextConstants.appName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              TextConstants.appSubtitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Formulario de login
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  TextConstants.iniciarSesion,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 32),
                                
                                // Campo de email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: TextConstants.email,
                                    hintText: 'correo@ejemplo.com',
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Por favor ingrese un email válido';
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
                                    labelText: TextConstants.password,
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
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su contraseña';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 8),
                                
                                // Enlace de recuperar contraseña
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(TextConstants.olvidoPassword),
                                  ),
                                ),
                                SizedBox(height: 24),
                                
                                // Botón de login
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                          )
                                        : Text(
                                            TextConstants.ingresar,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                
                                // Enlace de registro
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(TextConstants.noTieneCuenta),
                                    TextButton(
                                      onPressed: _isLoading ? null : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(TextConstants.registrese),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Información adicional para usuarios nuevos
                      Container(
                        margin: EdgeInsets.all(16),
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
                                  TextConstants.informacionNuevosUsuarios,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              TextConstants.infoNuevosUsuarios,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Versión de la aplicación
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Center(
                          child: Text(
                            TextConstants.appVersion,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}