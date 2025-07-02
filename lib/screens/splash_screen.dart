import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/screens/complete_profile_screen.dart';

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
    print('SplashScreen: ¿Necesita completar perfil? ${authProvider.needsProfileCompletion}');
    
    if (authProvider.user != null) {
      print('SplashScreen: Usuario: ${authProvider.user!.nombre}');
      print('SplashScreen: Rol: ${authProvider.user!.rol}');
      print('SplashScreen: Perfil completo: ${authProvider.perfilCompleto}');
      print('SplashScreen: Código corresponsal: ${authProvider.codigoCorresponsal}');
    }
    
    // LÓGICA CORREGIDA: Verificar primero si es admin/asesor
    if (authProvider.user != null && 
        (authProvider.user!.rol == 'admin' || authProvider.user!.rol == 'asesor')) {
      // Admin y asesores SIEMPRE van directo al dashboard
      print('SplashScreen: Admin/Asesor detectado - Acceso directo al dashboard');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
      return;
    }
    
    // Para usuarios normales (CNB), verificar estado normal
    if (authProvider.isAuthenticated) {
      print('SplashScreen: Usuario normal autenticado - Redirigiendo a Home');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (authProvider.needsProfileCompletion) {
      print('SplashScreen: Usuario normal necesita completar perfil');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CompleteProfileScreen(
            codigoCorresponsal: authProvider.codigoCorresponsal,
          ),
        ),
      );
    } else {
      print('SplashScreen: Sin autenticación - Redirigiendo a Login');
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
              'Gestión de Comprobantes CNB',
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
            SizedBox(height: 16),
            Text(
              'Verificando credenciales...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}