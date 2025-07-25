// lib/main.dart - COMPLETO Y ACTUALIZADO CON AuthWrapper
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/providers/message_provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riocaja_smart/models/user.dart';

// ================================
// MAIN FUNCTION
// ================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

// ================================
// MyApp - APLICACIÓN PRINCIPAL
// ================================
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ IMPORTANTE: lazy: false para AuthProvider
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ReceiptsProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'RíoCaja Smart',
        locale: Locale('es', 'ES'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green.shade700,
            elevation: 0,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green.shade700, width: 2),
            ),
          ),
        ),
        // ✅ CAMBIO PRINCIPAL: usar AuthWrapper en lugar de HomeScreen
        home: AuthWrapper(),
        navigatorObservers: [AuthErrorHandler()],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ================================
// AuthWrapper - MANEJADOR DE AUTENTICACIÓN
// ================================
// AuthWrapper SÚPER SIMPLE - SIN ERRORES
class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // ✅ SIMPLEMENTE ESPERAR UN POCO y marcar como inicializado
    await Future.delayed(Duration(milliseconds: 200));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ MOSTRAR splash brevemente
    if (!_isInitialized) {
      return SplashScreen();
    }

    // ✅ DEJAR que AuthProvider maneje todo normalmente
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

// ================================
// SplashScreen - PANTALLA DE CARGA
// ================================
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de la aplicación
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance,
                  size: 70,
                  color: Colors.green[700],
                ),
              ),
              
              SizedBox(height: 40),
              
              // Título principal
              Text(
                'RíoCaja Smart',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              
              SizedBox(height: 8),
              
              // Subtítulo
              Container(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Sistema de Automatización de Cierre de Caja para Corresponsales No Bancarios',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 60),
              
              // Indicador de carga
              Container(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              
              SizedBox(height: 24),
              
              // Texto de estado
              Text(
                'Verificando sesión...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(height: 40),
              
              // Información adicional
              Container(
                padding: EdgeInsets.symmetric(horizontal: 60),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.white60,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Conexión segura',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_done,
                          color: Colors.white60,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sincronización en la nube',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
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
  }
}

// ================================
// AuthErrorHandler - OBSERVADOR DE NAVEGACIÓN
// ================================
class AuthErrorHandler extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Ejecutar verificación de token cuando se navega a una nueva pantalla
    Future.microtask(() {
      try {
        if (navigator != null && navigator!.context != null) {
          final authProvider = Provider.of<AuthProvider>(
            navigator!.context, 
            listen: false
          );
          
          if (authProvider.isAuthenticated) {
            // Verificar y refrescar token si es necesario
            authProvider.checkAndRefreshToken();
          }
        }
      } catch (e) {
        print('❌ Error en AuthErrorHandler: $e');
      }
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    
    // También verificar al regresar de una pantalla
    Future.microtask(() {
      try {
        if (navigator != null && navigator!.context != null) {
          final authProvider = Provider.of<AuthProvider>(
            navigator!.context, 
            listen: false
          );
          
          if (authProvider.isAuthenticated) {
            authProvider.checkAndRefreshToken();
          }
        }
      } catch (e) {
        print('❌ Error en AuthErrorHandler (didPop): $e');
      }
    });
  }
}

