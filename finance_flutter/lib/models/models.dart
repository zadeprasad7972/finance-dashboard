class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String status;

  User({required this.id, required this.username, required this.email,
        required this.role, required this.status});

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'], username: j['username'], email: j['email'],
    role: j['role'], status: j['status'],
  );
}

class FinancialRecord {
  final int id;
  final double amount;
  final String type;
  final String category;
  final String date;
  final String? notes;
  final String? createdBy;

  FinancialRecord({required this.id, required this.amount, required this.type,
                   required this.category, required this.date, this.notes, this.createdBy});

  factory FinancialRecord.fromJson(Map<String, dynamic> j) => FinancialRecord(
    id: j['id'],
    amount: (j['amount'] as num).toDouble(),
    type: j['type'],
    category: j['category'],
    date: j['date'],
    notes: j['notes'],
    createdBy: j['createdBy'],
  );
}

class PagedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  PagedResponse({required this.content, required this.page, required this.size,
                 required this.totalPages, required this.totalElements});
}

class DashboardSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final int totalRecords;
  final Map<String, double> categoryTotals;
  final List<FinancialRecord> recentActivity;
  final List<MonthlyTrend> monthlyTrends;

  DashboardSummary({required this.totalIncome, required this.totalExpenses,
                    required this.netBalance, required this.totalRecords,
                    required this.categoryTotals, required this.recentActivity,
                    required this.monthlyTrends});

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
    totalIncome: (j['totalIncome'] as num).toDouble(),
    totalExpenses: (j['totalExpenses'] as num).toDouble(),
    netBalance: (j['netBalance'] as num).toDouble(),
    totalRecords: (j['totalRecords'] as num?)?.toInt() ?? 0,
    categoryTotals: (j['categoryTotals'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble())),
    recentActivity: (j['recentActivity'] as List)
        .map((e) => FinancialRecord.fromJson(e)).toList(),
    monthlyTrends: (j['monthlyTrends'] as List)
        .map((e) => MonthlyTrend.fromJson(e)).toList(),
  );
}

class MonthlyTrend {
  final int year;
  final int month;
  final String type;
  final double amount;

  MonthlyTrend({required this.year, required this.month,
                required this.type, required this.amount});

  factory MonthlyTrend.fromJson(Map<String, dynamic> j) => MonthlyTrend(
    year: j['year'], month: j['month'], type: j['type'],
    amount: (j['amount'] as num).toDouble(),
  );
}
