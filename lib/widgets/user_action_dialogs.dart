// lib/widgets/user_action_dialogs.dart
import 'package:flutter/material.dart';

class UserActionDialogs {
  
  // Diálogo de aprobación
  static Future<String?> showApprovalDialog(BuildContext context, String userName) async {
    String? codigo;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aprobar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Desea aprobar a $userName?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Código de Corresponsal',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => codigo = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codigo != null && codigo!.isNotEmpty) {
                Navigator.pop(context, codigo);
              }
            },
            child: Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de rechazo
  static Future<String?> showRejectDialog(BuildContext context, String userName) async {
    String? reason;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rechazar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Desea rechazar a $userName?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason ?? ''),
            child: Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de cambio de estado
  static Future<String?> showChangeStateDialog(BuildContext context, String userName, String newState) async {
    String? reason;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Cambiar estado de $userName a $newState?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason ?? ''),
            child: Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de cambio de rol
  static Future<String?> showChangeRoleDialog(BuildContext context, String userName, String currentRole, String newRole) async {
    String? reason;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Cambiar rol de $userName de $currentRole a $newRole?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason ?? ''),
            child: Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de eliminación
  static Future<String?> showDeleteDialog(BuildContext context, String userName) async {
    String? reason;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿ELIMINAR PERMANENTEMENTE a $userName?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason ?? ''),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Diálogo de selección de estado
  static Future<String?> showStateSelectionDialog(BuildContext context, String userName, List<String> availableStates) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Seleccione el nuevo estado para $userName:'),
            SizedBox(height: 16),
            ...availableStates.map((state) => ListTile(
              title: Text(state.toUpperCase()),
              onTap: () => Navigator.pop(context, state),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de selección de rol
  static Future<String?> showRoleSelectionDialog(BuildContext context, String userName, String currentRole, List<String> availableRoles) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rol actual: $currentRole'),
            SizedBox(height: 8),
            Text('Seleccione el nuevo rol para $userName:'),
            SizedBox(height: 16),
            ...availableRoles.map((role) => ListTile(
              title: Text(role.toUpperCase()),
              onTap: () => Navigator.pop(context, role),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.blue,
            ),
            child: Text(confirmText, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Diálogo de carga
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // Diálogo de éxito
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Diálogo de error
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Diálogo de detalles del usuario
  static Future<void> showUserDetailsDialog(BuildContext context, Map<String, dynamic> user) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Usuario'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nombre: ${user['nombre'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Email: ${user['email'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Estado: ${user['estado'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Rol: ${user['rol'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Código: ${user['codigo_corresponsal'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Teléfono: ${user['telefono'] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}