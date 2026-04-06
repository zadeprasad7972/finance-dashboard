import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await ApiService.getDashboard();
      setState(() { _summary = s; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    if (_error != null) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ],
    ));

    final s = _summary!;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                  child: Text((auth.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome, ${auth.username}!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_roleDescription(auth.role),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Summary cards row 1
            Row(children: [
              _SummaryCard('Total Income', fmt.format(s.totalIncome), Icons.trending_up, Colors.green),
              const SizedBox(width: 12),
              _SummaryCard('Total Expenses', fmt.format(s.totalExpenses), Icons.trending_down, Colors.red),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _SummaryCard('Net Balance', fmt.format(s.netBalance),
                  s.netBalance >= 0 ? Icons.account_balance : Icons.warning,
                  s.netBalance >= 0 ? Colors.blue : Colors.orange),
              const SizedBox(width: 12),
              _SummaryCard('Total Records', s.totalRecords.toString(), Icons.receipt_long, Colors.purple),
            ]),
            const SizedBox(height: 20),

            // Monthly Trends
            if (s.monthlyTrends.isNotEmpty) ...[
              Row(children: [
                const Text('Monthly Trends', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                _Legend(Colors.green, 'Income'),
                const SizedBox(width: 12),
                _Legend(Colors.red, 'Expense'),
              ]),
              const SizedBox(height: 12),
              _MonthlyChart(trends: s.monthlyTrends),
              const SizedBox(height: 20),
            ],

            // Category Breakdown
            if (s.categoryTotals.isNotEmpty) ...[
              const Text('Category Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _CategoryChart(categories: s.categoryTotals),
              const SizedBox(height: 20),
            ],

            // Recent Activity
            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (s.recentActivity.isEmpty)
              const Center(child: Text('No recent activity', style: TextStyle(color: Colors.grey)))
            else
              ...s.recentActivity.map((r) => _RecentItem(record: r, fmt: fmt)),

            // Role info banner for VIEWER
            if (auth.role == 'VIEWER') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('You have view-only access. Contact an admin to request elevated permissions.',
                      style: TextStyle(color: Colors.blue, fontSize: 12))),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _roleDescription(String? role) => switch (role) {
    'ADMIN' => 'Full access — manage records, users & dashboard',
    'ANALYST' => 'Can view & manage financial records',
    _ => 'View-only access to dashboard & records',
  };
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 3, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 12)),
  ]);
}

class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _SummaryCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _MonthlyChart extends StatelessWidget {
  final List<MonthlyTrend> trends;
  const _MonthlyChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final months = trends.map((t) => '${t.month}/${t.year}').toSet().toList();
    final incomeData = <FlSpot>[];
    final expenseData = <FlSpot>[];

    for (int i = 0; i < months.length; i++) {
      final parts = months[i].split('/');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      final income = trends.where((t) => t.month == month && t.year == year && t.type == 'INCOME')
          .fold(0.0, (s, t) => s + t.amount);
      final expense = trends.where((t) => t.month == month && t.year == year && t.type == 'EXPENSE')
          .fold(0.0, (s, t) => s + t.amount);
      incomeData.add(FlSpot(i.toDouble(), income));
      expenseData.add(FlSpot(i.toDouble(), expense));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFF334155), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
              getTitlesWidget: (v, _) => Text('\$${(v / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(color: Colors.grey, fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= 0 && i < months.length) {
                  return Text(months[i], style: const TextStyle(color: Colors.grey, fontSize: 9));
                }
                return const Text('');
              })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: incomeData, color: Colors.green, barWidth: 2,
              dotData: const FlDotData(show: true)),
          LineChartBarData(spots: expenseData, color: Colors.red, barWidth: 2,
              dotData: const FlDotData(show: true)),
        ],
      )),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<String, double> categories;
  const _CategoryChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
    final entries = categories.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        SizedBox(
          height: 160, width: 160,
          child: PieChart(PieChartData(
            sections: entries.asMap().entries.map((e) => PieChartSectionData(
              value: e.value.value,
              color: colors[e.key % colors.length],
              title: '${(e.value.value / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(color: Colors.white, fontSize: 11),
              radius: 60,
            )).toList(),
          )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(
                    color: colors[e.key % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.key,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis)),
                Text('\$${e.value.value.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]),
            )).toList(),
          ),
        ),
      ]),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final FinancialRecord record;
  final NumberFormat fmt;
  const _RecentItem({required this.record, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == 'INCOME';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isIncome ? Colors.green : Colors.red).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          Text(record.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
        Text(fmt.format(record.amount),
            style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
