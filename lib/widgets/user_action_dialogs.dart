// lib/widgets/user_action_dialogs.dart - DIÁLOGOS PARA ACCIONES DE USUARIO
import 'package:flutter/material.dart';
import 'package:riocaja_smart/utils/text_constants.dart';

class UserActionDialogs {
  
  // ================================
  // DIÁLOGO DE APROBACIÓN CON CÓDIGO
  // ================================
  
  static Future<String?> showApprovalDialog(BuildContext context, String userName) async {
    final TextEditingController codigoController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aprobar Usuario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usuario: $userName', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 16),
                Text(
                  'Asignar Código de Corresponsal:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: codigoController,
                  decoration: InputDecoration(
                    hintText: 'Ej: CNB001',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El código es obligatorio';
                    }
                    if (value.trim().length < 4) {
                      return 'El código debe tener al menos 4 caracteres';
                    }
                    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.trim().toUpperCase())) {
                      return 'Solo letras mayúsculas y números';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.green.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se enviará un email automático de aprobación con el código asignado.',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(codigoController.text.trim().toUpperCase());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Aprobar'),
            ),
          ],
        );
      },
    );
  }

  // ================================
  // DIÁLOGO DE RECHAZO CON MOTIVO
  // ================================
  
  static Future<String?> showRejectDialog(BuildContext context, String userName) async {
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rechazar Usuario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usuario: $userName', style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 16),
                Text(
                  'Motivo del rechazo (opcional):',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ej: Documentación incompleta, datos incorretos...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.note_alt),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se enviará un email automático de rechazo al usuario.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
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
              onPressed: () {
                final reason = reasonController.text.trim();
                Navigator.of(context).pop(reason.isEmpty ? null : reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Rechazar'),
            ),
          ],
        );
      },
    );
  }

  // ================================
  // DIÁLOGO GENÉRICO DE CAMBIO DE ESTADO
  // ================================
  
  static Future<String?> showChangeStateDialog(
    BuildContext context, 
    String userName, 
    String newState
  ) async {
    final TextEditingController reasonController = TextEditingController();
    
    // Configurar información según el estado
    late String title;
    late IconData icon;
    late Color color;
    late String actionText;
    late String description;
    
    switch (newState.toLowerCase()) {
      case 'suspendido':
        title = 'Suspender Usuario';
        icon = Icons.pause_circle;
        color = Colors.orange;
        actionText = 'Suspender';
        description = 'El usuario no podrá acceder temporalmente al sistema.';
        break;
      case 'inactivo':
        title = 'Desactivar Usuario';
        icon = Icons.block;
        color = Colors.grey;
        actionText = 'Desactivar';
        description = 'El usuario será marcado como inactivo.';
        break;
      case 'activo':
        title = 'Activar Usuario';
        icon = Icons.check_circle;
        color = Colors.green;
        actionText = 'Activar';
        description = 'El usuario podrá acceder normalmente al sistema.';
        break;
      default:
        title = 'Cambiar Estado';
        icon = Icons.edit;
        color = Colors.blue;
        actionText = 'Cambiar';
        description = 'Se cambiará el estado del usuario.';
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: $userName', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Text('Nuevo estado: ${TextConstants.getEstadoName(newState)}', 
                   style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 16),
              Text(description, style: TextStyle(color: Colors.grey.shade600)),
              SizedBox(height: 16),
              Text(
                'Motivo (opcional):',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Razón del cambio de estado...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.note_alt),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: color, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se enviará un email automático notificando el cambio.',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                Navigator.of(context).pop(reason.isEmpty ? null : reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }

  // ================================
  // DIÁLOGO DE ELIMINACIÓN
  // ================================
  
  static Future<String?> showDeleteDialog(BuildContext context, String userName) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red.shade700, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eliminar Usuario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: $userName', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '¡ATENCIÓN!',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Esta acción es IRREVERSIBLE. El usuario será eliminado permanentemente del sistema.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Motivo de eliminación (opcional):',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Razón de la eliminación...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.note_alt),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se enviará un email automático notificando la eliminación.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                Navigator.of(context).pop(reason.isEmpty ? null : reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // ================================
  // DIÁLOGO DE CONFIRMACIÓN SIMPLE
  // ================================
  
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: confirmColor ?? Colors.blue, size: 28),
                SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor ?? Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ================================
  // DIÁLOGO DE INFORMACIÓN/ÉXITO
  // ================================
  
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Aceptar',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.green.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se ha enviado una notificación por email automáticamente.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  // ================================
  // DIÁLOGO DE ERROR
  // ================================
  
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Aceptar',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  // ================================
  // DIÁLOGO DE CARGA/PROGRESO
  // ================================
  
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  // ================================
  // DIÁLOGO DE SELECCIÓN DE ESTADO
  // ================================
  
  static Future<String?> showStateSelectionDialog(
    BuildContext context, 
    String userName,
    List<String> availableStates
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text('Cambiar Estado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: $userName', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 16),
              Text('Seleccionar nuevo estado:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              ...availableStates.map((state) {
                IconData icon;
                Color color;
                
                switch (state.toLowerCase()) {
                  case 'activo':
                    icon = Icons.check_circle;
                    color = Colors.green;
                    break;
                  case 'inactivo':
                    icon = Icons.block;
                    color = Colors.grey;
                    break;
                  case 'suspendido':
                    icon = Icons.pause_circle;
                    color = Colors.orange;
                    break;
                  default:
                    icon = Icons.radio_button_unchecked;
                    color = Colors.blue;
                }
                
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(TextConstants.getEstadoName(state)),
                  onTap: () => Navigator.of(context).pop(state),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}