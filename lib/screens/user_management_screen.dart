// lib/screens/user_management_screen.dart - PANTALLA COMPLETA DE GESTIÓN DE USUARIOS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/services/admin_service.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _statusFilter = 'todos';
  String _roleFilter = 'todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.setContext(context);
    await adminProvider.loadPendingUsers();
    await adminProvider.loadAllUsers(); // Nueva función
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Usuarios'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Pendientes',
              icon: Icon(Icons.person_add),
            ),
            Tab(
              text: 'Todos los Usuarios',
              icon: Icon(Icons.people),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingUsersTab(),
          _buildAllUsersTab(),
        ],
      ),
    );
  }

  // Tab de usuarios pendientes (existente)
  Widget _buildPendingUsersTab() {
    return Consumer<AdminProvider>(
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
                Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
                SizedBox(height: 16),
                Text(
                  'No hay usuarios pendientes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Todos los usuarios han sido procesados',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadUserData,
          child: ListView.builder(
            itemCount: pendingUsers.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              return _buildPendingUserCard(context, user);
            },
          ),
        );
      },
    );
  }

  // Nuevo tab de todos los usuarios
  Widget _buildAllUsersTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final allUsers = adminProvider.allUsers;
        final filteredUsers = _filterUsers(allUsers);

        return Column(
          children: [
            // Filtros y búsqueda
            _buildFiltersSection(),
            
            // Lista de usuarios
            Expanded(
              child: filteredUsers.isEmpty
                  ? _buildEmptyUsersState()
                  : RefreshIndicator(
                      onRefresh: _loadUserData,
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(context, user);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Sección de filtros
  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          SizedBox(height: 12),
          
          // Filtros por estado y rol
          Row(
            children: [
              // Filtro por estado
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'todos', child: Text('Todos los estados')),
                        DropdownMenuItem(value: 'activo', child: Text('Activos')),
                        DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
                        DropdownMenuItem(value: 'suspendido', child: Text('Suspendidos')),
                        DropdownMenuItem(value: 'inactivo', child: Text('Inactivos')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              
              // Filtro por rol
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _roleFilter,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: 'todos', child: Text('Todos los roles')),
                        DropdownMenuItem(value: 'admin', child: Text('Administradores')),
                        DropdownMenuItem(value: 'asesor', child: Text('Asesor')),
                        DropdownMenuItem(value: 'cnb', child: Text('CNB')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _roleFilter = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Filtrar usuarios según criterios
  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    return users.where((user) {
      // Filtro por búsqueda
      final searchMatch = _searchQuery.isEmpty ||
          (user['nombre'] ?? '').toLowerCase().contains(_searchQuery) ||
          (user['email'] ?? '').toLowerCase().contains(_searchQuery);

      // Filtro por estado
      final statusMatch = _statusFilter == 'todos' ||
          (user['estado'] ?? '').toLowerCase() == _statusFilter.toLowerCase();

      // Filtro por rol
      final roleMatch = _roleFilter == 'todos' ||
          (user['rol'] ?? '').toLowerCase() == _roleFilter.toLowerCase();

      return searchMatch && statusMatch && roleMatch;
    }).toList();
  }

  // Card de usuario pendiente (existente, mejorado)
  Widget _buildPendingUserCard(BuildContext context, Map<String, dynamic> user) {
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
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade700,
                  child: Text(
                    (user['nombre'] as String?)?.isNotEmpty == true 
                        ? (user['nombre'] as String).substring(0, 1).toUpperCase() 
                        : 'U',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDIENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
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
                  'Rol solicitado: ${user['rol'] ?? 'lector'}',
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
                  icon: Icon(Icons.cancel, color: Colors.red, size: 18),
                  label: Text('Rechazar'),
                  onPressed: () => _confirmRejectUser(context, user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.check_circle, size: 18),
                  label: Text('Aprobar'),
                  onPressed: () => _showApproveUserDialog(context, user),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card de usuario (todos los usuarios)
  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final estado = user['estado'] ?? 'desconocido';
    final rol = user['rol'] ?? 'lector';
    final perfilCompleto = user['perfil_completo'] ?? false;
    
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    
    switch (estado.toLowerCase()) {
      case 'activo':
        statusColor = Colors.green.shade800;
        statusBgColor = Colors.green.shade100;
        statusIcon = Icons.check_circle;
        break;
      case 'pendiente':
        statusColor = Colors.orange.shade800;
        statusBgColor = Colors.orange.shade100;
        statusIcon = Icons.pending;
        break;
      case 'suspendido':
        statusColor = Colors.red.shade800;
        statusBgColor = Colors.red.shade100;
        statusIcon = Icons.block;
        break;
      case 'inactivo':
        statusColor = Colors.grey.shade800;
        statusBgColor = Colors.grey.shade100;
        statusIcon = Icons.remove_circle;
        break;
      default:
        statusColor = Colors.grey.shade800;
        statusBgColor = Colors.grey.shade100;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(rol),
                  child: Text(
                    (user['nombre'] as String?)?.isNotEmpty == true 
                        ? (user['nombre'] as String).substring(0, 1).toUpperCase() 
                        : 'U',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
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
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Información adicional
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip('Rol', _getRoleName(rol), _getRoleColor(rol)),
                ),
                SizedBox(width: 8),
                if (user['codigo_corresponsal'] != null)
                  Expanded(
                    child: _buildInfoChip('Código', user['codigo_corresponsal'], Colors.blue.shade700),
                  ),
              ],
            ),
            
            if (user['nombre_local'] != null) ...[
              SizedBox(height: 8),
              _buildInfoChip('Local', user['nombre_local'], Colors.purple.shade700),
            ],
            
            SizedBox(height: 12),
            
            // Acciones
            if (estado != 'pendiente')
              Row(
                children: [
                  // Botón de cambiar estado
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(_getStateActionIcon(estado), size: 16),
                      label: Text(_getStateActionText(estado)),
                      onPressed: () => _showChangeStateDialog(context, user),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getStateActionColor(estado),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  
                  // Botón de cambiar rol
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.admin_panel_settings, size: 16),
                      label: Text('Cambiar Rol'),
                      onPressed: () => _showChangeRoleDialog(context, user),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Widget para información en chips
  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Estado vacío para usuarios
  Widget _buildEmptyUsersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ajusta los filtros para ver más resultados',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Diálogos y métodos auxiliares existentes y nuevos...
  
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
                await adminProvider.loadAllUsers(); // Recargar todos los usuarios
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
    String selectedRole = user['rol'] ?? 'lector';
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
                        Text('Usuario:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${user['nombre']} (${user['email']})'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Campo para código de corresponsal
                  TextFormField(
                    controller: codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código de Corresponsal*',
                      hintText: 'Ej: CNB001, 0123, etc.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                      helperText: 'Código único para el usuario',
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Selector de rol
                  Text('Rol del usuario:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  final codigo = codigoController.text.trim();
                  
                  if (codigo.isEmpty || codigo.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Debe ingresar un código válido (mínimo 2 caracteres)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.of(context).pop();
                  
                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  final success = await adminProvider.approveUserWithCode(user['_id'], codigo);
                  
                  if (success && selectedRole != user['rol']) {
                    await adminProvider.changeUserRole(user['_id'], selectedRole);
                  }
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Usuario aprobado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await adminProvider.loadPendingUsers();
                    await adminProvider.loadAllUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al aprobar usuario'),
                        backgroundColor: Colors.red,
                      ),
                    );
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

  void _showChangeStateDialog(BuildContext context, Map<String, dynamic> user) {
  final currentState = user['estado'] ?? 'pendiente';
  String newState = currentState;
  
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Cambiar Estado del Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${user['nombre']}'),
              Text('Estado actual: ${currentState.toUpperCase()}'),
              SizedBox(height: 16),
              Text('Nuevo estado:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: newState,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                items: [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'suspendido', child: Text('Suspendido')),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                  DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      newState = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: newState == currentState ? null : () async {
                // Cerrar diálogo primero
                Navigator.of(dialogContext).pop();
                
                // Usar el context original, no el del diálogo
                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                final success = await adminProvider.changeUserState(user['_id'], newState);
                
                // Verificar que el widget aún esté montado antes de mostrar SnackBar
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Estado cambiado a ${newState.toUpperCase()}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await adminProvider.loadAllUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cambiar estado'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Cambiar Estado'),
            ),
          ],
        );
      },
    ),
  );
}

  void _showChangeRoleDialog(BuildContext context, Map<String, dynamic> user) {
    final currentRole = user['rol'] ?? 'lector';
    String newRole = currentRole;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Cambiar Rol del Usuario'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usuario: ${user['nombre']}'),
                Text('Rol actual: ${_getRoleName(currentRole)}'),
                SizedBox(height: 16),
                Text('Nuevo rol:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: newRole,
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
                        newRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: newRole == currentRole ? null : () async {
                  Navigator.of(context).pop();
                  
                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  final success = await adminProvider.changeUserRole(user['_id'], newRole);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rol cambiado a ${_getRoleName(newRole)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await adminProvider.loadAllUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cambiar rol'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Cambiar Rol'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Métodos auxiliares para obtener información de roles y estados
  Color _getRoleColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return Colors.red.shade700;
      case 'asesor':
        return Colors.orange.shade700;
      case 'cnb':
      default:
        return Colors.blue.shade700;
    }
  }

  String _getRoleName(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'asesor':
        return 'Asesor';
      case 'cnb':
      default:
        return 'CNB';
    }
  }

  IconData _getStateActionIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Icons.pause_circle;
      case 'suspendido':
        return Icons.play_circle;
      case 'inactivo':
        return Icons.play_circle;
      default:
        return Icons.settings;
    }
  }

  String _getStateActionText(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return 'Suspender';
      case 'suspendido':
        return 'Activar';
      case 'inactivo':
        return 'Activar';
      default:
        return 'Cambiar Estado';
    }
  }

  Color _getStateActionColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Colors.orange.shade700;
      case 'suspendido':
        return Colors.green.shade700;
      case 'inactivo':
        return Colors.green.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}
                      