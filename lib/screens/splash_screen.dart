// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

Future<void> _checkAuth() async {
  // Esperamos un tiempo suficiente para que el AuthProvider se inicialice
  await Future.delayed(Duration(seconds: 3));
  
  if (!mounted) return;
  
  // Verificar el estado de autenticación
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  print('SplashScreen: Estado de autenticación: ${authProvider.authStatus}');
  print('SplashScreen: ¿Usuario autenticado? ${authProvider.isAuthenticated}');
  if (authProvider.user != null) {
    print('SplashScreen: Usuario: ${authProvider.user!.nombre}, Token: ${authProvider.user!.token.substring(0, 10)}...');
  }
  
  // Si el usuario está autenticado, ir a Home; de lo contrario, ir a Login
  if (authProvider.isAuthenticated) {
    print('SplashScreen: Redirigiendo a Home');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  } else {
    print('SplashScreen: Redirigiendo a Login');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono de la app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance,
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            
            // Nombre de la app
            Text(
              'RíoCaja Smart',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Gestión de Comprobantes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 40),
            
            // Indicador de carga
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }
}