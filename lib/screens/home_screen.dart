// lib/screens/home_screen.dart - VERSIÓN CON INTERFAZ MODERNA GRID 2x2
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
import 'package:riocaja_smart/screens/excel_reports_screen.dart';

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
      () =>
          Provider.of<ReceiptsProvider>(context, listen: false).loadReceipts(),
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
                  // Resumen del dashboard (sin saludos)
                  DashboardSummary(),
                  SizedBox(height: 20),

                  // Interfaz moderna para usuarios cnb - Grid 2x2
                  if (authProvider.hasRole('cnb')) ...[
                    Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Grid 2x2 con tarjetas modernas
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
                        
                        // Historial Completo
                        _buildModernActionCard(
                          context: context,
                          title: 'HISTORIAL',
                          subtitle: 'COMPLETO',
                          icon: Icons.history,
                          iconSecondary: Icons.list_alt,
                          color: Colors.blue.shade600,
                          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HistoryScreen()),
                          ),
                        ),
                        
                        // Reportes PDF
                        _buildModernActionCard(
                          context: context,
                          title: 'REPORTE',
                          subtitle: 'PDF',
                          icon: Icons.picture_as_pdf,
                          iconSecondary: Icons.file_present,
                          color: Colors.red.shade600,
                          gradientColors: [Colors.red.shade400, Colors.red.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ReportScreen()),
                          ),
                        ),
                        
                        // Reportes Excel
                        _buildModernActionCard(
                          context: context,
                          title: 'REPORTES',
                          subtitle: 'EXCEL',
                          icon: Icons.table_chart,
                          iconSecondary: Icons.analytics,
                          color: Colors.orange.shade600,
                          gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExcelReportsScreen()),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para crear tarjetas modernas de acción
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Iconos apilados con efecto
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Icono de fondo con opacidad
                        Icon(
                          iconSecondary,
                          size: 45,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        // Icono principal
                        Icon(
                          icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Título principal
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Subtítulo
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Indicador de acción
                    Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método legacy mantenido para compatibilidad (puede eliminarse)
  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }
}