import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<FinancialRecord> _records = [];
  bool _loading = true;
  String? _filterType;
  String _search = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  int _page = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({int page = 0}) async {
    setState(() { _loading = true; _page = page; });
    try {
      final result = await ApiService.getRecords(
        type: _filterType,
        search: _search.isNotEmpty ? _search : null,
        from: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
        to: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
        page: page,
        size: 10,
      );
      setState(() {
        _records = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() { _filterType = null; _search = ''; _fromDate = null; _toDate = null; });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by category or notes...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); _load(); })
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
              onSubmitted: (_) => _load(),
            ),
          ),
          // Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              _Chip('All', null),
              const SizedBox(width: 8),
              _Chip('Income', 'INCOME'),
              const SizedBox(width: 8),
              _Chip('Expense', 'EXPENSE'),
              const SizedBox(width: 8),
              _DateRangeBtn(),
              if (_fromDate != null || _filterType != null || _search.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.clear, color: Colors.red, size: 14),
                      SizedBox(width: 4),
                      Text('Clear', style: TextStyle(color: Colors.red, fontSize: 13)),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
          // Results count
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('$_totalElements record${_totalElements != 1 ? 's' : ''} found',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (!auth.isAnalyst) ...[
                  const Spacer(),
                  const Row(children: [
                    Icon(Icons.lock_outline, color: Colors.grey, size: 14),
                    SizedBox(width: 4),
                    Text('View only', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ],
              ]),
            ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : RefreshIndicator(
                    onRefresh: () => _load(page: _page),
                    child: _records.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.inbox, color: Colors.grey, size: 48),
                            const SizedBox(height: 12),
                            const Text('No records found', style: TextStyle(color: Colors.grey)),
                            if (_search.isNotEmpty || _filterType != null || _fromDate != null)
                              TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _records.length,
                            itemBuilder: (_, i) => _RecordTile(
                              record: _records[i], fmt: fmt,
                              canEdit: auth.isAnalyst, canDelete: auth.isAdmin,
                              onEdit: () => _showForm(record: _records[i]),
                              onDelete: () => _delete(_records[i].id),
                            ),
                          ),
                  ),
          ),
          // Pagination
          if (_totalPages > 1 && !_loading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _page > 0 ? () => _load(page: _page - 1) : null,
                ),
                Text('Page ${_page + 1} of $_totalPages',
                    style: const TextStyle(color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _page < _totalPages - 1 ? () => _load(page: _page + 1) : null,
                ),
              ]),
            ),
        ],
      ),
      floatingActionButton: auth.isAnalyst
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF6366F1),
              onPressed: () => _showForm(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _Chip(String label, String? value) => GestureDetector(
    onTap: () { setState(() => _filterType = value); _load(); },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _filterType == value ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
          color: _filterType == value ? Colors.white : Colors.grey, fontSize: 13)),
    ),
  );

  Widget _DateRangeBtn() => GestureDetector(
    onTap: () async {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: _fromDate != null && _toDate != null
            ? DateTimeRange(start: _fromDate!, end: _toDate!) : null,
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1))),
          child: child!,
        ),
      );
      if (range != null) {
        setState(() { _fromDate = range.start; _toDate = range.end; });
        _load();
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _fromDate != null ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        const Icon(Icons.date_range, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          _fromDate != null
              ? '${DateFormat('MMM d').format(_fromDate!)} – ${DateFormat('MMM d').format(_toDate!)}'
              : 'Date Range',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ]),
    ),
  );

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Record', style: TextStyle(color: Colors.white)),
        content: const Text('This will soft-delete the record. Continue?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteRecord(id);
        _load(page: _page);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showForm({FinancialRecord? record}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => RecordForm(record: record, onSaved: () => _load(page: _page)),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final FinancialRecord record;
  final NumberFormat fmt;
  final bool canEdit, canDelete;
  final VoidCallback onEdit, onDelete;

  const _RecordTile({required this.record, required this.fmt,
      required this.canEdit, required this.canDelete,
      required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == 'INCOME';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isIncome ? Colors.green : Colors.red).withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isIncome ? Colors.green : Colors.red).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red),
        ),
        title: Text(record.category,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (record.notes != null && record.notes!.isNotEmpty)
            Text(record.notes!, style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(children: [
            Text(record.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (record.createdBy != null) ...[
              const Text(' · ', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text(record.createdBy!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ]),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(fmt.format(record.amount),
              style: TextStyle(color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold, fontSize: 14)),
          if (canEdit || canDelete) PopupMenuButton<String>(
            color: const Color(0xFF0F172A),
            onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); },
            itemBuilder: (_) => [
              if (canEdit) const PopupMenuItem(value: 'edit',
                  child: Row(children: [Icon(Icons.edit, color: Colors.white, size: 18),
                    SizedBox(width: 8), Text('Edit', style: TextStyle(color: Colors.white))])),
              if (canDelete) const PopupMenuItem(value: 'delete',
                  child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]),
      ),
    );
  }
}

class RecordForm extends StatefulWidget {
  final FinancialRecord? record;
  final VoidCallback onSaved;
  const RecordForm({super.key, this.record, required this.onSaved});
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'INCOME';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _amountCtrl.text = r.amount.toString();
      _categoryCtrl.text = r.category;
      _notesCtrl.text = r.notes ?? '';
      _type = r.type;
      _date = DateTime.parse(r.date);
    }
  }

  @override
  void dispose() { _amountCtrl.dispose(); _categoryCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'amount': double.parse(_amountCtrl.text),
      'type': _type,
      'category': _categoryCtrl.text.trim(),
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'notes': _notesCtrl.text.trim(),
    };
    try {
      final res = widget.record != null
          ? await ApiService.updateRecord(widget.record!.id, data)
          : await ApiService.createRecord(data);
      if (res['success'] == true) {
        if (mounted) { Navigator.pop(context); widget.onSaved(); }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(widget.record != null ? 'Edit Record' : 'New Record',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _TypeBtn('INCOME', Colors.green),
            const SizedBox(width: 12),
            _TypeBtn('EXPENSE', Colors.red),
          ]),
          const SizedBox(height: 16),
          _field(_amountCtrl, 'Amount', TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : double.tryParse(v) == null ? 'Invalid number' : null),
          const SizedBox(height: 12),
          _field(_categoryCtrl, 'Category', TextInputType.text,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context,
                  initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1))),
                    child: child!,
                  ));
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                const SizedBox(width: 10),
                Text(DateFormat('yyyy-MM-dd').format(_date), style: const TextStyle(color: Colors.white)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _field(_notesCtrl, 'Notes (optional)', TextInputType.text),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.record != null ? 'Update Record' : 'Create Record',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _TypeBtn(String type, Color color) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _type == type ? color.withOpacity(0.2) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _type == type ? color : Colors.transparent),
        ),
        child: Text(type, textAlign: TextAlign.center,
            style: TextStyle(color: _type == type ? color : Colors.grey, fontWeight: FontWeight.w600)),
      ),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, TextInputType type,
      {String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl, keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.grey),
          filled: true, fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1))),
        ),
        validator: validator,
      );
}
