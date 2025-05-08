// lib/screens/history_screen.dart
// MODIFICADO: Actualizado método para usar fechas con guiones

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

  @override
  void initState() {
    super.initState();
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
      print(
        'HistoryScreen: Intentando cargar comprobantes desde el provider...',
      );

      // Obtener información sobre la URL del API service
      final apiService = ApiService(); // Necesitarás importar esta clase
      print('HistoryScreen: URL del API: ${apiService.baseUrl}/receipts/');

      // Establecer el contexto en el provider
      final receiptsProvider = Provider.of<ReceiptsProvider>(
        context,
        listen: false,
      );
      receiptsProvider.setContext(context);

      await receiptsProvider.loadReceipts();
      final receipts = receiptsProvider.receipts;
      print('HistoryScreen: Se cargaron ${receipts.length} comprobantes');

      if (receipts.isEmpty) {
        print('HistoryScreen: La lista de comprobantes está vacía');
      } else {
        // Mostrar el primer comprobante como ejemplo
        print(
          'HistoryScreen: Muestra del primer comprobante: ${receipts[0].nroTransaccion}',
        );
      }
    } catch (e) {
      print('HistoryScreen: Error al cargar comprobantes: $e');
      // Mostrar más detalles sobre el error
      print('HistoryScreen: Tipo de error: ${e.runtimeType}');
      print('HistoryScreen: Detalles completos: $e');

      // Comprobar si es un error de autenticación
      if (e.toString().contains('Sesión expirada') ||
          e.toString().contains('Token')) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptsProvider>(
      builder: (context, receiptsProvider, child) {
        final _allReceipts = receiptsProvider.receipts;
        final _isProviderLoading = receiptsProvider.isLoading;

        // Filtrar los comprobantes según los filtros seleccionados
        final _receipts = _filterReceipts(_allReceipts);

        return Scaffold(
          appBar: AppBar(
            title: Text('Historial de Comprobantes'),
            actions: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: _showFilterOptions,
              ),
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: _selectDate,
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
              IconButton(icon: Icon(Icons.refresh), onPressed: _loadReceipts),
            ],
          ),
          body:
              _isLoading || _isProviderLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      // Mostrar los filtros activos
                      _buildActiveFilters(),

                      // Lista de comprobantes
                      Expanded(
                        child:
                            _receipts.isEmpty
                                ? _buildEmptyState()
                                : _buildReceiptsList(_receipts),
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
  
  // Filtro por fecha
  if (_selectedDate != null) {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate!);
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
        size: 18
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
  // Método para seleccionar fecha
  void _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

// Método para filtrar comprobantes
List<Receipt> _filterReceipts(List<Receipt> receipts) {
  List<Receipt> filteredReceipts = List.from(receipts);
  
  // Filtrar por tipos - ahora soportamos múltiples tipos
  if (_selectedFilters.isNotEmpty) {
    filteredReceipts = filteredReceipts.where((receipt) => 
      _selectedFilters.contains(receipt.tipo)
    ).toList();
  }
  
  // Filtrar por fecha
  if (_selectedDate != null) {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    filteredReceipts = filteredReceipts.where((receipt) => 
      receipt.fecha == dateStr
    ).toList();
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

// Método auxiliar para convertir hora (HH:mm:ss) a segundos
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

// Método auxiliar para comparar fechas en formato dd/MM/yyyy
int _compareDate(String dateA, String dateB) {
  // Si alguna fecha está vacía, considerarla como "menor"
  if (dateA.isEmpty) return -1;
  if (dateB.isEmpty) return 1;
  
  try {
    // Convertir a objetos DateTime
    final a = _parseDate(dateA);
    final b = _parseDate(dateB);
    
    if (a == null) return -1;
    if (b == null) return 1;
    
    return a.compareTo(b);
  } catch (e) {
    return 0; // En caso de error, considerar las fechas iguales
  }
}

// Método auxiliar para convertir string dd/MM/yyyy a DateTime
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

  // Método para mostrar las opciones de filtro
void _showFilterOptions() {
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
                Expanded(
                  child: ListView(
                    children: [
                      CheckboxListTile(
                        title: Text('Pagos de Servicio'),
                        secondary: Icon(Icons.payment, color: Colors.blue),
                        value: tempFilters.contains('Pago de Servicio'),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              tempFilters.add('Pago de Servicio');
                            } else {
                              tempFilters.remove('Pago de Servicio');
                            }
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Retiros'),
                        secondary: Icon(Icons.money_off, color: Colors.orange),
                        value: tempFilters.contains('Retiro'),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              tempFilters.add('Retiro');
                            } else {
                              tempFilters.remove('Retiro');
                            }
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Efectivo Móvil'),
                        secondary: Icon(Icons.mobile_friendly, color: Colors.purple),
                        value: tempFilters.contains('EFECTIVO MOVIL'),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              tempFilters.add('EFECTIVO MOVIL');
                            } else {
                              tempFilters.remove('EFECTIVO MOVIL');
                            }
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Depósitos'),
                        secondary: Icon(Icons.savings, color: Colors.green),
                        value: tempFilters.contains('DEPOSITO'),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              tempFilters.add('DEPOSITO');
                            } else {
                              tempFilters.remove('DEPOSITO');
                            }
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Recargas Claro'),
                        secondary: Icon(Icons.phone_android, color: Colors.red),
                        value: tempFilters.contains('RECARGA CLARO'),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              tempFilters.add('RECARGA CLARO');
                            } else {
                              tempFilters.remove('RECARGA CLARO');
                            }
                          });
                        },
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No hay comprobantes escaneados',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
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

  Widget _buildReceiptCard(Receipt receipt) {
    IconData typeIcon;
    Color headerColor;

    switch (receipt.tipo) {
      case 'Retiro':
        typeIcon = Icons.money_off;
        headerColor = Colors.orange.shade100;
        break;
      case 'EFECTIVO MOVIL':
        typeIcon = Icons.mobile_friendly;
        headerColor = Colors.purple.shade100;
        break;
      case 'DEPOSITO':
        typeIcon = Icons.savings;
        headerColor = Colors.green.shade100;
        break;
      case 'RECARGA CLARO':
        typeIcon = Icons.phone_android;
        headerColor = Colors.red.shade100;
        break;
      default: // Pago de Servicio u otros
        typeIcon = Icons.payment;
        headerColor = Colors.blue.shade100;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReceiptDetails(receipt),
        child: Column(
          children: [
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
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transacción #${receipt.nroTransaccion}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\$${receipt.valorTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Corresponsal: ${receipt.corresponsal}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),

                  if (receipt.tipo == 'Pago de Servicio' ||
                      receipt.tipo == 'Retiro')
                    SizedBox(height: 4),

                  if (receipt.tipo == 'Pago de Servicio' ||
                      receipt.tipo == 'Retiro')
                    Text(
                      'Local: ${receipt.local}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),

                  if (receipt.tipo == 'Pago de Servicio' ||
                      receipt.tipo == 'Retiro')
                    SizedBox(height: 4),

                  if (receipt.tipo == 'Pago de Servicio' ||
                      receipt.tipo == 'Retiro')
                    Text(
                      'Cuenta: ${receipt.tipoCuenta}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),

                  if (receipt.tipo == 'EFECTIVO MOVIL' &&
                      receipt.nroAutorizacion.isNotEmpty)
                    SizedBox(height: 4),

                  if (receipt.tipo == 'EFECTIVO MOVIL' &&
                      receipt.nroAutorizacion.isNotEmpty)
                    Text(
                      'Autorización: ${receipt.nroAutorizacion}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),

                  if (receipt.tipo == 'RECARGA CLARO' &&
                      receipt.numTelefonico.isNotEmpty)
                    SizedBox(height: 4),

                  if (receipt.tipo == 'RECARGA CLARO' &&
                      receipt.numTelefonico.isNotEmpty)
                    Text(
                      'Teléfono: ${receipt.numTelefonico}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

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

                    _buildDetailRow('Banco', receipt.banco),
                    _buildDetailRow('Fecha', receipt.fecha),
                    _buildDetailRow('Hora', receipt.hora),
                    _buildDetailRow('Tipo', receipt.tipo),
                    _buildDetailRow('Transacción', receipt.nroTransaccion),

                    if (receipt.tipo == 'Pago de Servicio' ||
                        receipt.tipo == 'Retiro' ||
                        receipt.tipo == 'DEPOSITO')
                      _buildDetailRow('Control', receipt.nroControl),

                    if (receipt.tipo == 'Pago de Servicio' ||
                        receipt.tipo == 'Retiro')
                      _buildDetailRow('Local', receipt.local),

                    if (receipt.fechaAlternativa.isNotEmpty)
                      _buildDetailRow('Fecha Alt.', receipt.fechaAlternativa),

                    _buildDetailRow('Corresponsal', receipt.corresponsal),

                    if (receipt.tipo == 'Pago de Servicio' ||
                        receipt.tipo == 'Retiro')
                      _buildDetailRow('Tipo Cuenta', receipt.tipoCuenta),

                    if (receipt.tipo == 'EFECTIVO MOVIL' &&
                        receipt.nroAutorizacion.isNotEmpty)
                      _buildDetailRow(
                        'Nro. Autorización',
                        receipt.nroAutorizacion,
                      ),

                    if (receipt.tipo == 'RECARGA CLARO')
                      _buildDetailRow('Ilim. Claro', receipt.ilimClaro),

                    if (receipt.tipo == 'RECARGA CLARO' &&
                        receipt.numTelefonico.isNotEmpty)
                      _buildDetailRow('Núm. Telefónico', receipt.numTelefonico),

                    _buildDetailRow(
                      'Valor Total',
                      '\$${receipt.valorTotal.toStringAsFixed(2)}',
                    ),

                    SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(
                        'Texto Completo',
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
                          child: Text(receipt.fullText),
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
                provider.setContext(
                  context,
                ); // Asegurarse de establecer el contexto

                try {
                  final success = await provider.deleteReceipt(
                    receipt.nroTransaccion,
                  );

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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
}
