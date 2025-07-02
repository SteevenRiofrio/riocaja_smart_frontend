// lib/screens/pending_users_screen.dart - ACTUALIZADA CON CÓDIGO CORRESPONSAL
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/services/admin_service.dart';
import 'package:intl/intl.dart';

class PendingUsersScreen extends StatefulWidget {
  @override
  _PendingUsersScreenState createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }
  
  Future<void> _loadPendingUsers() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.setContext(context);
    await adminProvider.loadPendingUsers();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios Pendientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPendingUsers,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          final pendingUsers = adminProvider.pendingUsers;
          
          if (pendingUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'No hay usuarios pendientes de aprobación',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _loadPendingUsers,
            child: ListView.builder(
              itemCount: pendingUsers.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final user = pendingUsers[index];
                return _buildUserCard(context, user);
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    // Formatear fecha de registro
    String fechaRegistro = 'Desconocida';
    if (user['fecha_registro'] != null) {
      try {
        final fecha = DateTime.parse(user['fecha_registro']);
        fechaRegistro = DateFormat('dd/MM/yyyy HH:mm').format(fecha);
      } catch (e) {
        fechaRegistro = user['fecha_registro'] ?? 'Desconocida';
      }
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade700,
                  child: Text(
                    (user['nombre'] as String?)?.isNotEmpty == true 
                        ? (user['nombre'] as String).substring(0, 1).toUpperCase() 
                        : 'U',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user['email'] ?? 'Sin email',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Registrado: $fechaRegistro',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Rol solicitado: ${user['rol'] ?? 'cnb'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  label: Text('Rechazar'),
                  onPressed: () => _confirmRejectUser(context, user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.check_circle),
                  label: Text('Aprobar'),
                  onPressed: () => _showApproveUserDialog(context, user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmRejectUser(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechazar Usuario'),
        content: Text(
          '¿Está seguro de que desea rechazar la solicitud de ${user['nombre']}?\n\n'
          'Esta acción no se puede deshacer.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final adminProvider = Provider.of<AdminProvider>(context, listen: false);
              final success = await adminProvider.rejectUser(user['_id']);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Usuario rechazado correctamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al rechazar usuario'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Rechazar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
 void _showApproveUserDialog(BuildContext context, Map<String, dynamic> user) {
  String selectedRole = user['rol'] ?? 'cnb';
  final codigoController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Aprobar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del usuario
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Información del Usuario:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Nombre: ${user['nombre']}'),
                      Text('Email: ${user['email']}'),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Campo para código de corresponsal - CORREGIDO
                Text('Código de Corresponsal:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextFormField(
                  controller: codigoController,
                  decoration: InputDecoration(
                    hintText: 'Ej: 001, 0123, CNB001, etc.',
                    labelText: 'Código único del corresponsal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                    helperText: 'Puede empezar con 0. Se preservará el formato exacto.',
                    helperStyle: TextStyle(color: Colors.blue.shade600),
                  ),
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: 16),
                
                // Selector de rol
                Text('Seleccione el rol:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    DropdownMenuItem(value: 'cnb', child: Text('CNB')),
                    DropdownMenuItem(value: 'asesor', child: Text('Asesor')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // VALIDACIÓN CORREGIDA
                final codigoOriginal = codigoController.text.trim();
                
                if (codigoOriginal.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Debe ingresar un código de corresponsal'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (codigoOriginal.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El código debe tener al menos 2 caracteres'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // CORRECCIÓN: Cerrar el diálogo primero y guardar el contexto
                Navigator.of(context).pop();
                
                // Usar el contexto principal de la pantalla, no del diálogo
                final mainContext = this.context; // Contexto del widget principal
                
                // Variable para controlar el diálogo de carga
                bool isLoadingDialogOpen = false;
                
                try {
                  // Mostrar indicador de carga
                  showDialog(
                    context: mainContext,
                    barrierDismissible: false,
                    builder: (loadingContext) {
                      isLoadingDialogOpen = true;
                      return WillPopScope(
                        onWillPop: () async => false, // Prevenir cierre accidental
                        child: Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Aprobando usuario...'),
                                  SizedBox(height: 8),
                                  Text(
                                    'Código: $codigoOriginal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
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
                  
                  // Realizar la aprobación
                  final adminService = AdminService();
                  adminService.setContext(mainContext);
                  
                  final success = await adminService.approveUserWithCode(
                    user['_id'],
                    codigoOriginal,
                  );
                  
                  // Cerrar indicador de carga si sigue abierto
                  if (isLoadingDialogOpen && Navigator.canPop(mainContext)) {
                    Navigator.of(mainContext).pop();
                    isLoadingDialogOpen = false;
                  }
                  
                  if (success) {
                    // Cambiar rol si es diferente al original
                    if (selectedRole != user['rol']) {
                      await adminService.changeUserRole(user['_id'], selectedRole);
                    }
                    
                    // Recargar lista
                    final adminProvider = Provider.of<AdminProvider>(mainContext, listen: false);
                    await adminProvider.loadPendingUsers();
                    
                    // Mostrar mensaje de éxito
                    if (mounted) {  // Verificar que el widget sigue montado
                      ScaffoldMessenger.of(mainContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Usuario aprobado correctamente.\n'
                            'Código asignado: $codigoOriginal',
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  } else {
                    // Mostrar error
                    if (mounted) {
                      ScaffoldMessenger.of(mainContext).showSnackBar(
                        SnackBar(
                          content: Text('Error al aprobar usuario. Verifique que el código no esté en uso.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Cerrar indicador de carga si sigue abierto
                  if (isLoadingDialogOpen && Navigator.canPop(mainContext)) {
                    try {
                      Navigator.of(mainContext).pop();
                    } catch (navError) {
                      print('Error cerrando diálogo de carga: $navError');
                    }
                    isLoadingDialogOpen = false;
                  }
                  
                  // Mostrar error
                  if (mounted) {
                    ScaffoldMessenger.of(mainContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  
                  print('Error completo al aprobar usuario: $e');
                }
              },
              child: Text('Aprobar'),
            ),
          ],
        );
      },
    ),
  );
}
}