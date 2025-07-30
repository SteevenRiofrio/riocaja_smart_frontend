import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riocaja_smart/models/receipt.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';
import 'package:riocaja_smart/services/api_service.dart';
import 'package:riocaja_smart/providers/auth_provider.dart';
import 'package:riocaja_smart/screens/login_screen.dart';
import 'package:riocaja_smart/screens/edit_receipt_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  Set<String> _selectedFilters = {}; // vacío significa "Todos"
  String _selectedCorresponsal = 'todos'; // NUEVO: Filtro por corresponsal
  DateTime? _selectedDate; // Filtro por fecha
  bool _sortDescending = true; // Ordenar de mayor a menor hora (descendente)
  
  // Lista de tipos disponibles que se actualiza dinámicamente
  Set<String> _availableTypes = {};
  
  // NUEVO: Lista de corresponsales disponibles
  Set<String> _availableCorresponsales = {};

  // 1. AGREGAR VARIABLE Y CONTROLADOR
  String _searchTransactionNumber = ''; // NUEVO: Filtro por número de transacción
  final TextEditingController _searchController = TextEditingController(); // NUEVO: Controlador para el campo de búsqueda

  // Variables adicionales para búsquedas recientes
  List<String> _recentSearches = [];

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

      // ACTUALIZAR TIPOS Y CORRESPONSALES DISPONIBLES DINÁMICAMENTE
      _updateAvailableFilters(receipts);

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

  // MEJORADO: Método para actualizar tipos y corresponsales disponibles dinámicamente
  void _updateAvailableFilters(List<Receipt> receipts) {
    Set<String> types = {};
    Set<String> corresponsales = {};
    
    for (var receipt in receipts) {
      if (receipt.tipo.isNotEmpty) {
        types.add(receipt.tipo);
      }
      
      // NUEVO: Recopilar corresponsales disponibles
      if (receipt.codigoCorresponsal != null && receipt.codigoCorresponsal!.isNotEmpty) {
        corresponsales.add(receipt.codigoCorresponsal!);
      }
    }
    
    // CLAVE: Solo actualizar si realmente cambió algo
    if (!_setEquals(_availableTypes, types) || !_setEquals(_availableCorresponsales, corresponsales)) {
      setState(() {
        _availableTypes = types;
        _availableCorresponsales = corresponsales;
        
        // Limpiar filtros que ya no existen en los datos
        _selectedFilters.removeWhere((filter) => !_availableTypes.contains(filter));
        
        // Limpiar filtro de corresponsal si ya no existe
        if (_selectedCorresponsal != 'todos' && !_availableCorresponsales.contains(_selectedCorresponsal)) {
          _selectedCorresponsal = 'todos';
        }
      });
      
      print('Tipos de comprobantes actualizados: $_availableTypes');
      print('Corresponsales disponibles: $_availableCorresponsales');
    }
  }

  // Método para comparar sets sin modificar el estado
  bool _setEquals<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  void _addToRecentSearches(String search) {
    if (search.isNotEmpty && !_recentSearches.contains(search)) {
      setState(() {
        _recentSearches.insert(0, search);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.take(5).toList();
        }
      });
    }
  }

  // NUEVO MÉTODO: Mostrar diálogo de búsqueda
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempSearchText = _searchTransactionNumber;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text('Buscar Comprobante'),
            ],
          ),
          content: TextField(
            controller: TextEditingController(text: tempSearchText),
            decoration: InputDecoration(
              hintText: 'Ingrese N° de transacción',
              prefixIcon: Icon(Icons.receipt_long),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
            ),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              tempSearchText = value;
            },
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchTransactionNumber = '';
                });
                Navigator.of(context).pop();
              },
              child: Text('Limpiar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.text = tempSearchText;
                  _searchTransactionNumber = tempSearchText;
                  if (tempSearchText.isNotEmpty) {
                    _addToRecentSearches(tempSearchText);
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  // ALTERNATIVA: Bottom Sheet más elegante
  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.search, color: Theme.of(context).primaryColor, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Buscar Comprobante',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Número de Transacción',
                  hintText: 'Ej: 1234567890',
                  prefixIcon: Icon(Icons.receipt_long),
                  suffixIcon: _searchTransactionNumber.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchTransactionNumber = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  setState(() {
                    _searchTransactionNumber = value;
                  });
                },
                autofocus: true,
              ),
              SizedBox(height: 20),
              if (_recentSearches.isNotEmpty) ...[
                Text(
                  'Búsquedas recientes:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _recentSearches.take(3).map((search) =>
                    ActionChip(
                      label: Text(search),
                      onPressed: () {
                        setState(() {
                          _searchController.text = search;
                          _searchTransactionNumber = search;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ).toList(),
                ),
                SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchTransactionNumber = '';
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Limpiar'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_searchTransactionNumber.isNotEmpty) {
                          _addToRecentSearches(_searchTransactionNumber);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Buscar'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptsProvider>(
      builder: (context, receiptsProvider, child) {
        final _allReceipts = receiptsProvider.receipts;
        final _isProviderLoading = receiptsProvider.isLoading;

        if (!_isProviderLoading && _allReceipts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateAvailableFilters(_allReceipts);
          });
        }

        final _receipts = _filterReceipts(_allReceipts);

        return Scaffold(
          appBar: AppBar(
            title: Text('Historial de Comprobantes'),
            actions: [
              // Barra de búsqueda pequeña y compacta, sin ícono de lupa
              Container(
                width: 120, // Más pequeña
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'N° transacción',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    // Sin prefixIcon
                    suffixIcon: _searchTransactionNumber.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 14),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchTransactionNumber = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: TextStyle(fontSize: 11),
                  onChanged: (value) {
                    setState(() {
                      _searchTransactionNumber = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: _availableTypes.isNotEmpty ? _showFilterOptions : null,
                tooltip: _availableTypes.isEmpty 
                    ? 'No hay comprobantes para filtrar'
                    : 'Filtros',
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.hasRole('admin') || authProvider.hasRole('asesor')) {
                    return IconButton(
                      icon: Icon(Icons.person_search),
                      onPressed: _availableCorresponsales.isNotEmpty ? _showCorresponsalFilter : null,
                      tooltip: 'Filtrar por corresponsal',
                    );
                  }
                  return SizedBox.shrink();
                },
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

  // MEJORADO: Método para mostrar los filtros activos
  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // NUEVO: Chip para búsqueda por número de transacción
    if (_searchTransactionNumber.isNotEmpty) {
      filterChips.add(
        Chip(
          label: Text('Buscar: $_searchTransactionNumber'),
          avatar: Icon(Icons.search, size: 16),
          onDeleted: () {
            setState(() {
              _searchController.clear();
              _searchTransactionNumber = '';
            });
          },
        ),
      );
    }

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

    // NUEVO: Filtro por corresponsal
    if (_selectedCorresponsal != 'todos') {
      filterChips.add(
        Chip(
          label: Text('Corresponsal: $_selectedCorresponsal'),
          avatar: Icon(Icons.person, size: 16),
          onDeleted: () {
            setState(() {
              _selectedCorresponsal = 'todos';
            });
          },
        ),
      );
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

  // NUEVO: Método para mostrar filtro de corresponsal
  void _showCorresponsalFilter() {
    if (_availableCorresponsales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay corresponsales disponibles para filtrar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.person_search, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Text(
                      'Filtrar por Corresponsal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCorresponsal = 'todos';
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Todos'),
                    ),
                  ],
                ),
              ),
              Divider(),
              
              // Mostrar información sobre corresponsales disponibles
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Corresponsales con comprobantes (${_availableCorresponsales.length}):',
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
                    // Opción "Todos"
                    ListTile(
                      leading: Icon(Icons.all_inclusive, color: Colors.green.shade700),
                      title: Text('Todos los corresponsales'),
                      trailing: _selectedCorresponsal == 'todos' 
                          ? Icon(Icons.check, color: Colors.green) 
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCorresponsal = 'todos';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    Divider(),
                    
                    // MOSTRAR CORRESPONSALES DISPONIBLES DINÁMICAMENTE
                    ..._availableCorresponsales.map((codigo) {
                      // Contar comprobantes para este corresponsal
                      final receiptsProvider = Provider.of<ReceiptsProvider>(context, listen: false);
                      final count = receiptsProvider.receipts
                          .where((r) => r.codigoCorresponsal == codigo)
                          .length;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            codigo.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('Corresponsal $codigo'),
                        subtitle: Text('$count comprobante${count != 1 ? 's' : ''}'),
                        trailing: _selectedCorresponsal == codigo 
                            ? Icon(Icons.check, color: Colors.green) 
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCorresponsal = codigo;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                    
                    // Mensaje si no hay corresponsales disponibles
                    if (_availableCorresponsales.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No hay corresponsales para filtrar',
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
            ],
          ),
        );
      },
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

  // MEJORADO: Método para filtrar comprobantes incluyendo corresponsal
  List<Receipt> _filterReceipts(List<Receipt> receipts) {
    List<Receipt> filteredReceipts = receipts;

    // Filtrar por tipos seleccionados
    if (_selectedFilters.isNotEmpty) {
      filteredReceipts = filteredReceipts
          .where((receipt) => _selectedFilters.contains(receipt.tipo))
          .toList();
    }

    // NUEVO: Filtrar por número de transacción
    if (_searchTransactionNumber.isNotEmpty) {
      filteredReceipts = filteredReceipts
          .where((receipt) => receipt.nroTransaccion
              .toLowerCase()
              .contains(_searchTransactionNumber.toLowerCase()))
          .toList();
    }

    // NUEVO: Filtrar por corresponsal
    if (_selectedCorresponsal != 'todos') {
      filteredReceipts = filteredReceipts.where((receipt) => 
          receipt.codigoCorresponsal == _selectedCorresponsal).toList();
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
            _selectedFilters.isNotEmpty || 
            _selectedDate != null || 
            _selectedCorresponsal != 'todos' ||
            _searchTransactionNumber.isNotEmpty
              ? 'No hay comprobantes que coincidan con los filtros seleccionados'
              : 'No hay comprobantes escaneados',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          if (_selectedFilters.isNotEmpty || 
              _selectedDate != null || 
              _selectedCorresponsal != 'todos' ||
              _searchTransactionNumber.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilters.clear();
                  _selectedDate = null;
                  _selectedCorresponsal = 'todos';
                  _searchController.clear();
                  _searchTransactionNumber = '';
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

// CORREGIDO: Card de comprobante - SOLO ADMIN VE INFORMACIÓN DEL CORRESPONSAL
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
                  Expanded(
                    child: Text(
                      receipt.tipo,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  // SOLO ADMIN: Mostrar código del corresponsal en el header
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if ((authProvider.hasRole('admin') || authProvider.hasRole('asesor')) && 
                          receipt.codigoCorresponsal != null && receipt.codigoCorresponsal!.isNotEmpty) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.grey.shade700,
                              ),
                              SizedBox(width: 4),
                              Text(
                                receipt.codigoCorresponsal!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  Text(
                    '${receipt.fecha} ${receipt.hora}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
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
                  
                  // SOLO ADMIN/OPERADOR: Mostrar información del corresponsal
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if ((authProvider.hasRole('admin') || authProvider.hasRole('asesor')) && 
                          receipt.codigoCorresponsal != null && receipt.codigoCorresponsal!.isNotEmpty) {
                        return Container(
                          margin: EdgeInsets.only(top: 12),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: Row(
                            children: [
                              // Icono del corresponsal
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  receipt.codigoCorresponsal!.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Código del corresponsal
                                    Text(
                                      'Corresponsal: ${receipt.codigoCorresponsal}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    // Nombre del corresponsal (si está disponible)
                                    if (receipt.nombreCorresponsal != null && receipt.nombreCorresponsal!.isNotEmpty)
                                      Text(
                                        'Escaneado por: ${receipt.nombreCorresponsal}',
                                        style: TextStyle(
                                          color: Colors.indigo.shade600,
                                          fontSize: 12,
                                        ),
                                      )
                                    else if (receipt.usuarioId != null && receipt.usuarioId!.isNotEmpty)
                                      Text(
                                        'Escaneado por: ${receipt.usuarioId}',
                                        style: TextStyle(
                                          color: Colors.indigo.shade600,
                                          fontSize: 12,
                                        ),
                                      )
                                    else if (receipt.usuarioId != null)
                                      Text(
                                        'Usuario ID: ${receipt.usuarioId}',
                                        style: TextStyle(
                                          color: Colors.indigo.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Icono indicador
                              Icon(
                                Icons.admin_panel_settings,
                                color: Colors.indigo.shade400,
                                size: 18,
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox.shrink(); // No mostrar nada para usuarios normales
                    },
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
                  // ✅ SOLO MOSTRAR BOTÓN ELIMINAR PARA ADMIN Y ASESOR
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final userRole = authProvider.user?.rol ?? '';
                      
                      // 🗑️ SOLO Admin y Asesor ven el botón Eliminar en las tarjetas
                      if (userRole == 'admin' || userRole == 'asesor') {
                        return TextButton.icon(
                          icon: Icon(Icons.delete_outline, size: 18),
                          label: Text('Eliminar'),
                          onPressed: () => _confirmDelete(receipt),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: Colors.red,
                          ),
                        );
                      }
                      
                      // 📝 CNB no ve ningún botón en las tarjetas
                      else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CORREGIDO: Detalles del comprobante - SOLO ADMIN VE INFORMACIÓN DEL CORRESPONSAL
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
                    
                    // Header con icono del tipo
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getColorForType(receipt.tipo),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_getIconForType(receipt.tipo), size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detalles del Comprobante',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                receipt.tipo,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),

                    // INFORMACIÓN DEL COMPROBANTE
                    Text(
                      'Información de la Transacción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow('Fecha', receipt.fecha),
                    _buildDetailRow('Hora', receipt.hora),
                    _buildDetailRow('Tipo', receipt.tipo),
                    _buildDetailRow('Transacción', receipt.nroTransaccion),
                    _buildDetailRow(
                      'Valor Total',
                      '\$${receipt.valorTotal.toStringAsFixed(2)}',
                    ),

                    // SOLO ADMIN/OPERADOR: INFORMACIÓN DEL CORRESPONSAL
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if ((authProvider.hasRole('admin') || authProvider.hasRole('asesor')) && 
                            receipt.codigoCorresponsal != null && receipt.codigoCorresponsal!.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 16),
                              Divider(),
                              
                              // Badge de "Solo Admin"
                              Row(
                                children: [
                                  Icon(Icons.admin_panel_settings, 
                                       color: Colors.indigo.shade700, 
                                       size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Información del Corresponsal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Solo Admin',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // Card especial para el corresponsal
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.indigo.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.indigo.shade100,
                                          child: Text(
                                            receipt.codigoCorresponsal!.substring(0, 1).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo.shade700,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Código: ${receipt.codigoCorresponsal}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.indigo.shade700,
                                                ),
                                              ),
                                              if (receipt.nombreCorresponsal != null && receipt.nombreCorresponsal!.isNotEmpty)
                                                Text(
                                                  'Nombre: ${receipt.nombreCorresponsal}',
                                                  style: TextStyle(
                                                    color: Colors.indigo.shade600,
                                                    fontSize: 14,
                                                  ),
                                                )
                                              else if (receipt.usuarioId != null && receipt.usuarioId!.isNotEmpty)
                                                Text(
                                                  'Usuario ID: ${receipt.usuarioId}',
                                                  style: TextStyle(
                                                    color: Colors.indigo.shade600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.verified_user,
                                          color: Colors.indigo.shade400,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                    if (receipt.usuarioId != null) ...[
                                      SizedBox(height: 8),
                                      Divider(color: Colors.indigo.shade200),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.fingerprint, 
                                               color: Colors.indigo.shade600, 
                                               size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'ID de Usuario: ${receipt.usuarioId}',
                                            style: TextStyle(
                                              color: Colors.indigo.shade600,
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return SizedBox.shrink(); // No mostrar nada para usuarios normales
                      },
                    ),

                    SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(
                        'Ver texto completo escaneado',
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

                    // 🔧 BOTONES CON PERMISOS ESPECÍFICOS
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final userRole = authProvider.user?.rol ?? '';
                        
                        return Column(
                          children: [
                            // 🔧 BOTÓN DE EDITAR (Admin y CNB)
                            if (userRole == 'admin' || userRole == 'cnb') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context); // Cerrar detalles
                                    
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditReceiptScreen(receipt: receipt),
                                      ),
                                    );
                                    
                                    // Si se editó exitosamente, recargar lista
                                    if (result == true) {
                                      final provider = Provider.of<ReceiptsProvider>(context, listen: false);
                                      provider.setContext(context);
                                      await provider.loadReceipts();
                                    }
                                  },
                                  icon: Icon(Icons.edit, color: Colors.white),
                                  label: Text('✏️ Editar Comprobante', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                            ],
                            
                            // 🗑️ BOTÓN DE ELIMINAR (Admin y Asesor)
                            if (userRole == 'admin' || userRole == 'asesor') ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context); // Cerrar detalles
                                    _confirmDelete(receipt);
                                  },
                                  icon: Icon(Icons.delete_outline, color: Colors.white),
                                  label: Text('🗑️ Eliminar Comprobante', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                            
                            // 📋 Si no tiene permisos, mostrar mensaje informativo
                            if (userRole != 'admin' && userRole != 'asesor' && userRole != 'cnb') ...[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ℹ️ Sin permisos para editar o eliminar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
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
      case 'RECARGA CLARO':
      case 'RECARGA':
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
      case 'RECARGA CLARO':
      case 'RECARGA':
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
      case 'RECARGA CLARO':
      case 'RECARGA':
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
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}