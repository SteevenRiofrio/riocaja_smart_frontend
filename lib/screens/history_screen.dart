import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/services/api_service.dart'; // Asegúrate de importar tu ApiService

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'Todos'; // Filtro seleccionado
  
@override
void initState() {
  super.initState();
  print('HistoryScreen initState - cargando comprobantes...');
  _loadReceipts();
}

Future<void> _loadReceipts() async {
  setState(() => _isLoading = true);
  
  try {
    print('HistoryScreen: Intentando cargar comprobantes desde el provider...');
    
    // Obtener información sobre la URL del API service
    final apiService = ApiService(); // Necesitarás importar esta clase
    print('HistoryScreen: URL del API: ${apiService.baseUrl}/receipts/');
    
    await Provider.of<ReceiptsProvider>(context, listen: false).loadReceipts();
    final receipts = Provider.of<ReceiptsProvider>(context, listen: false).receipts;
    print('HistoryScreen: Se cargaron ${receipts.length} comprobantes');
    
    if (receipts.isEmpty) {
      print('HistoryScreen: La lista de comprobantes está vacía');
    } else {
      // Mostrar el primer comprobante como ejemplo
      print('HistoryScreen: Muestra del primer comprobante: ${receipts[0].nroTransaccion}');
    }
  } catch (e) {
    print('HistoryScreen: Error al cargar comprobantes: $e');
    // Mostrar más detalles sobre el error
    print('HistoryScreen: Tipo de error: ${e.runtimeType}');
    print('HistoryScreen: Detalles completos: $e');
  }
  
  setState(() => _isLoading = false);
}
  
   @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptsProvider>(
      builder: (context, receiptsProvider, child) {
        final _allReceipts = receiptsProvider.receipts;
        final _isProviderLoading = receiptsProvider.isLoading;
        
        // Filtrar los comprobantes según el filtro seleccionado
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
                icon: Icon(Icons.refresh),
                onPressed: _loadReceipts,
              ),
            ],
          ),
          body: _isLoading || _isProviderLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Mostrar el filtro activo
                    if (_selectedFilter != 'Todos')
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.grey.shade200,
                        child: Row(
                          children: [
                            Text('Filtro: $_selectedFilter', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                            Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = 'Todos';
                                });
                              },
                              child: Text('Limpiar'),
                            )
                          ],
                        ),
                      ),
                    // Lista de comprobantes
                    Expanded(
                      child: _receipts.isEmpty
                          ? _buildEmptyState()
                          : _buildReceiptsList(_receipts),
                    ),
                  ],
                ),
        );
      },
    );
  }
  
  // Método para filtrar comprobantes
  List<Receipt> _filterReceipts(List<Receipt> receipts) {
    if (_selectedFilter == 'Todos') {
      return receipts;
    }
    
    return receipts.where((receipt) {
      return receipt.tipo == _selectedFilter;
    }).toList();
  }
  
  // Mostrar opciones de filtro
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Todos los comprobantes'),
                leading: Icon(Icons.receipt_long),
                selected: _selectedFilter == 'Todos',
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Todos';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Pagos de Servicio'),
                leading: Icon(Icons.payment, color: Colors.blue),
                selected: _selectedFilter == 'Pago de Servicio',
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Pago de Servicio';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Retiros'),
                leading: Icon(Icons.money_off, color: Colors.orange),
                selected: _selectedFilter == 'Retiro',
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Retiro';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No hay comprobantes escaneados',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
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

  Widget _buildReceiptCard(Receipt receipt) {
      // Determinar el icono y color según el tipo de comprobante
  IconData typeIcon;
  Color headerColor;
  
  if (receipt.tipo == 'Retiro') {
    typeIcon = Icons.money_off; // Icono para retiros
    headerColor = Colors.orange.shade100; // Color para retiros
  } else {
    // Para Pago de Servicio u otros tipos no reconocidos
    typeIcon = Icons.payment; // Icono para pagos de servicio
    headerColor = Colors.blue.shade100; // Color para pagos
  }
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReceiptDetails(receipt),
        child: Column(
          children: [
            // Encabezado con tipo y fecha
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Text(
                  '${receipt.fecha} ${receipt.hora}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
            
            // Contenido principal
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
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
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
                  Text('Corresponsal: ${receipt.corresponsal}', 
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Local: ${receipt.local}', 
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Cuenta: ${receipt.tipoCuenta}', 
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
            ),
            
            // Pie del card con actions
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
                    // Encabezado
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
                    
                    // Información general
                    _buildDetailRow('Banco', receipt.banco),
                    _buildDetailRow('Fecha', receipt.fecha),
                    _buildDetailRow('Hora', receipt.hora),
                    _buildDetailRow('Tipo', receipt.tipo),
                    _buildDetailRow('Transacción', receipt.nroTransaccion),
                    _buildDetailRow('Control', receipt.nroControl),
                    _buildDetailRow('Local', receipt.local),
                    _buildDetailRow('Fecha Alt.', receipt.fechaAlternativa),
                    _buildDetailRow('Corresponsal', receipt.corresponsal),
                    _buildDetailRow('Tipo Cuenta', receipt.tipoCuenta),
                    _buildDetailRow('Valor Total', '\$${receipt.valorTotal.toStringAsFixed(2)}'),
                    
                    // Texto completo
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
                    
                    // Acciones
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
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete(Receipt receipt) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Comprobante'),
          content: Text('¿Estás seguro de eliminar este comprobante? Esta acción no se puede deshacer.'),
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
                final provider = Provider.of<ReceiptsProvider>(context, listen: false);
                
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
                    SnackBar(
                      content: Text('Error: $e'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}