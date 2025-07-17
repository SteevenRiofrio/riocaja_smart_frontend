// lib/widgets/dashboard_summary.dart - VERSIÓN CORREGIDA BASADA EN TU ESTRUCTURA REAL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/providers/message_provider.dart';
import 'package:riocaja_smart/widgets/admin_stats_widget.dart';
import 'package:riocaja_smart/screens/user_management_screen.dart';
import 'package:riocaja_smart/screens/messages_screen.dart';

class DashboardSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saludo personalizado
        _buildGreeting(authProvider),
        SizedBox(height: 16),
        
        // Panel administrativo (solo para admin/asesor)
        if (authProvider.hasRole('admin') || authProvider.hasRole('asesor'))
          AdminStatsWidget(),
        
        // Alert de usuarios suspendidos (solo para admin/asesor)
        if (authProvider.hasRole('admin') || authProvider.hasRole('asesor'))
          _buildSuspendedUsersAlert(context),
        
        // Mensajes nuevos (para todos)
        _buildNewMessagesAlert(context),
        
        // Resumen de comprobantes (solo para CNB)
        if (authProvider.hasRole('cnb'))
          _buildReceiptsSummary(context),
      ],
    );
  }

  Widget _buildGreeting(AuthProvider authProvider) {
    String greeting = _getGreeting();
    // ✅ CORREGIDO: usar 'nombre' en lugar de 'username'
    String userName = authProvider.user?.nombre ?? 'Usuario';
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildSuspendedUsersAlert(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // ✅ CORREGIDO: Acceder correctamente al estado del usuario como Map
        final suspendedUsers = adminProvider.allUsers
            .where((user) => user['estado'] == 'suspended')  // ✅ user es Map<String, dynamic>
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
                  MaterialPageRoute(
                    builder: (context) => UserManagementScreen(),
                  ),
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

  Widget _buildNewMessagesAlert(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        // ✅ CORREGIDO: Calcular unreadCount correctamente según tu estructura
        final unreadCount = messageProvider.messages
            .where((message) => !message.leidoPor.contains(messageProvider.getCurrentUserId()))
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
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(),
                  ),
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

  Widget _buildReceiptsSummary(BuildContext context) {
    return Consumer<ReceiptsProvider>(
      builder: (context, receiptsProvider, child) {
        final receipts = receiptsProvider.receipts;
        final todayReceipts = receipts.where((receipt) {
          final today = DateTime.now();
          // ✅ CORREGIDO: usar 'fecha' directamente según tu modelo Receipt
          final receiptDateStr = receipt.fecha; // receipt.fecha es String según tu modelo
          
          // Convertir fecha del receipt (formato dd/MM/yyyy) a DateTime para comparar
          try {
            final parts = receiptDateStr.split('/');
            if (parts.length == 3) {
              final receiptDate = DateTime(
                int.parse(parts[2]), // año
                int.parse(parts[1]), // mes
                int.parse(parts[0]), // día
              );
              return receiptDate.year == today.year &&
                     receiptDate.month == today.month &&
                     receiptDate.day == today.day;
            }
          } catch (e) {
            print('Error al parsear fecha del receipt: $e');
          }
          return false;
        }).toList();

        final todayTotal = todayReceipts.fold<double>(
          0,
          (sum, receipt) => sum + receipt.valorTotal,
        );

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Resumen de Hoy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // ✅ LAYOUT RESPONSIVE PARA RESUMEN
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 400) {
                      // Layout horizontal para pantallas más anchas
                      return Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'Comprobantes',
                              todayReceipts.length.toString(),
                              Icons.description,
                              Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryItem(
                              'Total del Día',
                              '\$${todayTotal.toStringAsFixed(2)}',
                              Icons.monetization_on,
                              Colors.green.shade700,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Layout vertical para pantallas más pequeñas
                      return Column(
                        children: [
                          _buildSummaryItem(
                            'Comprobantes',
                            todayReceipts.length.toString(),
                            Icons.description,
                            Colors.blue.shade700,
                          ),
                          SizedBox(height: 12),
                          _buildSummaryItem(
                            'Total del Día',
                            '\$${todayTotal.toStringAsFixed(2)}',
                            Icons.monetization_on,
                            Colors.green.shade700,
                          ),
                        ],
                      );
                    }
                  },
                ),

                if (todayReceipts.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Text(
                    'Últimas Transacciones',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Mostrar últimas 3 transacciones de forma compacta
                  ...todayReceipts.take(3).map((receipt) => _buildCompactReceiptItem(receipt)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

  Widget _buildCompactReceiptItem(dynamic receipt) {
    // ✅ CORREGIDO: usar 'tipo' según tu modelo Receipt
    IconData icon = _getIconForType(receipt.tipo);
    Color color = _getColorForType(receipt.tipo);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              receipt.tipo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${receipt.valorTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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

  IconData _getIconForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return Icons.money_off;
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return Icons.mobile_friendly;
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return Icons.savings;
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return Icons.send;
      case 'PAGO GIRO':
        return Icons.receipt;
      default:
        return Icons.payment;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return Colors.orange.shade700;
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return Colors.purple.shade700;
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return Colors.green.shade700;
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return Colors.indigo.shade700;
      case 'PAGO GIRO':
        return Colors.teal.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}