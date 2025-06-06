// lib/widgets/report_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final DateTime selectedDate;
  final VoidCallback onShareReport;
  final VoidCallback onGeneratePDF;

  const ReportSummaryWidget({
    Key? key,
    required this.reportData,
    required this.selectedDate,
    required this.onShareReport,
    required this.onGeneratePDF,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final incomes = reportData['incomes'] as Map<dynamic, dynamic>? ?? {};
    final incomeCount = reportData['incomeCount'] as Map<dynamic, dynamic>? ?? {};
    final expenses = reportData['expenses'] as Map<dynamic, dynamic>? ?? {};
    final expenseCount = reportData['expenseCount'] as Map<dynamic, dynamic>? ?? {};
    final totalIncomes = reportData['totalIncomes'] as double? ?? 0.0;
    final totalExpenses = reportData['totalExpenses'] as double? ?? 0.0;
    final totalIncomeCount = reportData['totalIncomeCount'] as int? ?? 0;
    final totalExpenseCount = reportData['totalExpenseCount'] as int? ?? 0;
    final saldoEnCaja = reportData['saldoEnCaja'] as double? ?? 0.0;
    final count = reportData['count'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del reporte
            _buildReportHeader(),
            Divider(),

            if (count == 0) ...[
              _buildEmptyState(),
            ] else ...[
              // Secciones de ingresos y egresos
              if (incomes.isNotEmpty) ...[
                _buildIncomeSection(incomes, incomeCount, totalIncomes, totalIncomeCount),
                SizedBox(height: 16),
              ],

              if (expenses.isNotEmpty) ...[
                _buildExpenseSection(expenses, expenseCount, totalExpenses, totalExpenseCount),
                SizedBox(height: 16),
              ],

              // Saldo en caja
              _buildBalanceSection(saldoEnCaja),
              SizedBox(height: 16),

              // Total de transacciones
              _buildTransactionCount(count),
            ],

            SizedBox(height: 16),

            // Botones de acción
            if (count > 0) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'REPORTE DEL DÍA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          DateFormat('dd/MM/yyyy').format(selectedDate),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text('NO HAY TRANSACCIONES EN ESTA FECHA'),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSection(Map incomes, Map incomeCount, double totalIncomes, int totalIncomeCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INGRESOS EFECTIVO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green.shade700,
          ),
        ),
        SizedBox(height: 8),

        // Header de tabla
        _buildTableHeader(),

        // Items de ingresos
        ...incomes.entries.map((entry) => _buildTableRow(
          entry.key.toString().toUpperCase(),
          incomeCount[entry.key] ?? 0,
          (entry.value as num).toDouble(),
        )).toList(),

        // Total ingresos
        Divider(),
        _buildTableRow(
          'TOTAL INGRESOS',
          totalIncomeCount,
          totalIncomes,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildExpenseSection(Map expenses, Map expenseCount, double totalExpenses, int totalExpenseCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EGRESOS EFECTIVO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.red.shade700,
          ),
        ),
        SizedBox(height: 8),

        // Header de tabla
        _buildTableHeader(),

        // Items de egresos
        ...expenses.entries.map((entry) => _buildTableRow(
          entry.key.toString().toUpperCase(),
          expenseCount[entry.key] ?? 0,
          (entry.value as num).toDouble(),
        )).toList(),

        // Total egresos
        Divider(),
        _buildTableRow(
          'TOTAL EGRESOS',
          totalExpenseCount,
          totalExpenses,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('CANT', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('VALOR', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTableRow(String tipo, int cantidad, double valor, {bool isBold = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              tipo,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${valor.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(double saldoEnCaja) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: saldoEnCaja >= 0 ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: saldoEnCaja >= 0 ? Colors.green.shade300 : Colors.red.shade300,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                saldoEnCaja >= 0 ? Icons.account_balance_wallet : Icons.warning,
                color: saldoEnCaja >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'SALDO EN CAJA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: saldoEnCaja >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          Text(
            '\$${saldoEnCaja.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: saldoEnCaja >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCount(int count) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Text(
                'TOTAL TRANSACCIONES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onShareReport,
            icon: Icon(Icons.share),
            label: Text('Compartir Reporte de Texto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onGeneratePDF,
            icon: Icon(Icons.picture_as_pdf),
            label: Text('Generar y Compartir PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade700),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}