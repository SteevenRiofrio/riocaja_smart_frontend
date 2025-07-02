// lib/widgets/dashboard_summary.dart - VERSIÓN SIN "NO HAY DATOS PARA MOSTRAR HOY"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/providers/message_provider.dart';
import 'package:riocaja_smart/screens/pending_users_screen.dart';
import 'package:riocaja_smart/screens/messages_screen.dart';
import 'package:riocaja_smart/widgets/admin_stats_widget.dart';
import 'package:riocaja_smart/widgets/excel_reports_widget.dart';
import 'package:intl/intl.dart';

class DashboardSummary extends StatefulWidget {
  @override
  _DashboardSummaryState createState() => _DashboardSummaryState();
}

class _DashboardSummaryState extends State<DashboardSummary> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
    
    // Inicializar providers adicionales si es administrador
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) {
      _loadAdminData();
    }
    
    // Cargar mensajes para todos los usuarios
    _loadMessages();
  }

  Future<void> _loadReportData() async {
    final receiptsProvider = Provider.of<ReceiptsProvider>(
      context,
      listen: false,
    );

    setState(() => _isLoading = true);

    try {
      // Obtener el reporte para la fecha actual
      final reportData = await receiptsProvider.generateClosingReport(
        DateTime.now(),
      );

      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report data: $e');
      setState(() {
        _reportData = {
          'summary': {},
          'total': 0.0,
          'date': DateTime.now().toString(),
          'count': 0,
        };
        _isLoading = false;
      });
    }
  }
  
  // Método para cargar datos de administrador
  Future<void> _loadAdminData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.setContext(context);
    
    // Establecer token desde el AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      adminProvider.setAuthToken(authProvider.user?.token);
    }
    
    await adminProvider.loadPendingUsers();
  }
  
  // Método para cargar mensajes
  Future<void> _loadMessages() async {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.setContext(context);
    
    // Establecer token desde el AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      messageProvider.setAuthToken(authProvider.user?.token);
    }
    
    await messageProvider.loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Verificar si es admin o asesor
    final isAdmin = authProvider.hasRole('admin');
    final isOperador = authProvider.hasRole('asesor');
    
    return Column(
      children: [
        // Widget de estadísticas para administradores
        if (isAdmin || isOperador)
          AdminStatsWidget(),
          
        // Sección de alertas para usuarios pendientes (solo para admin/asesor)
        if (isAdmin || isOperador)
          _buildPendingUsersAlert(),
          
        // Mensajes para todos los usuarios
        _buildMessagesAlert(),
        

        
        // Resumen del día - SOLO SI HAY DATOS
        if (_isLoading) 
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_reportData.isNotEmpty && (_reportData['count'] as int) > 0) 
          _buildSummaryCard(),
        // ELIMINADO: El else que mostraba "No hay datos para mostrar hoy"
      ],
    );
  }
  
  // Widget para mostrar el resumen del día
  Widget _buildSummaryCard() {
    final summary = _reportData['summary'] as Map<dynamic, dynamic>;
    final total = _reportData['total'] as double;
    final count = _reportData['count'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.indigo.shade700),
                SizedBox(width: 8),
                Text(
                  'Resumen del día',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Transacciones',
                  count.toString(),
                  Icons.receipt,
                  Colors.blue.shade100,
                ),
                _buildSummaryItem(
                  'Total',
                  '\$${total.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.green.shade100,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.pie_chart, size: 16, color: Colors.indigo.shade700),
                SizedBox(width: 4),
                Text(
                  'Distribución por tipo', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...summary.entries.map((entry) {
              IconData icon;
              Color iconColor;

              switch (entry.key) {
                case 'Retiro':
                  icon = Icons.money_off;
                  iconColor = Colors.orange;
                  break;
                case 'EFECTIVO MOVIL':
                  icon = Icons.mobile_friendly;
                  iconColor = Colors.purple;
                  break;
                case 'DEPOSITO':
                  icon = Icons.savings;
                  iconColor = Colors.green;
                  break;
                case 'RECARGA CLARO':
                  icon = Icons.phone_android;
                  iconColor = Colors.red;
                  break;
                default: // Pago de Servicio u otros
                  icon = Icons.payment;
                  iconColor = Colors.blue;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: iconColor),
                    SizedBox(width: 8),
                    Text(entry.key.toString()),
                    Spacer(),
                    Text('\$${(entry.value as num).toStringAsFixed(2)}'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  // Widget para mostrar alerta de usuarios pendientes (simplificado)
  Widget _buildPendingUsersAlert() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final pendingUsersCount = adminProvider.pendingUsers.length;
        
        if (pendingUsersCount == 0) {
          return SizedBox.shrink(); // No mostrar nada si no hay pendientes
        }
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          color: Colors.amber.shade100,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.amber.shade800),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Usuarios pendientes de aprobación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                    Text(
                      '$pendingUsersCount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Hay usuarios esperando su aprobación para acceder al sistema.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PendingUsersScreen(),
                        ),
                      );
                    },
                    child: Text('Ver pendientes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Widget para mostrar mensajes sin leer
  Widget _buildMessagesAlert() {
    return Consumer2<MessageProvider, AuthProvider>(
      builder: (context, messageProvider, authProvider, child) {
        // Filtrar mensajes no leídos por el usuario actual
        final unreadMessages = messageProvider.messages.where((message) {
          if (authProvider.user?.id == null) return false;
          return !message.isReadBy(authProvider.user!.id);
        }).toList();
        
        if (unreadMessages.isEmpty) {
          return SizedBox.shrink(); // No mostrar nada si no hay mensajes sin leer
        }
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          color: Colors.blue.shade100,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.mail, color: Colors.blue.shade800),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mensajes nuevos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    Text(
                      '${unreadMessages.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Mostrar el primer mensaje sin leer
                if (unreadMessages.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unreadMessages.first.titulo,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          unreadMessages.first.contenido.length > 50 
                              ? '${unreadMessages.first.contenido.substring(0, 50)}...' 
                              : unreadMessages.first.contenido,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (unreadMessages.length > 1)
                      Text(
                        '${unreadMessages.length - 1} más...',
                        style: TextStyle(fontSize: 12),
                      )
                    else
                      SizedBox.shrink(),
                    TextButton(
                      onPressed: () {
                        // Navegar a la pantalla de mensajes
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagesScreen(),
                          ),
                        );
                      },
                      child: Text('Ver todos'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}