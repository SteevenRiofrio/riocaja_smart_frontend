// lib/widgets/app_drawer.dart - MENÚ CORRECTO PARA CADA ROL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/scanner_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/screens/excel_reports_screen.dart';  
import 'package:riocaja_smart/screens/debug_screen.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/screens/messages_screen.dart';
import 'package:riocaja_smart/screens/pending_users_screen.dart';
import 'package:riocaja_smart/screens/user_management_screen.dart';
import 'package:riocaja_smart/utils/text_constants.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.rol ?? 'cnb';
    final isAdmin = userRole == 'admin';
    final isAsesor = userRole == 'asesor';
    final isCNB = userRole == 'cnb';
    
    return Drawer(
      child: Column(
        children: [
          // Encabezado del drawer
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green.shade700,
            ),
            accountName: Text(
              authProvider.user?.nombre ?? 'Usuario',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              authProvider.user?.email ?? 'usuario@riocaja.com',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (authProvider.user?.nombre?.isNotEmpty == true) 
                    ? authProvider.user!.nombre[0].toUpperCase() 
                    : 'U',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            otherAccountsPictures: [
              Container(
                decoration: BoxDecoration(
                  color: _getRoleColor(userRole),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getRoleIcon(userRole),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Elementos del menú
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. INICIO - Para todos
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Inicio'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),
                
                // 2. ESCANEAR COMPROBANTE - Para todos
                ListTile(
                  leading: Icon(Icons.document_scanner, color: Colors.green.shade700),
                  title: Text('Escanear Comprobante'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScannerScreen()),
                    );
                  },
                ),
                
                // 3. HISTORIAL DE COMPROBANTES - Para todos
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Historial de Comprobantes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                ),

                // Solo para ADMIN y ASESOR - Reportes adicionales
                if (isAdmin || isAsesor) ...[
                  // 4. REPORTES DE CIERRE - Solo Admin/Asesor
                  ListTile(
                    leading: Icon(Icons.assessment, color: Colors.blue.shade700),
                    title: Text('Reportes de Cierre'),
                    subtitle: Text('Ver y compartir reportes'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReportScreen()),
                      );
                    },
                  ),
                  
                  // 5. REPORTES EXCEL - Solo Admin/Asesor
                  ListTile(
                    leading: Icon(Icons.table_chart, color: Colors.green.shade700),
                    title: Text('Reportes Excel'),
                    subtitle: Text('Exportar datos detallados'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExcelReportsScreen()),
                      );
                    },
                  ),
                ],

                // 6. MENSAJES - Para Admin y Asesor
                if (isAdmin || isAsesor) ...[
                  ListTile(
                    leading: Icon(Icons.message, color: Colors.purple.shade700),
                    title: Text('Mensajes'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MessagesScreen()),
                      );
                    },
                  ),
                ],
                
                // Separador para administración
                if (isAdmin || isAsesor) ...[
                  Divider(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Administración',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  // 7. GESTIÓN DE USUARIOS - Solo Admin/Asesor
                  ListTile(
                    leading: Icon(Icons.people_alt, color: Colors.green.shade700),
                    title: Text('Gestión de Usuarios'),
                    subtitle: Text('Administrar todos los usuarios del sistema'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserManagementScreen()),
                      );
                    },
                  ),
                  
                  // 8. USUARIOS PENDIENTES - Solo Admin/Asesor  
                  ListTile(
                    leading: Icon(Icons.person_add, color: Colors.orange.shade700),
                    title: Text('Usuarios Pendientes'),
                    subtitle: Text('Solo usuarios pendientes de aprobación'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PendingUsersScreen()),
                      );
                    },
                  ),
                  
                  // 9. DIAGNÓSTICO - Solo Admin/Asesor
                  ListTile(
                    leading: Icon(Icons.bug_report, color: Colors.red.shade700),
                    title: Text('Diagnóstico'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DebugScreen()),
                      );
                    },
                  ),
                ],
                
                // CNB solo ve lo básico (ya está arriba)
              ],
            ),
          ),
          
          // Sección inferior con información de rol y logout
          Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                // Información de sesión
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rol: ${_getRoleName(userRole)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Local: ${authProvider.user?.nombreLocal ?? 'Administración'}',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Botón de logout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: Icon(Icons.logout),
                    label: Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación de logout
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirmar cierre de sesión'),
          content: Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                
                Navigator.of(dialogContext).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Cerrar drawer
                
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Cerrando sesión...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                
                try {
                  await authProvider.logout();
                  
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sesión cerrada correctamente'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  // Funciones auxiliares para colores e iconos
  Color _getRoleColor(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.red.shade700;
      case 'asesor':
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  String _getRoleIcon(String rol) {
    switch (rol) {
      case 'admin':
        return 'A';
      case 'asesor':
        return 'O';
      default:
        return 'C';
    }
  }

  String _getRoleName(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'asesor':
        return 'Asesor';
      default:
        return 'CNB';
    }
  }
}