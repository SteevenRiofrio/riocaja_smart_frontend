// lib/main.dart - ACTUALIZADO CON SOPORTE ESPAÑOL
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:riocaja_smart/services/privacy_simple_service.dart';
import 'package:riocaja_smart/screens/privacy_terms_screen.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/providers/message_provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';

// Si usas algún observer personalizado, puedes dejarlo aquí
class AuthErrorHandler extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
          ),
        ),
        home: PrivacyChecker(), // ← CAMBIO PRINCIPAL AQUÍ
        navigatorObservers: [AuthErrorHandler()],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class PrivacyChecker extends StatefulWidget {
  @override
  State<PrivacyChecker> createState() => _PrivacyCheckerState();
}

class _PrivacyCheckerState extends State<PrivacyChecker> {
  bool _isLoading = true;
  bool _hasAcceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyStatus();
  }

  Future<void> _checkPrivacyStatus() async {
    try {
      final hasAccepted = await PrivacySimpleService.hasAcceptedTerms();
      setState(() {
        _hasAcceptedTerms = hasAccepted;
        _isLoading = false;
      });
      print(hasAccepted
          ? '✅ Usuario ya aceptó términos'
          : '⚠️ Usuario debe aceptar términos');
    } catch (e) {
      print('❌ Error verificando términos: $e');
      setState(() {
        _hasAcceptedTerms = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              ),
              SizedBox(height: 16),
              Text(
                'Verificando configuración de privacidad...',
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

    if (!_hasAcceptedTerms) {
      return PrivacyTermsScreen(
        onAccepted: () {
          setState(() {
            _hasAcceptedTerms = true;
          });
        },
      );
    }

    // Si ya aceptó, mostrar la app normal
    return HomeScreen();
  }
}