// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/providers/message_provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

// Clase para interceptar errores de autenticación globalmente
class AuthErrorHandler extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Verificar el token cuando se navega a una nueva pantalla
    Future.microtask(() {
      if (navigator != null && navigator!.context != null) {
        final authProvider = Provider.of<AuthProvider>(navigator!.context, listen: false);
        if (authProvider.isAuthenticated) {
          authProvider.checkAndRefreshToken();
        }
      }
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Proveedor de autenticación (debe inicializarse primero)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: false, // Esto hace que se inicialice inmediatamente al inicio, no bajo demanda
        ),
        
        // Proveedor de comprobantes
        ChangeNotifierProvider(create: (_) => ReceiptsProvider()),
        
        // Nuevos providers para la gestión de usuarios y mensajes
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'RíoCaja Smart',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green.shade700,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
          ),
        ),
        home: SplashScreen(), // Iniciar con la pantalla de carga
        navigatorObservers: [AuthErrorHandler()], // Agregar observador para errores de autenticación
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}