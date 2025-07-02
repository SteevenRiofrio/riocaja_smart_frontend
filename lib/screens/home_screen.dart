// lib/screens/home_screen.dart - VERSIÓN FINAL LIMPIA
import 'package:flutter/material.dart';
import 'package:riocaja_smart/screens/scanner_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/screens/excel_reports_screen.dart';
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
    Future.microtask(
      () => Provider.of<ReceiptsProvider>(context, listen: false).loadReceipts(),
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
      
      // ✅ CONFIGURAR TODOS LOS SERVICIOS CON EL TOKEN AL INICIO
      if (authProvider.isAuthenticated && authProvider.user?.token != null) {
        // Configurar ReceiptsProvider
        final receiptsProvider = Provider.of<ReceiptsProvider>(context, listen: false);
        receiptsProvider.setContext(context);
        
        // Configurar ApiService global (para reportes)
        authProvider.apiService.setContext(context);
        authProvider.apiService.setAuthToken(authProvider.user!.token);
        
        print('HomeScreen: Todos los servicios configurados con token');
      }
      
      return Scaffold(
          appBar: AppBar(
            title: Text('RíoCaja Smart', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  Provider.of<ReceiptsProvider>(
                    context,
                    listen: false,
                  ).loadReceipts();
                },
              ),
            ],
          ),
          drawer: AppDrawer(),
          body: RefreshIndicator(
            onRefresh: () async {
              await Provider.of<ReceiptsProvider>(
                context,
                listen: false,
              ).loadReceipts();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dashboard con estadísticas (AdminStatsWidget + alertas)
                  DashboardSummary(),
                  SizedBox(height: 20),

                  // SOLO CNB ve las tarjetas 2x2 de accesos rápidos
                  if (authProvider.hasRole('cnb') && 
                      !authProvider.hasRole('admin') && 
                      !authProvider.hasRole('asesor')) ...[
                    Text(
                      'Accesos Rápidos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Grid 2x2 SOLO para CNB
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        // Escanear Ahora
                        _buildModernActionCard(
                          context: context,
                          title: 'ESCANEAR',
                          subtitle: 'AHORA',
                          icon: Icons.document_scanner,
                          iconSecondary: Icons.flash_on,
                          color: Colors.green.shade600,
                          gradientColors: [Colors.green.shade400, Colors.green.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ScannerScreen()),
                          ),
                        ),
                        
                        // Ver Historial
                        _buildModernActionCard(
                          context: context,
                          title: 'VER',
                          subtitle: 'HISTORIAL',
                          icon: Icons.history,
                          iconSecondary: Icons.timeline,
                          color: Colors.blue.shade600,
                          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HistoryScreen()),
                          ),
                        ),
                        
                        // Reportes
                        _buildModernActionCard(
                          context: context,
                          title: 'REPORTES',
                          subtitle: 'DEL DÍA',
                          icon: Icons.assessment,
                          iconSecondary: Icons.trending_up,
                          color: Colors.purple.shade600,
                          gradientColors: [Colors.purple.shade400, Colors.purple.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReportScreen()),
                          ),
                        ),
                        
                        // Excel Reports
                        _buildModernActionCard(
                          context: context,
                          title: 'EXCEL',
                          subtitle: 'REPORTS',
                          icon: Icons.table_chart,
                          iconSecondary: Icons.file_download,
                          color: Colors.teal.shade600,
                          gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExcelReportsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ✅ ADMIN/ASESOR: SOLO ven el dashboard, todo lo demás por menú
                  if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) ...[
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Panel de Administración',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Usa el menú lateral para acceder a todas las funciones administrativas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para construir tarjetas modernas de acción (solo para CNB)
  Widget _buildModernActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required IconData iconSecondary,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Icono principal
            Positioned(
              top: 16,
              left: 16,
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 32,
              ),
            ),
            
            // Icono secundario (decorativo)
            Positioned(
              bottom: -10,
              right: -10,
              child: Icon(
                iconSecondary,
                color: Colors.white.withOpacity(0.1),
                size: 80,
              ),
            ),
            
            // Texto
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
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