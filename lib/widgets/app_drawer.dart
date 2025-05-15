// lib/widgets/app_drawer.dart - Actualización para incluir nuevas opciones de menú
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/home_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/screens/debug_screen.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/screens/messages_screen.dart'; // Nuevo
import 'package:riocaja_smart/screens/pending_users_screen.dart'; // Nuevo

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
          
          // Nuevo elemento: Mensajes
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
          if (authProvider.hasRole('admin') || authProvider.hasRole('operador'))
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Usuarios Pendientes'),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PendingUsersScreen()),
                );
              },
            ),
          
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
          
          // Opciones de autenticación (código existente)
          ListTile(
            leading: Icon(authProvider.isAuthenticated ? Icons.logout : Icons.login),
            title: Text(authProvider.isAuthenticated ? 'Cerrar Sesión' : 'Iniciar Sesión'),
            onTap: () async {
              // ... código existente ...
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