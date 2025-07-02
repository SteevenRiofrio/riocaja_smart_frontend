// lib/screens/messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/models/message.dart';
import 'package:riocaja_smart/providers/message_provider.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Mensajes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          final messages = messageProvider.messages;
          
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'No tiene mensajes',
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
            onRefresh: _loadMessages,
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageCard(context, message);
              },
            ),
          );
        },
      ),
      // Botón para crear mensaje solo para admin/asesor
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) {
            return FloatingActionButton(
              onPressed: () => _showCreateMessageDialog(context),
              child: Icon(Icons.add),
              tooltip: 'Crear Mensaje',
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
  
  Widget _buildMessageCard(BuildContext context, Message message) {
    // Determinar color según tipo de mensaje
    Color cardColor;
    IconData iconData;
    
    switch (message.tipo) {
      case 'advertencia':
        cardColor = Colors.amber.shade100;
        iconData = Icons.warning;
        break;
      case 'urgente':
        cardColor = Colors.red.shade100;
        iconData = Icons.priority_high;
        break;
      default: // informativo
        cardColor = Colors.blue.shade100;
        iconData = Icons.info;
        break;
    }
    
    // Verificar si ya fue leído
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isRead = currentUserId != null ? message.isReadBy(currentUserId) : false;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isRead ? Colors.white : cardColor,
      child: InkWell(
        onTap: () => _showMessageDetails(context, message),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconData, color: isRead ? Colors.grey : Colors.black87),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.titulo,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                message.contenido.length > 100 
                    ? '${message.contenido.substring(0, 100)}...' 
                    : message.contenido,
                style: TextStyle(
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(message.fechaCreacion),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showMessageDetails(BuildContext context, Message message) {
    // Marcar como leído
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    messageProvider.markAsRead(message.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.titulo),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.contenido),
              SizedBox(height: 16),
              Text(
                'Enviado: ${DateFormat('dd/MM/yyyy HH:mm').format(message.fechaCreacion)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (message.visibleHasta != null)
                Text(
                  'Visible hasta: ${DateFormat('dd/MM/yyyy').format(message.visibleHasta!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          // Botón para eliminar (solo admin/asesor)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) {
                return TextButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Eliminar', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _confirmDeleteMessage(context, message);
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDeleteMessage(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Mensaje'),
        content: Text('¿Está seguro de que desea eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final messageProvider = Provider.of<MessageProvider>(context, listen: false);
              final success = await messageProvider.deleteMessage(message.id);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mensaje eliminado correctamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar el mensaje'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showCreateMessageDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String messageType = 'informativo';
    DateTime? expiryDate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Crear Mensaje'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: 'Contenido',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  SizedBox(height: 16),
                  Text('Tipo de mensaje:'),
                  DropdownButton<String>(
                    value: messageType,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'informativo',
                        child: Text('Informativo'),
                      ),
                      DropdownMenuItem(
                        value: 'advertencia',
                        child: Text('Advertencia'),
                      ),
                      DropdownMenuItem(
                        value: 'urgente',
                        child: Text('Urgente'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          messageType = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Visible hasta:'),
                      Spacer(),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          
                          if (pickedDate != null) {
                            setState(() {
                              expiryDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          expiryDate != null 
                              ? DateFormat('dd/MM/yyyy').format(expiryDate!)
                              : 'Seleccionar fecha',
                        ),
                      ),
                    ],
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
                  if (titleController.text.isEmpty || contentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por favor complete todos los campos'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.of(context).pop();
                  
                  final messageProvider = Provider.of<MessageProvider>(context, listen: false);
                  final success = await messageProvider.createMessage(
                    titleController.text,
                    contentController.text,
                    messageType,
                    visibleHasta: expiryDate,
                  );
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mensaje creado correctamente')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear el mensaje'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }
}