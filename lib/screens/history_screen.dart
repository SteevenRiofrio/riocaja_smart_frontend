// lib/screens/history_screen.dart - VERSIÓN COMPLETA SIMPLIFICADA
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  Set<String> _selectedFilters = {}; // vacío significa "Todos"
  DateTime? _selectedDate; // Filtro por fecha
  bool _sortDescending = true; // Ordenar de mayor a menor hora (descendente)
  
  // Lista de tipos disponibles que se actualiza dinámicamente
  Set<String> _availableTypes = {};

  @override
  void initState() {
    super.initState();
    // Configurar locale en español
    Intl.defaultLocale = 'es_ES';
    
    // Verificar autenticación
    _checkAuthentication();
    print('HistoryScreen initState - cargando comprobantes...');
    _loadReceipts();
  }

  // Método para verificar autenticación
  void _checkAuthentication() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      // Si no está autenticado, redirigir a login
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);

    try {
      print('HistoryScreen: Intentando cargar comprobantes desde el provider...');

      // Obtener información sobre la URL del API service
      final apiService = ApiService();
      print('HistoryScreen: URL del API: ${apiService.baseUrl}/receipts/');

      // Establecer el contexto en el provider
      final receiptsProvider = Provider.of<ReceiptsProvider>(context, listen: false);
      receiptsProvider.setContext(context);

      await receiptsProvider.loadReceipts();
      final receipts = receiptsProvider.receipts;
      print('HistoryScreen: Se cargaron ${receipts.length} comprobantes');

      // ACTUALIZAR TIPOS DISPONIBLES DINÁMICAMENTE
      _updateAvailableTypes(receipts);

      if (receipts.isEmpty) {
        print('HistoryScreen: La lista de comprobantes está vacía');
      } else {
        // Mostrar el primer comprobante como ejemplo
        print('HistoryScreen: Muestra del primer comprobante: ${receipts[0].nroTransaccion}');
      }
    } catch (e) {
      print('HistoryScreen: Error al cargar comprobantes: $e');
      print('HistoryScreen: Tipo de error: ${e.runtimeType}');
      print('HistoryScreen: Detalles completos: $e');

      // Comprobar si es un error de autenticación
      if (e.toString().contains('Sesión expirada') || e.toString().contains('Token')) {
        // Mostrar mensaje al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión expirada. Inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );

        // Redirigir a pantalla de login
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      }
    }

    setState(() => _isLoading = false);
  }

  // Método para actualizar tipos disponibles dinámicamente
  void _updateAvailableTypes(List<Receipt> receipts) {
    Set<String> types = {};
    for (var receipt in receipts) {
      if (receipt.tipo.isNotEmpty) {
        types.add(receipt.tipo);
      }
    }
    
    // CLAVE: Solo actualizar si realmente cambió algo
    if (!_setEquals(_availableTypes, types)) {
      setState(() {
        _availableTypes = types;
        // Limpiar filtros que ya no existen en los datos
        _selectedFilters.removeWhere((filter) => !_availableTypes.contains(filter));
      });
      
      print('Tipos de comprobantes actualizados: $_availableTypes');
    }
  }

  // Método para comparar sets sin modificar el estado
  bool _setEquals<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptsProvider>(
      builder: (context, receiptsProvider, child) {
        final _allReceipts = receiptsProvider.receipts;
        final _isProviderLoading = receiptsProvider.isLoading;

        // CORREGIDO: Solo actualizar si NO está cargando y hay datos
        if (!_isProviderLoading && _allReceipts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateAvailableTypes(_allReceipts);
          });
        }

        // Filtrar los comprobantes según los filtros seleccionados
        final _receipts = _filterReceipts(_allReceipts);

        return Scaffold(
          appBar: AppBar(
            title: Text('Historial de Comprobantes'),
            actions: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: _availableTypes.isNotEmpty ? _showFilterOptions : null,
                tooltip: _availableTypes.isEmpty ? 'Sin tipos disponibles' : 'Filtrar por tipo',
              ),
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: _selectDate,
                tooltip: 'Filtrar por fecha',
              ),
              IconButton(
                icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
                tooltip: _sortDescending ? 'Mostrando más recientes primero' : 'Mostrando más antiguos primero',
                onPressed: () {
                  setState(() {
                    _sortDescending = !_sortDescending;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh), 
                onPressed: _loadReceipts,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          body: _isLoading || _isProviderLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Mostrar los filtros activos
                    _buildActiveFilters(),

                    // Lista de comprobantes
                    Expanded(
                      child: _receipts.isEmpty ? _buildEmptyState() : _buildReceiptsList(_receipts),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // Método para mostrar los filtros activos
  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // Filtros por tipo de comprobante
    if (_selectedFilters.isNotEmpty) {
      if (_selectedFilters.length <= 2) {
        // Si hay pocos filtros, mostrar uno por uno
        for (final filter in _selectedFilters) {
          filterChips.add(
            Chip(
              label: Text(filter),
              onDeleted: () {
                setState(() {
                  _selectedFilters.remove(filter);
                });
              },
            ),
          );
        }
      } else {
        // Si hay muchos filtros, mostrar la cantidad
        filterChips.add(
          Chip(
            label: Text('${_selectedFilters.length} tipos seleccionados'),
            onDeleted: () {
              setState(() {
                _selectedFilters.clear();
              });
            },
          ),
        );
      }
    }

    // Filtro por fecha EN ESPAÑOL
    if (_selectedDate != null) {
      final dateStr = _formatDateInSpanish(_selectedDate!);
      filterChips.add(
        Chip(
          label: Text('Fecha: $dateStr'),
          onDeleted: () {
            setState(() {
              _selectedDate = null;
            });
          },
        ),
      );
    }

    // Filtro de ordenamiento
    filterChips.add(
      Chip(
        label: Text(_sortDescending ? 'Más recientes primero' : 'Más antiguos primero'),
        onDeleted: null, // No permite eliminar este chip
        deleteIcon: Icon(
          _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
          size: 18,
        ),
      ),
    );

    if (filterChips.isEmpty) {
      return SizedBox.shrink(); // No mostrar nada si no hay filtros activos
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade200,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filterChips,
      ),
    );
  }

  // NUEVO: Método para formatear fecha en español
  String _formatDateInSpanish(DateTime date) {
    final formatter = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es_ES');
    return formatter.format(date);
  }

  // MEJORADO: Método para seleccionar fecha con interfaz en español
  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Locale('es', 'ES'), // ESPAÑOL
      helpText: 'Seleccionar fecha', // En español
      cancelText: 'Cancelar', // En español
      confirmText: 'Aceptar', // En español
      fieldLabelText: 'Ingrese fecha', // En español
      fieldHintText: 'dd/mm/aaaa', // En español
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Método para filtrar comprobantes (sin cambios)
  List<Receipt> _filterReceipts(List<Receipt> receipts) {
    List<Receipt> filteredReceipts = List.from(receipts);

    // Filtrar por tipos - ahora soportamos múltiples tipos
    if (_selectedFilters.isNotEmpty) {
      filteredReceipts = filteredReceipts.where((receipt) => _selectedFilters.contains(receipt.tipo)).toList();
    }

    // Filtrar por fecha
    if (_selectedDate != null) {
      final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      filteredReceipts = filteredReceipts.where((receipt) => receipt.fecha == dateStr).toList();
    }

    // Ordenar por fecha y hora
    filteredReceipts.sort((a, b) {
      // Primero comparar por fecha
      int dateComparison = _compareDate(a.fecha, b.fecha);

      // Si las fechas son diferentes, retornar la comparación de fechas
      if (dateComparison != 0) {
        return _sortDescending ? -dateComparison : dateComparison;
      }

      // Si las fechas son iguales, comparar por hora
      int aSeconds = _timeToSeconds(a.hora);
      int bSeconds = _timeToSeconds(b.hora);

      if (_sortDescending) {
        return bSeconds.compareTo(aSeconds); // De mayor a menor
      } else {
        return aSeconds.compareTo(bSeconds); // De menor a mayor
      }
    });

    return filteredReceipts;
  }

  // Métodos auxiliares (sin cambios)
  int _timeToSeconds(String timeStr) {
    if (timeStr.isEmpty) return 0;

    List<String> parts = timeStr.split(':');
    if (parts.length != 3) return 0;

    try {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);

      return hours * 3600 + minutes * 60 + seconds;
    } catch (e) {
      print('Error al convertir tiempo: $e');
      return 0;
    }
  }

  int _compareDate(String dateA, String dateB) {
    if (dateA.isEmpty) return -1;
    if (dateB.isEmpty) return 1;

    try {
      final a = _parseDate(dateA);
      final b = _parseDate(dateB);

      if (a == null) return -1;
      if (b == null) return 1;

      return a.compareTo(b);
    } catch (e) {
      return 0;
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  // MEJORADO: Método para mostrar filtros DINÁMICOS según tipos disponibles
  void _showFilterOptions() {
    // Verificar que hay tipos disponibles
    if (_availableTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay tipos de comprobantes disponibles para filtrar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Crear una copia temporal de los filtros seleccionados
    Set<String> tempFilters = Set.from(_selectedFilters);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Filtrar por tipo de comprobante',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempFilters.clear();
                            });
                          },
                          child: Text('Limpiar'),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  
                  // Mostrar información sobre tipos disponibles
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Tipos disponibles en tus comprobantes (${_availableTypes.length}):',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: ListView(
                      children: [
                        // SOLO MOSTRAR TIPOS DISPONIBLES DINÁMICAMENTE
                        ..._availableTypes.map((tipo) {
                          return _buildFilterCheckbox(
                            tipo,
                            _getIconForType(tipo),
                            _getColorForTypeFilter(tipo),
                            tempFilters,
                            setModalState,
                          );
                        }).toList(),
                        
                        // Mensaje si no hay tipos disponibles
                        if (_availableTypes.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No hay comprobantes para filtrar',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancelar'),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilters = tempFilters;
                            });
                            Navigator.pop(context);
                          },
                          child: Text('Aplicar Filtros'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // Widget para checkbox de filtros (sin cambios)
  Widget _buildFilterCheckbox(
    String tipo,
    IconData icon,
    Color color,
    Set<String> tempFilters,
    StateSetter setModalState,
  ) {
    return CheckboxListTile(
      title: Text(tipo),
      secondary: Icon(icon, color: color),
      value: tempFilters.contains(tipo),
      onChanged: (bool? value) {
        setModalState(() {
          if (value == true) {
            tempFilters.add(tipo);
          } else {
            tempFilters.remove(tipo);
          }
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            _selectedFilters.isNotEmpty || _selectedDate != null 
              ? 'No hay comprobantes que coincidan con los filtros seleccionados'
              : 'No hay comprobantes escaneados',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          if (_selectedFilters.isNotEmpty || _selectedDate != null)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilters.clear();
                  _selectedDate = null;
                });
              },
              icon: Icon(Icons.clear_all),
              label: Text('Limpiar Filtros'),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Volver a la pantalla principal
              },
              icon: Icon(Icons.camera_alt),
              label: Text('Escanear Nuevo Comprobante'),
            ),
        ],
      ),
    );
  }

  // Card de comprobante (sin cambios)
  Widget _buildReceiptCard(Receipt receipt) {
    IconData typeIcon = _getIconForType(receipt.tipo);
    Color headerColor = _getColorForType(receipt.tipo);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReceiptDetails(receipt),
        child: Column(
          children: [
            // Header con tipo
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(typeIcon),
                  SizedBox(width: 8),
                  Text(
                    receipt.tipo,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Spacer(),
                  Text(
                    '${receipt.fecha} ${receipt.hora}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Contenido SIMPLIFICADO - Solo lo esencial
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transacción #${receipt.nroTransaccion}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (receipt.hora.isNotEmpty)
                          Text(
                            'Hora: ${receipt.hora}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${receipt.valorTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Botón eliminar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text('Eliminar'),
                    onPressed: () => _confirmDelete(receipt),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Detalles del comprobante (sin cambios)
  void _showReceiptDetails(Receipt receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.receipt_long, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Detalles del Comprobante',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),

                    // SOLO LOS CAMPOS BÁSICOS - SIMPLIFICADO!
                    _buildDetailRow('Fecha', receipt.fecha),
                    _buildDetailRow('Hora', receipt.hora),
                    _buildDetailRow('Tipo', receipt.tipo),
                    _buildDetailRow('Transacción', receipt.nroTransaccion),
                    _buildDetailRow(
                      'Valor Total',
                      '\$${receipt.valorTotal.toStringAsFixed(2)}',
                    ),

                    SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(
                        'Texto Completo Escaneado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            receipt.fullText,
                            style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(receipt);
                        },
                        icon: Icon(Icons.delete_outline),
                        label: Text('Eliminar Comprobante'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList(List<Receipt> receipts) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return _buildReceiptCard(receipt);
      },
    );
  }

  void _confirmDelete(Receipt receipt) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Comprobante'),
          content: Text(
            '¿Estás seguro de eliminar este comprobante? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar el diálogo

                // Usar el provider para eliminar el comprobante
                final provider = Provider.of<ReceiptsProvider>(
                  context,
                  listen: false,
                );
                provider.setContext(context); // Asegurarse de establecer el contexto

                try {
                  final success = await provider.deleteReceipt(receipt.nroTransaccion);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Comprobante eliminado exitosamente'),
                      ),
                    );

                    // Recargar la lista después de eliminar
                    await provider.loadReceipts();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar el comprobante'),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error al eliminar comprobante: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Métodos auxiliares para iconos y colores
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
      case 'RECARGA CLARO':          // ✅ ASEGURADO
      case 'RECARGA':                // ✅ VARIACIÓN
        return Icons.phone_android;
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return Icons.send;
      case 'PAGO GIRO':
        return Icons.receipt;
      default: // PAGO DE SERVICIO y otros
        return Icons.payment;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return Colors.orange.shade100;
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return Colors.purple.shade100;
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return Colors.green.shade100;
      case 'RECARGA CLARO':          // ✅ ASEGURADO
      case 'RECARGA':                // ✅ VARIACIÓN
        return Colors.red.shade100;
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return Colors.indigo.shade100;
      case 'PAGO GIRO':
        return Colors.teal.shade100;
      default: // PAGO DE SERVICIO y otros
        return Colors.blue.shade100;
    }
  }

  // Color para iconos en los filtros (más intenso que los headers)
  Color _getColorForTypeFilter(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RETIRO':
        return Colors.orange;
      case 'EFECTIVO MOVIL':
      case 'EFECTIVO MÓVIL':
        return Colors.purple;
      case 'DEPOSITO':
      case 'DEPÓSITO':
        return Colors.green;
      case 'RECARGA CLARO':          // ✅ ASEGURADO
      case 'RECARGA':                // ✅ VARIACIÓN
        return Colors.red;
      case 'ENVÍO GIRO':
      case 'ENVIO GIRO':
        return Colors.indigo;
      case 'PAGO GIRO':
        return Colors.teal;
      default: // PAGO DE SERVICIO y otros
        return Colors.blue;
    }
  }
}