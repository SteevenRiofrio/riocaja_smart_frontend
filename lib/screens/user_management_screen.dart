// lib/screens/user_management_screen.dart - PARTE 1 (Líneas 1-500)
// CON CONFIGURACIÓN DEL TOKEN Y FUNCIONALIDADES COMPLETAS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/admin_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/services/admin_service.dart';
import 'package:riocaja_smart/widgets/user_action_dialogs.dart';
import 'package:riocaja_smart/utils/text_constants.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'todos';
  String _roleFilter = 'todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // ✅ CRÍTICO: Configurar AdminService antes de cargar datos
    _setupAdminService();
    
    // Cargar datos solo después de configurar el servicio
    _loadData();
  }

  /// ✅ MÉTODO CLAVE: Configurar AdminService con contexto y token
  void _setupAdminService() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('UserManagementScreen: Configurando AdminService...');
    print('UserManagementScreen: Usuario autenticado: ${authProvider.isAuthenticated}');
    print('UserManagementScreen: Rol del usuario: ${authProvider.user?.rol}');
    print('UserManagementScreen: Token disponible: ${authProvider.user?.token != null ? "SÍ" : "NO"}');
    
    // Verificar permisos de administrador
    if (!authProvider.hasRole('admin') && !authProvider.hasRole('asesor')) {
      print('UserManagementScreen: ❌ Usuario sin permisos de administrador');
      return;
    }
    
    // Verificar que el token esté disponible
    if (authProvider.user?.token == null) {
      print('UserManagementScreen: ❌ No hay token de autenticación disponible');
      return;
    }
    
    // Configurar AdminService
    _adminService.setContext(context);
    _adminService.setAuthToken(authProvider.user!.token);
    
    print('UserManagementScreen: ✅ AdminService configurado correctamente');
    print('UserManagementScreen: Token configurado: ${authProvider.user!.token.substring(0, 10)}...');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // ✅ Verificar que el AdminService esté configurado antes de cargar
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.hasRole('admin') && !authProvider.hasRole('asesor')) {
      print('UserManagementScreen: ❌ Sin permisos para cargar datos');
      return;
    }
    
    if (authProvider.user?.token == null) {
      print('UserManagementScreen: ❌ Sin token para cargar datos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('UserManagementScreen: Iniciando carga de datos...');
      
      final pendingUsers = await _adminService.getPendingUsers();
      final allUsers = await _adminService.getAllUsers();
      
      setState(() {
        _pendingUsers = pendingUsers;
        _allUsers = allUsers;
      });
      
      print('UserManagementScreen: ✅ Datos cargados exitosamente');
      print('UserManagementScreen: Pendientes: ${_pendingUsers.length}, Todos: ${_allUsers.length}');
      
    } catch (e) {
      print('UserManagementScreen: ❌ Error cargando datos: $e');
      _showSnackBar('Error cargando datos: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================================
  // ACCIONES CON NOTIFICACIONES
  // ================================

  Future<void> _approveUser(Map<String, dynamic> user) async {
    try {
      final codigo = await UserActionDialogs.showApprovalDialog(
        context, 
        user['nombre'] ?? 'Usuario'
      );
      
      if (codigo != null) {
        UserActionDialogs.showLoadingDialog(context, 'Aprobando usuario...');
        
        final success = await _adminService.approveUserWithCode(
          user['_id'],
          codigo,
        );
        
        Navigator.of(context).pop(); // Cerrar loading
        
        if (success) {
          await UserActionDialogs.showSuccessDialog(
            context,
            title: 'Usuario Aprobado',
            message: 'El usuario ${user['nombre']} ha sido aprobado exitosamente con el código $codigo.',
          );
          _loadData(); // Recargar datos
        } else {
          throw Exception('Error al aprobar usuario');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading si está abierto
      await UserActionDialogs.showErrorDialog(
        context,
        title: 'Error',
        message: 'No se pudo aprobar el usuario: $e',
      );
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    try {
      final reason = await UserActionDialogs.showRejectDialog(
        context,
        user['nombre'] ?? 'Usuario'
      );
      
      // El usuario confirmó el rechazo (reason puede ser null)
      if (reason != null || await UserActionDialogs.showConfirmationDialog(
        context,
        title: 'Confirmar Rechazo',
        message: '¿Está seguro de rechazar este usuario sin especificar motivo?',
        confirmText: 'Rechazar',
        confirmColor: Colors.red,
        icon: Icons.warning,
      )) {
        UserActionDialogs.showLoadingDialog(context, 'Rechazando usuario...');
        
        final success = await _adminService.rejectUser(
          user['_id'],
          reason: reason,
        );
        
        Navigator.of(context).pop(); // Cerrar loading
        
        if (success) {
          await UserActionDialogs.showSuccessDialog(
            context,
            title: 'Usuario Rechazado',
            message: 'El usuario ${user['nombre']} ha sido rechazado.',
          );
          _loadData(); // Recargar datos
        } else {
          throw Exception('Error al rechazar usuario');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading si está abierto
      await UserActionDialogs.showErrorDialog(
        context,
        title: 'Error',
        message: 'No se pudo rechazar el usuario: $e',
      );
    }
  }

  Future<void> _changeUserState(Map<String, dynamic> user, String newState) async {
    try {
      final reason = await UserActionDialogs.showChangeStateDialog(
        context,
        user['nombre'] ?? 'Usuario',
        newState,
      );
      
      // El usuario confirmó el cambio (reason puede ser null)
      if (reason != null || await UserActionDialogs.showConfirmationDialog(
        context,
        title: 'Confirmar Cambio',
        message: '¿Está seguro de cambiar el estado sin especificar motivo?',
        confirmText: 'Cambiar',
        icon: Icons.warning,
      )) {
        UserActionDialogs.showLoadingDialog(context, 'Cambiando estado...');
        
        final success = await _adminService.changeUserState(
          user['_id'],
          newState,
          reason: reason,
        );
        
        Navigator.of(context).pop(); // Cerrar loading
        
        if (success) {
          await UserActionDialogs.showSuccessDialog(
            context,
            title: 'Estado Cambiado',
            message: 'El estado del usuario ${user['nombre']} ha sido cambiado a ${TextConstants.getEstadoName(newState)}.',
          );
          _loadData(); // Recargar datos
        } else {
          throw Exception('Error al cambiar estado');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading si está abierto
      await UserActionDialogs.showErrorDialog(
        context,
        title: 'Error',
        message: 'No se pudo cambiar el estado: $e',
      );
    }
  }

  // ✅ NUEVO: Método para cambiar rol de usuario
  Future<void> _changeUserRole(Map<String, dynamic> user, String newRole) async {
    try {
      final reason = await UserActionDialogs.showChangeRoleDialog(
        context,
        user['nombre'] ?? 'Usuario',
        user['rol'] ?? 'cnb',
        newRole,
      );
      
      // El usuario confirmó el cambio (reason puede ser null)
      if (reason != null || await UserActionDialogs.showConfirmationDialog(
        context,
        title: 'Confirmar Cambio de Rol',
        message: '¿Está seguro de cambiar el rol de ${user['nombre']} a ${newRole.toUpperCase()}?',
        confirmText: 'Cambiar',
        icon: Icons.admin_panel_settings,
      )) {
        UserActionDialogs.showLoadingDialog(context, 'Cambiando rol...');
        
        final success = await _adminService.changeUserRole(
          user['_id'],
          newRole,
        );
        
        Navigator.of(context).pop(); // Cerrar loading
        
        if (success) {
          await UserActionDialogs.showSuccessDialog(
            context,
            title: 'Rol Cambiado',
            message: 'El rol del usuario ${user['nombre']} ha sido cambiado a ${newRole.toUpperCase()}.',
          );
          _loadData(); // Recargar datos
        } else {
          throw Exception('Error al cambiar rol');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading si está abierto
      await UserActionDialogs.showErrorDialog(
        context,
        title: 'Error',
        message: 'No se pudo cambiar el rol: $e',
      );
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    try {
      final reason = await UserActionDialogs.showDeleteDialog(
        context,
        user['nombre'] ?? 'Usuario'
      );
      
      // El usuario confirmó la eliminación (reason puede ser null)
      if (reason != null || await UserActionDialogs.showConfirmationDialog(
        context,
        title: 'Confirmar Eliminación',
        message: '¿Está ABSOLUTAMENTE SEGURO de eliminar este usuario sin especificar motivo? Esta acción es IRREVERSIBLE.',
        confirmText: 'Eliminar',
        confirmColor: Colors.red.shade700,
        icon: Icons.delete_forever,
      )) {
        UserActionDialogs.showLoadingDialog(context, 'Eliminando usuario...');
        
        final success = await _adminService.deleteUser(
          user['_id'],
          reason: reason,
        );
        
        Navigator.of(context).pop(); // Cerrar loading
        
        if (success) {
          await UserActionDialogs.showSuccessDialog(
            context,
            title: 'Usuario Eliminado',
            message: 'El usuario ${user['nombre']} ha sido eliminado del sistema.',
          );
          _loadData(); // Recargar datos
        } else {
          throw Exception('Error al eliminar usuario');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading si está abierto
      await UserActionDialogs.showErrorDialog(
        context,
        title: 'Error',
        message: 'No se pudo eliminar el usuario: $e',
      );
    }
  }

  // ✅ NUEVO: Método para mostrar menú de cambio de estado
  Future<void> _showStateChangeMenu(Map<String, dynamic> user) async {
    final availableStates = ['activo', 'inactivo', 'suspendido'];
    final currentState = user['estado'] ?? 'pendiente';
    
    // Remover el estado actual de las opciones
    availableStates.removeWhere((state) => state == currentState);
    
    final selectedState = await UserActionDialogs.showStateSelectionDialog(
      context,
      user['nombre'] ?? 'Usuario',
      availableStates,
    );
    
    if (selectedState != null) {
      await _changeUserState(user, selectedState);
    }
  }

  // ✅ NUEVO: Método para mostrar menú de cambio de rol
  Future<void> _showRoleChangeMenu(Map<String, dynamic> user) async {
    final availableRoles = ['admin', 'asesor', 'cnb'];
    final currentRole = user['rol'] ?? 'cnb';
    
    // Remover el rol actual de las opciones
    availableRoles.removeWhere((role) => role == currentRole);
    
    final selectedRole = await UserActionDialogs.showRoleSelectionDialog(
      context,
      user['nombre'] ?? 'Usuario',
      currentRole,
      availableRoles,
    );
    
    if (selectedRole != null) {
      await _changeUserRole(user, selectedRole);
    }
  }

  // ✅ NUEVO: Método para mostrar detalles del usuario
  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    await UserActionDialogs.showUserDetailsDialog(context, user);
  }

  // ✅ NUEVO: Widget para estadísticas mejoradas
  Widget _buildStatsHeader() {
    final activeUsers = _allUsers.where((u) => u['estado'] == 'activo').length;
    final pendingUsers = _pendingUsers.length;
    final suspendedUsers = _allUsers.where((u) => u['estado'] == 'suspendido').length;
    final inactiveUsers = _allUsers.where((u) => u['estado'] == 'inactivo').length;
    final totalUsers = _allUsers.length;

    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Total', totalUsers, Colors.blue, Icons.people),
              _buildStatCard('Activos', activeUsers, Colors.green, Icons.check_circle),
              _buildStatCard('Pendientes', pendingUsers, Colors.orange, Icons.schedule),
              _buildStatCard('Suspendidos', suspendedUsers, Colors.red, Icons.block),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard('Inactivos', inactiveUsers, Colors.grey, Icons.pause_circle),
              _buildStatCard('Admins', _allUsers.where((u) => u['rol'] == 'admin').length, Colors.purple, Icons.admin_panel_settings),
              _buildStatCard('Asesores', _allUsers.where((u) => u['rol'] == 'asesor').length, Colors.teal, Icons.support_agent),
              _buildStatCard('CNBs', _allUsers.where((u) => u['rol'] == 'cnb' || u['rol'] == null).length, Colors.indigo, Icons.person),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(height: 2),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // UI BUILDERS - PARTE 2 (Líneas 501-Final)
  // ================================

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Verificar permisos antes de mostrar la interfaz
        if (!authProvider.hasRole('admin') && !authProvider.hasRole('asesor')) {
          return Scaffold(
            appBar: AppBar(title: Text('Acceso Denegado')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'No tienes permisos de administrador',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Gestión de Usuarios'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  icon: Icon(Icons.pending_actions),
                  text: 'Pendientes (${_pendingUsers.length})',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Todos (${_allUsers.length})',
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadData,
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando usuarios...'),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingUsersTab(),
                    _buildAllUsersTab(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPendingUsersTab() {
    if (_pendingUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No hay usuarios pendientes',
        subtitle: 'Todos los usuarios han sido procesados',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _pendingUsers.length,
        itemBuilder: (context, index) {
          return _buildPendingUserCard(_pendingUsers[index]);
        },
      ),
    );
  }

  Widget _buildAllUsersTab() {
    return Column(
      children: [
        _buildStatsHeader(), // ✅ NUEVO: Estadísticas mejoradas
        _buildSearchAndFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _buildFilteredUsersList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          
          SizedBox(height: 12),
          
          // Filtros
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
                        DropdownMenuItem(value: 'inactivo', child: Text('Inactivos')),
                        DropdownMenuItem(value: 'suspendido', child: Text('Suspendidos')),
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
                        DropdownMenuItem(value: 'asesor', child: Text('Asesores')),
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

  Widget _buildFilteredUsersList() {
    final filteredUsers = _filterUsers(_allUsers);
    
    if (filteredUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No se encontraron usuarios',
        subtitle: 'Intenta ajustar los filtros de búsqueda',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(filteredUsers[index]);
      },
    );
  }

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

  Widget _buildPendingUserCard(Map<String, dynamic> user) {
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
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    user['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Email
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  user['email'] ?? 'Sin email',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            
            SizedBox(height: 4),
            
            // Rol y fecha
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'Rol: ${user['rol']?.toUpperCase() ?? 'CNB'}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Spacer(),
                Text(
                  fechaRegistro,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // ✅ BOTONES DE ACCIÓN ACTUALIZADOS PARA PENDIENTES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveUser(user),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectUser(user),
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Rechazar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                
                // Menú de opciones adicionales para pendientes
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'details':
                        _showUserDetails(user);
                        break;
                      case 'change_role':
                        _showRoleChangeMenu(user);
                        break;
                      case 'delete':
                        _deleteUser(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Ver Detalles'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'change_role',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Cambiar Rol'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final estado = user['estado'] ?? 'pendiente';
    Color statusColor;
    
    switch (estado.toLowerCase()) {
      case 'activo':
        statusColor = Colors.green;
        break;
      case 'pendiente':
        statusColor = Colors.orange;
        break;
      case 'inactivo':
        statusColor = Colors.grey;
        break;
      case 'suspendido':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    user['nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            // Email y rol
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user['email'] ?? 'Sin email',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 4),
            
            // Rol y código corresponsal
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['rol'] ?? 'cnb').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rol: ${user['rol']?.toUpperCase() ?? 'CNB'}',
                    style: TextStyle(
                      color: _getRoleColor(user['rol'] ?? 'cnb'),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                if (user['codigo_corresponsal'] != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Código: ${user['codigo_corresponsal']}',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            SizedBox(height: 16),
            
            // ✅ BOTONES DE ACCIÓN ACTUALIZADOS
            Row(
              children: [
                // Botón de estado
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStateChangeMenu(user),
                    icon: Icon(Icons.swap_horiz, size: 16),
                    label: Text('Estado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade700,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                
                // Botón de rol
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRoleChangeMenu(user),
                    icon: Icon(Icons.admin_panel_settings, size: 16),
                    label: Text('Rol'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                
                // Menú de opciones adicionales
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'details':
                        _showUserDetails(user);
                        break;
                      case 'delete':
                        _deleteUser(user);
                        break;
                      case 'activate':
                        _changeUserState(user, 'activo');
                        break;
                      case 'deactivate':
                        _changeUserState(user, 'inactivo');
                        break;
                      case 'suspend':
                        _changeUserState(user, 'suspendido');
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final estado = user['estado'] ?? 'pendiente';
                    List<PopupMenuEntry<String>> items = [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Ver Detalles'),
                          ],
                        ),
                      ),
                    ];
                    
                    // Opciones de estado según el estado actual
                    if (estado != 'activo') {
                      items.add(
                        PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Activar'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    if (estado != 'inactivo') {
                      items.add(
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Row(
                            children: [
                              Icon(Icons.pause_circle, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Desactivar'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    if (estado != 'suspendido') {
                      items.add(
                        PopupMenuItem(
                          value: 'suspend',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Suspender'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Separador y opción de eliminar
                    items.addAll([
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ]);
                    
                    return items;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            label: Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODOS AUXILIARES
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'asesor':
        return Colors.teal;
      case 'cnb':
      default:
        return Colors.indigo;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'asesor':
        return 'Asesor';
      case 'cnb':
      default:
        return 'CNB';
    }
  }

  String _getStateDisplayName(String state) {
    switch (state.toLowerCase()) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'suspendido':
        return 'Suspendido';
      case 'pendiente':
        return 'Pendiente';
      default:
        return state.toUpperCase();
    }
  }
}