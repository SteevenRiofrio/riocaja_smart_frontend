import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riocaja_smart/providers/receipts_provider.dart';

class DashboardSummary extends StatefulWidget {
  @override
  _DashboardSummaryState createState() => _DashboardSummaryState();
}

class _DashboardSummaryState extends State<DashboardSummary> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final receiptsProvider = Provider.of<ReceiptsProvider>(
      context,
      listen: false,
    );

    setState(() => _isLoading = true);

    try {
      // Obtener el reporte para la fecha actual
      final reportData = await receiptsProvider.generateClosingReport(
        DateTime.now(),
      );

      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report data: $e');
      setState(() {
        _reportData = {
          'summary': {},
          'total': 0.0,
          'date': DateTime.now(),
          'count': 0,
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si está cargando
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Si no hay datos
    if (_reportData.isEmpty || (_reportData['count'] as int) == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.insert_chart, size: 48, color: Colors.grey.shade400),
              SizedBox(height: 8),
              Text(
                'No hay datos para mostrar hoy',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Mostrar el resumen
    final summary = _reportData['summary'] as Map<String, dynamic>;
    final total = _reportData['total'] as double;
    final count = _reportData['count'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del día',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Transacciones',
                  count.toString(),
                  Icons.receipt,
                  Colors.blue.shade100,
                ),
                _buildSummaryItem(
                  'Total',
                  '\$${total.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.green.shade100,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Distribución', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...summary.entries.map((entry) {
              IconData icon;
              Color iconColor;

              if (entry.key == 'Retiro') {
                icon = Icons.money_off;
                iconColor = Colors.orange;
              } else {
                // Para Pago de Servicio u otros tipos
                icon = Icons.payment;
                iconColor = Colors.blue;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: iconColor),
                    SizedBox(width: 8),
                    Text(entry.key),
                    Spacer(),
                    Text('\$${(entry.value as num).toStringAsFixed(2)}'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
