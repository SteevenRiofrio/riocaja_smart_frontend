// lib/screens/home_screen.dart - VERSIÓN COMPLETA Y CORREGIDA
import 'package:flutter/material.dart';
import 'package:riocaja_smart/screens/scanner_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/screens/excel_reports_screen.dart';
import 'package:riocaja_smart/screens/user_management_screen.dart';
import 'package:riocaja_smart/screens/pending_users_screen.dart';
import 'package:riocaja_smart/screens/messages_screen.dart';
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
                  // Resumen del dashboard
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

                  // ADMIN y ASESOR ven Panel de Administración + Mensajes
                  if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) ...[
                    Text(
                      'Panel de Administración',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Panel de administración para Admin/Asesor
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        // Gestión de Usuarios
                        _buildModernActionCard(
                          context: context,
                          title: 'GESTIÓN',
                          subtitle: 'USUARIOS',
                          icon: Icons.people,
                          iconSecondary: Icons.admin_panel_settings,
                          color: Colors.indigo.shade600,
                          gradientColors: [Colors.indigo.shade400, Colors.indigo.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UserManagementScreen()),
                          ),
                        ),
                        
                        // Usuarios Pendientes
                        _buildModernActionCard(
                          context: context,
                          title: 'USUARIOS',
                          subtitle: 'PENDIENTES',
                          icon: Icons.person_add,
                          iconSecondary: Icons.pending_actions,
                          color: Colors.orange.shade600,
                          gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PendingUsersScreen()),
                          ),
                        ),
                        
                        // Mensajes del Sistema
                        _buildModernActionCard(
                          context: context,
                          title: 'MENSAJES',
                          subtitle: 'SISTEMA',
                          icon: Icons.message,
                          iconSecondary: Icons.notification_important,
                          color: Colors.red.shade600,
                          gradientColors: [Colors.red.shade400, Colors.red.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MessagesScreen()),
                          ),
                        ),
                        
                        // Reportes Avanzados
                        _buildModernActionCard(
                          context: context,
                          title: 'REPORTES',
                          subtitle: 'AVANZADOS',
                          icon: Icons.analytics,
                          iconSecondary: Icons.insights,
                          color: Colors.purple.shade600,
                          gradientColors: [Colors.purple.shade400, Colors.purple.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExcelReportsScreen()),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Sección de Mensajes para Admin/Asesor
                    Text(
                      'Mensajes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Widget de mensajes
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MessagesScreen()),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.message, color: Colors.blue.shade700, size: 32),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sistema de Mensajes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Comunícate con usuarios y administra notificaciones del sistema.',
                                    style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700),
                          ],
                        ),
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

  // Método para construir tarjetas modernas de acción
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