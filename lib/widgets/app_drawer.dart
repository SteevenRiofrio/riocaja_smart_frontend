// lib/widgets/app_drawer.dart - ACTUALIZADO CON NUEVA PANTALLA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/screens/debug_screen.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/screens/messages_screen.dart';
import 'package:riocaja_smart/screens/pending_users_screen.dart';
import 'package:riocaja_smart/screens/user_management_screen.dart';  // NUEVA IMPORTACIÓN

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
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
              // Indicador de rol
              Container(
                decoration: BoxDecoration(
                  color: _getRoleColor(authProvider.user?.rol ?? 'lector'),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getRoleIcon(authProvider.user?.rol ?? 'lector'),
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
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Inicio'),
                  onTap: () {
                    Navigator.of(context).pop(); // Cerrar drawer
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Historial de Comprobantes'),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.summarize),
                  title: Text('Reportes de Cierre'),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportScreen()),
                    );
                  },
                ),
                
                // Mensajes para todos los usuarios
                ListTile(
                  leading: Icon(Icons.mail),
                  title: Text('Mensajes'),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MessagesScreen()),
                    );
                  },
                ),
                
                Divider(),
                
                // Opciones de administrador
                if (authProvider.hasRole('admin') || authProvider.hasRole('operador')) ...[
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
                  
                  // NUEVA OPCIÓN: Gestión Completa de Usuarios
                  ListTile(
                    leading: Icon(Icons.people_alt, color: Colors.green.shade700),
                    title: Text('Gestión de Usuarios'),
                    subtitle: Text('Administrar todos los usuarios'),
                    onTap: () {
                      Navigator.pop(context); // Cerrar drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserManagementScreen()),
                      );
                    },
                  ),
                  
                  // Mantener la opción original para compatibilidad
                  ListTile(
                    leading: Icon(Icons.person_add, color: Colors.orange.shade700),
                    title: Text('Usuarios Pendientes'),
                    subtitle: Text('Solo pendientes de aprobación'),
                    onTap: () {
                      Navigator.pop(context); // Cerrar drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PendingUsersScreen()),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.bug_report, color: Colors.red.shade700),
                    title: Text('Diagnóstico'),
                    onTap: () {
                      Navigator.pop(context); // Cerrar drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DebugScreen()),
                      );
                    },
                  ),
                  Divider(),
                ],
              ],
            ),
          ),
          
          // Sección inferior con logout
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
                              'Rol: ${_getRoleName(authProvider.user?.rol ?? 'lector')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (authProvider.user?.nombreLocal != null)
                              Text(
                                'Local: ${authProvider.user!.nombreLocal}',
                                style: TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                
                // Botón de cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: Icon(Icons.logout, size: 18),
                    label: Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                
                // Versión
                Text(
                  'RíoCaja Smart v1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para mostrar diálogo de confirmación de logout
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Está seguro de que desea cerrar la sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar diálogo
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                  // Realizar logout
                  await authProvider.logout();
                  
                  // Cerrar indicador de carga y navegar a login
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false, // Eliminar todas las rutas anteriores
                  );
                  
                  // Mostrar mensaje de confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sesión cerrada correctamente'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  // En caso de error, cerrar el indicador y mostrar error
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

  // Obtener color según el rol
  Color _getRoleColor(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.red.shade700;
      case 'operador':
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  // Obtener icono según el rol
  String _getRoleIcon(String rol) {
    switch (rol) {
      case 'admin':
        return 'A';
      case 'operador':
        return 'O';
      default:
        return 'L';
    }
  }

  // Obtener nombre del rol
  String _getRoleName(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'operador':
        return 'Operador';
      default:
        return 'Lector';
    }
  }
}