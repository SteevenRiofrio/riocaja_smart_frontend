// lib/screens/home_screen.dart - VERSIÓN SIN SALUDOS NI BIENVENIDAS
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
          drawer: AppDrawer(),
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
                  // Resumen del dashboard (sin saludos)
                  DashboardSummary(),
                  SizedBox(height: 20),
                  
                  // Botones de acción solo para lectores
                  if (authProvider.hasRole('lector')) ...[
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
                      'Historial de Comprobantes',
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
                  ],
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