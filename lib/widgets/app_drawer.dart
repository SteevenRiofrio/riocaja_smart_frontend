// lib/widgets/app_drawer.dart - ACTUALIZADO CON TEXT CONSTANTS
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
                  color: _getRoleColor(authProvider.user?.rol ?? 'cnb'),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getRoleIcon(authProvider.user?.rol ?? 'cnb'),
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
                  title: Text(TextConstants.inicio),
                  onTap: () {
                    Navigator.of(context).pop(); // Cerrar drawer
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),
                
                // Escanear Comprobante para todos los roles
                ListTile(
                  leading: Icon(Icons.document_scanner, color: Colors.green.shade700),
                  title: Text(TextConstants.escanearComprobante),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScannerScreen()),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text(TextConstants.historialComprobantes),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()),
                    );
                  },
                ),
                
                Divider(),
                
                // Sección de Reportes
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    TextConstants.reportes,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                ListTile(
                  leading: Icon(Icons.summarize, color: Colors.blue.shade700),
                  title: Text(TextConstants.reportesCierre),
                  subtitle: Text(TextConstants.verCompartir),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportScreen()),
                    );
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.table_chart, color: Colors.green.shade700),
                  title: Text(TextConstants.reportesExcel),
                  subtitle: Text(TextConstants.exportarDatos),
                  onTap: () {
                    Navigator.pop(context); // Cerrar drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExcelReportsScreen()),
                    );
                  },
                ),
                
                Divider(),
                
                // Mensajes para todos los usuarios
                ListTile(
                  leading: Icon(Icons.mail),
                  title: Text(TextConstants.mensajes),
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
                if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      TextConstants.administracion,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.people_alt, color: Colors.green.shade700),
                    title: Text(TextConstants.gestionUsuarios),
                    subtitle: Text(TextConstants.administrarTodosLosUsuarios),
                    onTap: () {
                      Navigator.pop(context); // Cerrar drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserManagementScreen()),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.person_add, color: Colors.orange.shade700),
                    title: Text(TextConstants.usuariosPendientes),
                    subtitle: Text(TextConstants.soloPendientesAprobacion),
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
                    title: Text(TextConstants.diagnostico),
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
                              'Rol: ${TextConstants.getRoleName(authProvider.user?.rol ?? 'cnb')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Local: ${authProvider.user?.nombreLocal ?? TextConstants.administracion}',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                
                // Botón de cerrar sesión
                ElevatedButton(
                  onPressed: () => _showLogoutDialog(context, authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(TextConstants.cerrarSesion),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de confirmación para cerrar sesión
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(TextConstants.confirmarCierreSesion),
          content: Text(TextConstants.estaSeguroCerrarSesion),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar diálogo
              },
              child: Text(TextConstants.cancelar),
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
                            Text(TextConstants.cerrandoSesion),
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
                      content: Text(TextConstants.sesionCerradaCorrectamente),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  // En caso de error, cerrar el indicador y mostrar error
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${TextConstants.errorCerrarSesion}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(TextConstants.cerrarSesion),
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
      case 'asesor':
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
      case 'asesor':
        return 'O';
      default:
        return 'L';
    }
  }
}