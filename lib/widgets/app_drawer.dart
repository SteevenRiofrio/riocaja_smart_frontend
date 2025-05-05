// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/screens/debug_screen.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

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
          ),
          
          // Elementos del menú
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Inicio'),
            onTap: () {
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
          
          Divider(),
          
          // Mostrar Debug solo para roles específicos
          if (authProvider.hasRole('admin') || authProvider.hasRole('operador'))
            ListTile(
              leading: Icon(Icons.bug_report),
              title: Text('Diagnóstico'),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DebugScreen()),
                );
              },
            ),
          
          // Opciones de autenticación
          ListTile(
            leading: Icon(
              authProvider.isAuthenticated ? Icons.logout : Icons.login,
            ),
            title: Text(
              authProvider.isAuthenticated ? 'Cerrar Sesión' : 'Iniciar Sesión',
            ),
            onTap: () async {
              if (authProvider.isAuthenticated) {
                // Mostrar diálogo de confirmación
                bool confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Cerrar Sesión'),
                    content: Text('¿Estás seguro de que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Cerrar Sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ) ?? false;
                
                if (confirm) {
                  await authProvider.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                }
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
          ),
          
          // Mostrar versión en la parte inferior
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'RíoCaja Smart v1.0.0',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}