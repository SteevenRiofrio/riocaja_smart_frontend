// lib/screens/main_screen.dart - CORRECCIÓN

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/terms_modal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _hasCheckedTerms = false;
  bool _isCheckingTerms = true;

  @override
  void initState() {
    super.initState();
    _checkTermsOnStartup();
  }

  /// ✅ VERIFICAR TÉRMINOS AL INICIAR LA PANTALLA PRINCIPAL
  Future<void> _checkTermsOnStartup() async {
    if (_hasCheckedTerms) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // ✅ CORREGIDO: Usar authProvider.user en lugar de currentUser
    if (authProvider.user == null) {
      // Redirigir al login si no está autenticado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    try {
      // ✅ VERIFICAR SI NECESITA ACEPTAR TÉRMINOS
      final needsAcceptance = await authProvider.checkTermsAcceptance(
        authProvider.user!.id  // ✅ CORREGIDO: usar .user en lugar de .currentUser
      );

      setState(() {
        _isCheckingTerms = false;
        _hasCheckedTerms = true;
      });

      // ✅ MOSTRAR MODAL SI NECESITA ACEPTAR TÉRMINOS
      if (needsAcceptance && mounted) {
        _showTermsModal();
      }

    } catch (e) {
      print('❌ Error verificando términos en MainScreen: $e');
      setState(() {
        _isCheckingTerms = false;
        _hasCheckedTerms = true;
      });
    }
  }

  /// ✅ MOSTRAR MODAL DE TÉRMINOS (NO SE PUEDE CERRAR)
  void _showTermsModal() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false, // ⚠️ NO SE PUEDE CERRAR SIN ACEPTAR
      builder: (context) => TermsAcceptanceModal(
        userId: authProvider.user!.id,  // ✅ CORREGIDO: usar .user
        onAccepted: () {
          // ✅ TÉRMINOS ACEPTADOS - CONTINUAR NORMAL
          print('✅ Términos aceptados - usuario puede continuar');
          // El modal ya se cerró automáticamente
        },
        onRejected: () {
          // ❌ TÉRMINOS RECHAZADOS - REDIRIGIR AL LOGIN
          print('❌ Términos rechazados - redirigiendo al login');
          Navigator.of(context).pushReplacementNamed('/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // ✅ MOSTRAR LOADING MIENTRAS SE VERIFICAN TÉRMINOS
    if (_isCheckingTerms) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'Verificando términos y condiciones...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ BLOQUEAR ACCESO SI NECESITA ACEPTAR TÉRMINOS
    if (authProvider.needsTermsAcceptance) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'Debe aceptar los términos\ny condiciones para continuar',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showTermsModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Revisar Términos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ PANTALLA PRINCIPAL NORMAL - TÉRMINOS YA ACEPTADOS
    return Scaffold(
      appBar: AppBar(
        title: const Text('RioCaja Smart'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              // Logout
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido, ${authProvider.user?.nombre ?? 'Usuario'}!',  // ✅ CORREGIDO
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Has aceptado los términos y condiciones.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),
            
            // ✅ BOTONES DE FUNCIONALIDADES PRINCIPALES
            ElevatedButton(
              onPressed: () {
                // Navegar a scanner OCR
                Navigator.of(context).pushNamed('/scanner');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text(
                'Escanear Comprobante',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navegar a historial
                Navigator.of(context).pushNamed('/history');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text(
                'Ver Historial',
                style: TextStyle(color: Colors.white),
              ),
            ),
            
            // ✅ BOTÓN ADICIONAL PARA VER ESTADO DE TÉRMINOS (DEBUG)
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Estado de Términos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Necesita aceptar: ${authProvider.needsTermsAcceptance ? "SÍ" : "NO"}',
                    style: TextStyle(
                      color: authProvider.needsTermsAcceptance 
                        ? Colors.red 
                        : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}