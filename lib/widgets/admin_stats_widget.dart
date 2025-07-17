// lib/widgets/admin_stats_widget.dart - VERSIÓN RESPONSIVE CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/user_management_screen.dart';

class AdminStatsWidget extends StatefulWidget {
  @override
  _AdminStatsWidgetState createState() => _AdminStatsWidgetState();
}

class _AdminStatsWidgetState extends State<AdminStatsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.hasRole('admin') && !authProvider.hasRole('asesor')) {
        return;
      }
      
      if (!authProvider.isAuthenticated || authProvider.user?.token == null) {
        print('AdminStatsWidget: No hay token disponible');
        return;
      }
      
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      
      // Configurar contexto y token
      adminProvider.setContext(context);
      adminProvider.setAuthToken(authProvider.user!.token);
      
      print('AdminStatsWidget: Token configurado: ${authProvider.user!.token.substring(0, 10)}...');
      
      // ✅ CORRECCIÓN: Usar Future.delayed para evitar setState durante build
      await Future.delayed(Duration.zero);
      await adminProvider.loadAllUsers();
      
    } catch (e) {
      print('Error en _loadStats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Solo mostrar a admins y asesores
    if (!authProvider.hasRole('admin') && !authProvider.hasRole('asesor')) {
      return SizedBox.shrink();
    }

    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final stats = adminProvider.getUserStats();
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y botón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Panel de Administración',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserManagementScreen(),
                          ),
                        );
                      },
                      child: Text('Ver Todo'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // ✅ SOLUCIÓN RESPONSIVE: Usar LayoutBuilder para adaptar según tamaño
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calcular número de columnas basado en ancho disponible
                    int crossAxisCount = 2;
                    double cardMinWidth = 150.0;
                    
                    if (constraints.maxWidth > 600) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth < 400) {
                      crossAxisCount = 1;
                    }
                    
                    // Calcular aspectRatio dinámicamente para evitar overflow
                    double availableWidth = constraints.maxWidth;
                    double cardSpacing = 12.0;
                    double totalSpacing = cardSpacing * (crossAxisCount - 1);
                    double cardWidth = (availableWidth - totalSpacing) / crossAxisCount;
                    double cardHeight = 80.0; // Altura fija reducida
                    double aspectRatio = cardWidth / cardHeight;
                    
                    // Asegurar que el aspectRatio no sea menor a 1.5
                    aspectRatio = aspectRatio < 1.5 ? 1.5 : aspectRatio;
                    
                    return GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,  // ← 2 columnas
                      crossAxisSpacing: 8,  // ← CAMBIO: Reducido de 12 a 8
                      mainAxisSpacing: 8,   // ← CAMBIO: Reducido de 12 a 8
                      childAspectRatio: 2.2,  // ← CAMBIO: Aumentado de 1.8 a 2.2 para que sea más ancho
                      children: [
                        // Fila 1
                        _buildStatCard(
                          'Total Usuarios',
                          stats['total'].toString(),
                          Icons.people,
                          Colors.blue.shade700,
                        ),
                        _buildStatCard(
                          'Activos',
                          stats['activos'].toString(),
                          Icons.check_circle,
                          Colors.green.shade700,
                        ),
                        
                        // Fila 2
                        _buildStatCard(
                          'Pendientes',
                          stats['pendientes'].toString(),
                          Icons.pending,
                          Colors.orange.shade700,
                        ),
                        _buildStatCard(
                          'Suspendidos',
                          stats['suspendidos'].toString(),
                          Icons.block,
                          Colors.red.shade700,
                        ),
                        
                        // Fila 3
                        _buildStatCard(
                          'Admins',
                          stats['admins'].toString(),
                          Icons.admin_panel_settings,
                          Colors.purple.shade700,
                        ),
                        _buildStatCard(
                          'CNBS',
                          stats['cnbs'].toString(),
                          Icons.store,
                          Colors.indigo.shade700,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ WIDGET CARD OPTIMIZADO PARA RESPONSIVE
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),  // ← CAMBIO: Reducido de 12 a 8
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,  // ← AÑADIDO: Evita que se expanda demasiado
        children: [
          Icon(icon, color: color, size: 16),  // ← CAMBIO: Reducido de 20 a 16
          SizedBox(height: 2),  // ← CAMBIO: Reducido de 4 a 2
          Text(
            value,
            style: TextStyle(
              fontSize: 14,  // ← CAMBIO: Reducido de 18 a 14
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 1),  // ← CAMBIO: Reducido de 2 a 1
          Text(
            title,
            style: TextStyle(
              fontSize: 9,  // ← CAMBIO: Reducido de 10 a 9
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ✅ WIDGET PARA ALERTAS DE USUARIOS PENDIENTES RESPONSIVE
class PendingUsersAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final pendingUsersCount = adminProvider.pendingUsers.length;
        
        if (pendingUsersCount == 0) {
          return SizedBox.shrink();
        }
        
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.amber.shade800,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pendingUsersCount usuario${pendingUsersCount > 1 ? 's' : ''} suspendido${pendingUsersCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Toca para gestionar',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserManagementScreen(),
                    ),
                  );
                },
                child: Text(
                  'Gestionar',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}