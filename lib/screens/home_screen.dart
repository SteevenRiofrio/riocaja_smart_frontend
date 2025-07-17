// lib/screens/home_screen.dart - ARCHIVO CORRECTO CON DRAWER
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/providers/message_provider.dart';
import 'package:riocaja_smart/widgets/app_drawer.dart';
import 'package:riocaja_smart/widgets/admin_stats_widget.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/screens/scanner_screen.dart';
import 'package:riocaja_smart/screens/history_screen.dart';
import 'package:riocaja_smart/screens/messages_screen.dart';
import 'package:riocaja_smart/screens/user_management_screen.dart';
import 'package:riocaja_smart/screens/report_screen.dart';
import 'package:riocaja_smart/screens/excel_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
      _loadInitialData();
    });
  }

  void _checkAuthentication() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _loadInitialData() {
    final receiptsProvider = Provider.of<ReceiptsProvider>(context, listen: false);
    receiptsProvider.setContext(context);
    receiptsProvider.loadReceipts();

    // Cargar datos de admin si es necesario
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      
      // ✅ CRÍTICO: Configurar AdminProvider igual que ReceiptsProvider
      adminProvider.setContext(context);
      adminProvider.setAuthToken(authProvider.user?.token);
      
      // Verificar que hay token antes de cargar
      final token = authProvider.user?.token;
      if (token != null && token.isNotEmpty) {
        print('🔄 Cargando usuarios para admin/asesor con token...');
        adminProvider.loadAllUsers().then((_) {
          print('✅ Usuarios cargados: ${adminProvider.allUsers.length}');
        }).catchError((error) {
          print('❌ Error cargando usuarios: $error');
        });
      } else {
        print('❌ No hay token disponible para cargar usuarios');
      }
    }

    // Cargar mensajes
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('RíoCaja Smart'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Recargando datos manualmente...');
              _loadInitialData();
              // Forzar rebuild del Consumer
              setState(() {});
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.rol ?? 'cnb';

    if (userRole == 'admin' || userRole == 'asesor') {
      return _buildAdminInterface();
    } else {
      return _buildCNBInterface();
    }
  }

  // Interfaz para usuarios CNB
  Widget _buildCNBInterface() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo personalizado
          _buildGreetingCard(),
          SizedBox(height: 20),
          
          // Mensajes nuevos (siempre visible)
          _buildMessagesCard(),
          SizedBox(height: 20),
          
          // Acciones rápidas
          _buildCNBQuickActions(),
        ],
      ),
    );
  }

  // Interfaz para administradores
  Widget _buildAdminInterface() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel de administración (6 cards en 2x3)
          _buildAdminPanel(),
          SizedBox(height: 20),
          
          // Alert de usuarios suspendidos (como en imagen 2)
          _buildAdminSuspendedAlert(),
          
          // Mensajes nuevos (para admin también)
          _buildMessagesCard(),
        ],
      ),
    );
  }

  // Alert específico para admin (como en imagen 2)
  Widget _buildAdminSuspendedAlert() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final suspendedUsers = adminProvider.allUsers
            .where((user) => user['estado'] == 'suspended')
            .toList();

        if (suspendedUsers.isEmpty) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserManagementScreen()),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${suspendedUsers.length} usuario suspendido',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Gestionar',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    String greeting = _getGreeting();
    String userName = authProvider.user?.nombre ?? 'Usuario';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.waving_hand,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getRoleMessage(authProvider),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text(
                  'Panel de Administración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserManagementScreen()),
                    );
                  },
                  child: Text('Ver Todos'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                // Debug: Mostrar información de carga
                print('🔍 AdminProvider estado: ${adminProvider.allUsers.length} usuarios');
                
                final allUsers = adminProvider.allUsers;
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                
                // Si no hay datos Y hay token, mostrar loading
                if (allUsers.isEmpty) {
                  final token = authProvider.user?.token;
                  
                  if (token == null || token.isEmpty) {
                    // No hay token - mostrar error de autenticación
                    return Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Error de autenticación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Token no disponible',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Cerrar sesión y volver al login
                                authProvider.logout();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => LoginScreen()),
                                );
                              },
                              child: Text('Reiniciar Sesión'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // Hay token pero no datos - mostrar loading (SIN recargar automáticamente)
                  return Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando datos de usuarios...'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Solo cargar manualmente al presionar el botón
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              
                              // ✅ Configurar AdminProvider antes de cargar
                              adminProvider.setContext(context);
                              adminProvider.setAuthToken(authProvider.user?.token);
                              
                              if (!adminProvider.isLoading) {
                                print('🔄 Recarga manual solicitada...');
                                adminProvider.loadAllUsers();
                              }
                            },
                            child: Text('Recargar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final totalUsers = allUsers.length;
                final activeUsers = allUsers.where((u) => u['estado'] == 'activo').length;
                final pendingUsers = allUsers.where((u) => u['estado'] == 'pendiente').length;
                final suspendedUsers = allUsers.where((u) => u['estado'] == 'suspended').length;
                final adminUsers = allUsers.where((u) => u['rol'] == 'admin').length;
                final cnbUsers = allUsers.where((u) => u['rol'] == 'cnb' || u['rol'] == null).length;

                print('📊 Estadísticas: Total=$totalUsers, Activos=$activeUsers, Pendientes=$pendingUsers, Suspendidos=$suspendedUsers');

                return Column(
                  children: [
                    // Primera fila: Total Usuarios y Activos
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdminStatCard(
                            'Total Usuarios', 
                            totalUsers, 
                            Colors.blue.shade700, 
                            Icons.people,
                            Colors.blue.shade50
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildAdminStatCard(
                            'Activos', 
                            activeUsers, 
                            Colors.green.shade700, 
                            Icons.check_circle,
                            Colors.green.shade50
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Segunda fila: Pendientes y Suspendidos
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdminStatCard(
                            'Pendientes', 
                            pendingUsers, 
                            Colors.orange.shade700, 
                            Icons.pending,
                            Colors.orange.shade50
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildAdminStatCard(
                            'Suspendidos', 
                            suspendedUsers, 
                            Colors.red.shade700, 
                            Icons.block,
                            Colors.red.shade50
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Tercera fila: Admins y CNBs
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdminStatCard(
                            'Admins', 
                            adminUsers, 
                            Colors.purple.shade700, 
                            Icons.admin_panel_settings,
                            Colors.purple.shade50
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildAdminStatCard(
                            'CNBs', 
                            cnbUsers, 
                            Colors.indigo.shade700, 
                            Icons.person,
                            Colors.indigo.shade50
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Nuevo método para las cards del admin (formato correcto)
  Widget _buildAdminStatCard(String label, int count, Color iconColor, IconData icon, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon, 
            color: iconColor, 
            size: 24
          ),
          SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspendedUsersAlert() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final suspendedUsers = adminProvider.allUsers
            .where((user) => user['estado'] == 'suspended')
            .toList();

        if (suspendedUsers.isEmpty) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Card(
            color: Colors.red.shade50,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserManagementScreen()),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${suspendedUsers.length} usuario${suspendedUsers.length > 1 ? 's' : ''} suspendido${suspendedUsers.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Toca para gestionar',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewMessagesAlert() {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.email ?? '';
        
        final unreadCount = messageProvider.messages
            .where((message) => !message.leidoPor.contains(currentUserId))
            .length;

        if (unreadCount == 0) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Card(
            color: Colors.blue.shade50,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MessagesScreen()),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.mail,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensajes nuevos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Tienes $unreadCount mensaje${unreadCount > 1 ? 's' : ''} sin leer',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Card de mensajes (siempre visible para CNB)
  Widget _buildMessagesCard() {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.email ?? '';
        
        final unreadCount = messageProvider.messages
            .where((message) => !message.leidoPor.contains(currentUserId))
            .length;

        return Container(
          child: Card(
            color: Colors.blue.shade50,
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MessagesScreen()),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.mail,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensajes nuevos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'BG Steeven Riofrio',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Estimados corresponsales muy buenas noches, me com...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '1 más...',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Text(
                                'Ver todos',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Accesos rápidos específicos para CNB (2x2)
  Widget _buildCNBQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos Rápidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildCNBActionCard(
              'ESCANEAR',
              'AHORA',
              Icons.document_scanner,
              Color(0xFF4CAF50), // Verde igual a la imagen
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScannerScreen()),
                );
              },
            ),
            _buildCNBActionCard(
              'VER',
              'HISTORIAL',
              Icons.history,
              Color(0xFF2196F3), // Azul igual a la imagen
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
            ),
            _buildCNBActionCard(
              'REPORTES',
              'DEL DÍA',
              Icons.bar_chart,
              Color(0xFF9C27B0), // Morado igual a la imagen
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportScreen()),
                );
              },
            ),
            _buildCNBActionCard(
              'EXCEL',
              'REPORTS',
              Icons.table_chart,
              Color(0xFF009688), // Verde agua igual a la imagen
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExcelReportsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // Card de acción específico para CNB - EXACTO A LA IMAGEN 1
  Widget _buildCNBActionCard(String title1, String title2, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
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
            // Símbolo difuminado de fondo (grande y transparente)
            Positioned(
              top: 10,
              right: 10,
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.2),
                size: 80,
              ),
            ),
            // Contenido principal
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono pequeño en esquina superior izquierda
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      Spacer(),
                    ],
                  ),
                  
                  Spacer(),
                  
                  // Texto en esquina inferior izquierda (2 líneas)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        title2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  String _getRoleMessage(AuthProvider authProvider) {
    if (authProvider.hasRole('admin')) {
      return 'Panel de administración del sistema';
    } else if (authProvider.hasRole('asesor')) {
      return 'Panel de asesoría y soporte';
    } else if (authProvider.hasRole('cnb')) {
      return 'Listo para procesar comprobantes';
    } else {
      return 'Bienvenido al sistema';
    }
  }
}