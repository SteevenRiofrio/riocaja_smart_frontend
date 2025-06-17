// lib/widgets/admin_stats_widget.dart
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
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.hasRole('admin') || authProvider.hasRole('operador')) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.setContext(context);
      
      if (authProvider.isAuthenticated) {
        adminProvider.setAuthToken(authProvider.user?.token);
      }
      
      await adminProvider.loadAllUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Solo mostrar para admin y operador
    if (!authProvider.hasRole('admin') && !authProvider.hasRole('operador')) {
      return SizedBox.shrink();
    }

    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return Card(
            child: Container(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = adminProvider.getUserStats();
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings, 
                         color: Colors.blue.shade700, 
                         size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Panel de Administración',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Spacer(),
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
                
                // Estadísticas generales
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Usuarios',
                        stats['total'].toString(),
                        Icons.people,
                        Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Activos',
                        stats['activos'].toString(),
                        Icons.check_circle,
                        Colors.green.shade700,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Pendientes',
                        stats['pendientes'].toString(),
                        Icons.pending,
                        Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Segunda fila de estadísticas
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Suspendidos',
                        stats['suspendidos'].toString(),
                        Icons.block,
                        Colors.red.shade700,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Admins',
                        stats['admins'].toString(),
                        Icons.admin_panel_settings,
                        Colors.purple.shade700,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Lectores',
                        stats['lectores'].toString(),
                        Icons.person,
                        Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                
                // Alertas si hay problemas
                if (stats['pendientes'] > 0) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade800),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${stats['pendientes']} usuario${stats['pendientes'] > 1 ? 's' : ''} esperando aprobación',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
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
                          child: Text('Revisar'),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (stats['suspendidos'] > 0) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red.shade800),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${stats['suspendidos']} usuario${stats['suspendidos'] > 1 ? 's' : ''} suspendido${stats['suspendidos'] > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
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
                          child: Text('Gestionar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
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