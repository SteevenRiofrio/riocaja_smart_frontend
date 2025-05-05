// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:riocaja_smart/screens/scanner_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/widgets/dashboard_summary.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Verificar que el usuario está autenticado
    _checkAuthentication();
    
    // Cargar comprobantes al iniciar
    Future.microtask(() => 
      Provider.of<ReceiptsProvider>(context, listen: false).loadReceipts()
    );
  }
  
  // Método para verificar la autenticación
  void _checkAuthentication() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Si no está autenticado, redirigir a login
    if (!authProvider.isAuthenticated) {
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('RíoCaja Smart'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  Provider.of<ReceiptsProvider>(context, listen: false).loadReceipts();
                },
              ),
            ],
          ),
          drawer: AppDrawer(), // Agregar el drawer
          body: RefreshIndicator(
            onRefresh: () async {
              await Provider.of<ReceiptsProvider>(context, listen: false).loadReceipts();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Información del usuario actual
                  if (authProvider.user != null)
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade700,
                              child: Text(
                                authProvider.user!.nombre.isNotEmpty
                                    ? authProvider.user!.nombre[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hola, ${authProvider.user!.nombre}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Rol: ${authProvider.user!.rol}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  
                  // Banner o logo
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage('assets/images/banner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Bienvenido a RíoCaja Smart',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black54,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Resumen del dashboard
                  DashboardSummary(),
                  SizedBox(height: 20),
                  
                  // Botones de acción principales
                  Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'Escanear Comprobante',
                    Icons.document_scanner,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScannerScreen()),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'Historial de Escaneos',
                    Icons.history,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'Generar Reporte de Cierre',
                    Icons.summarize,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportScreen()),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Información del corresponsal
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Corresponsal No Bancario:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Banco del Barrio - Banco Guayaquil'),
                        SizedBox(height: 4),
                        Text('Última sincronización: Hoy, 5:30 PM'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
      BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}