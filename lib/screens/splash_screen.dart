// lib/screens/splash_screen.dart - SOLUCIÓN DEFINITIVA
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
    // Esperamos tiempo suficiente para que AuthProvider se inicialice
    await Future.delayed(Duration(seconds: 3));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('🔍 SplashScreen: Verificando estado de autenticación...');
    print('📊 Estado: ${authProvider.authStatus}');
    print('👤 Usuario: ${authProvider.user?.nombre ?? "null"}');
    print('🔑 Rol: ${authProvider.user?.rol ?? "null"}');
    print('✅ Perfil completo: ${authProvider.perfilCompleto}');
    
    // ✅ PRIORIDAD 1: Verificar si el usuario tiene un rol privilegiado
    if (authProvider.user != null) {
      final rol = authProvider.user!.rol;
      
      // 🚨 IMPORTANTE: Admin y Asesor NUNCA van a completar perfil
      if (rol == 'admin' || rol == 'asesor') {
        print('🔒 SplashScreen: Usuario privilegiado detectado ($rol) - Acceso directo al dashboard');
        _navigateToHome();
        return;
      }
    }
    
    // ✅ PRIORIDAD 2: Para usuarios normales, verificar estado de autenticación
    switch (authProvider.authStatus) {
      case AuthStatus.authenticated:
        print('✅ SplashScreen: Usuario autenticado - Redirigiendo a Home');
        _navigateToHome();
        break;
        
      case AuthStatus.needsProfileCompletion:
        print('📝 SplashScreen: Usuario necesita completar perfil');
        _navigateToCompleteProfile();
        break;
        
      case AuthStatus.unauthenticated:
      default:
        print('🚪 SplashScreen: Usuario no autenticado - Redirigiendo a Login');
        _navigateToLogin();
        break;
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void _navigateToCompleteProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CompleteProfileScreen(
          codigoCorresponsal: authProvider.codigoCorresponsal,
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance,
                size: 60,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 30),
            
            // Título
            Text(
              'RioCaja Smart',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            
            // Subtítulo
            Text(
              'Sistema de Gestión Bancaria',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 50),
            
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            
            // Texto de carga
            Text(
              'Iniciando aplicación...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}