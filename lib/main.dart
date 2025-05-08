// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

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
      debugShowCheckedModeBanner: false,
    ),
  );
}
}