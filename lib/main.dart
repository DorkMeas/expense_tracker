import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  final AppState _state = AppState.seeded();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5FA3)),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          ),
          home: _state.isLoggedIn
              ? HomeShell(
                  state: _state,
                  onLogout: _state.logout,
                )
              : LoginScreen(onLogin: _state.login),
        );
      },
    );
  }
}

enum ExpenseCategory {
  food('Food', Icons.restaurant, Color(0xFF1E5FA3)),
  transport('Transport', Icons.directions_bus, Color(0xFFFF9800)),
  study('Study', Icons.auto_stories, Color(0xFF4CAF50)),
  health('Health', Icons.health_and_safety, Color(0xFF00ACC1)),
  fun('Fun', Icons.sports_esports, Color(0xFF7E57C2)),
  other('Other', Icons.more_horiz, Color(0xFF9E9E9E));

  const ExpenseCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  final String id;
  final double amount;
  final ExpenseCategory category;
  final String note;
  final DateTime date;
}

enum StatsRange { weekly, monthly, yearly }

class AppState extends ChangeNotifier {
  AppState.seeded() {
    _expenses.addAll([
      Expense(
        id: 'e1',
        amount: 2.5,
        category: ExpenseCategory.food,
        note: 'Lunch – Khmer Food',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Expense(
        id: 'e2',
        amount: 1.5,
        category: ExpenseCategory.transport,
        note: 'Taxi',
        date: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Expense(
        id: 'e3',
        amount: 8.5,
        category: ExpenseCategory.study,
        note: 'Book – Book Store',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'e4',
        amount: 12,
        category: ExpenseCategory.food,
        note: 'Dinner',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Expense(
        id: 'e5',
        amount: 18,
        category: ExpenseCategory.health,
        note: 'Medicine',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Expense(
        id: 'e6',
        amount: 20,
        category: ExpenseCategory.fun,
        note: 'Game credit',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);
  }

  bool isLoggedIn = false;
  double monthlyBudget = 400;
  final List<Expense> _expenses = [];
  StatsRange selectedRange = StatsRange.weekly;

  List<Expense> get expenses => List.unmodifiable(_expenses)..sort((a, b) => b.date.compareTo(a.date));

  void login(String email, String password) {
    if (email.contains('@') && password.length >= 6) {
      isLoggedIn = true;
      notifyListeners();
    }
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }

  void addExpense({
    required double amount,
    required ExpenseCategory category,
    required String note,
    required DateTime date,
  }) {
    _expenses.add(
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        category: category,
        note: note.isEmpty ? category.label : note,
        date: date,
      ),
    );
    notifyListeners();
  }

  void updateBudget(double budget) {
    monthlyBudget = budget;
    notifyListeners();
  }

  void changeStatsRange(StatsRange range) {
    selectedRange = range;
    notifyListeners();
  }

  double get monthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get budgetUsage => monthlyBudget <= 0 ? 0 : (monthTotal / monthlyBudget).clamp(0, 1);

  Map<ExpenseCategory, double> get monthByCategory {
    final now = DateTime.now();
    final map = <ExpenseCategory, double>{for (final c in ExpenseCategory.values) c: 0};
    for (final e in _expenses.where((e) => e.date.month == now.month && e.date.year == now.year)) {
      map[e.category] = map[e.category]! + e.amount;
    }
    return map;
  }

  List<double> get selectedBars {
    final now = DateTime.now();
    switch (selectedRange) {
      case StatsRange.weekly:
        return List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day - (6 - i));
          return _expenses.where((e) => _sameDay(e.date, day)).fold(0.0, (sum, e) => sum + e.amount);
        });
      case StatsRange.monthly:
        return List.generate(4, (i) {
          final start = DateTime(now.year, now.month, 1 + (i * 7));
          final end = start.add(const Duration(days: 6));
          return _expenses
              .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
              .fold(0.0, (sum, e) => sum + e.amount);
        });
      case StatsRange.yearly:
        return List.generate(12, (i) {
          return _expenses
              .where((e) => e.date.year == now.year && e.date.month == i + 1)
              .fold(0.0, (sum, e) => sum + e.amount);
        });
    }
  }

  String get smartTip {
    final spent = monthTotal;
    final usage = budgetUsage;
    if (spent == 0) return 'Start tracking today to unlock personalized saving tips.';
    if (usage < 0.5) return 'Great control! You saved ${(100 - (usage * 100)).round()}% of your monthly budget so far.';
    if (usage < 0.8) return 'Nice progress. Keep food and transport spending steady this week.';
    if (usage < 1.0) return 'Careful: you used ${(usage * 100).round()}% of budget. Try low-cost meals this week.';
    return 'Budget exceeded. Pause non-essential spending for a few days to recover.';
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final void Function(String email, String password) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    widget.onLogin(_email.text.trim(), _password.text.trim());
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E5FA3), Color(0xFF4A89D2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF1E5FA3), size: 54),
                      const SizedBox(height: 10),
                      const Text('Expense Tracker', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                      const SizedBox(height: 8),
                      const Text('Login to continue', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: const Color(0xFF1E5FA3)),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state, required this.onLogout});
  final AppState state;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        state: widget.state,
        onAddTap: () => setState(() => _index = 1),
      ),
      AddExpenseScreen(
        state: widget.state,
        onSaved: () => setState(() => _index = 0),
      ),
      StatisticsScreen(state: widget.state),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Add Expense'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Statistics'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state, required this.onAddTap});

  final AppState state;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final month = _monthLabel(DateTime.now());
    final categories = state.monthByCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1E5FA3), borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(month, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('\$${state.monthTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const Text('Total spent this month', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onAddTap,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C8ED7)),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget: \$${state.monthlyBudget.toStringAsFixed(0)}'),
            Text('${(state.budgetUsage * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: state.budgetUsage, minHeight: 10, borderRadius: BorderRadius.circular(20)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final value = await showDialog<double>(
                context: context,
                builder: (_) => _BudgetDialog(initial: state.monthlyBudget),
              );
              if (value != null && value > 0) state.updateBudget(value);
            },
            child: const Text('Set Budget'),
          ),
        ),
        const Text('BY CATEGORY', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in categories)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: entry.key.color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                child: Text('${entry.key.label}  \$${entry.value.toStringAsFixed(2)}'),
              )
          ],
        ),
        const SizedBox(height: 18),
        const Text('RECENT', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
        const SizedBox(height: 8),
        for (final expense in state.expenses.take(8)) _ExpenseCard(expense: expense),
      ],
    );
  }

  String _monthLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.state, required this.onSaved});

  final AppState state;
  final VoidCallback onSaved;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount (USD)', prefixText: '\$', border: OutlineInputBorder()),
            validator: (v) {
              final value = double.tryParse(v ?? '');
              if (value == null || value <= 0) return 'Enter valid amount';
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text('BY CATEGORY', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ExpenseCategory.values
                .map(
                  (c) => ChoiceChip(
                    label: Text(c.label),
                    avatar: Icon(c.icon, size: 18),
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note', hintText: 'e.g. Lunch at...', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(DateTime.now().year - 2),
                lastDate: DateTime(DateTime.now().year + 2),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
              child: Text(_formatDate(_date)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              widget.state.addExpense(
                amount: double.parse(_amount.text.trim()),
                category: _category,
                note: _note.text.trim(),
                date: _date,
              );
              _amount.clear();
              _note.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense saved successfully.')));
              widget.onSaved();
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E5FA3), minimumSize: const Size.fromHeight(52)),
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final bars = state.selectedBars;
    final maxBar = bars.fold<double>(1, (a, b) => math.max(a, b));
    final categoryMap = state.monthByCategory;
    final total = categoryMap.values.fold<double>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(child: Text('Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        SegmentedButton<StatsRange>(
          segments: const [
            ButtonSegment(value: StatsRange.weekly, label: Text('Weekly')),
            ButtonSegment(value: StatsRange.monthly, label: Text('Monthly')),
            ButtonSegment(value: StatsRange.yearly, label: Text('Yearly')),
          ],
          selected: {state.selectedRange},
          onSelectionChanged: (selection) => state.changeStatsRange(selection.first),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < bars.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      height: (bars[i] / maxBar) * 170,
                      decoration: BoxDecoration(
                        color: i == bars.length ~/ 2 ? const Color(0xFF1E5FA3) : const Color(0xFFB7D8EC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('BREAKDOWN', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: Row(
            children: [
              SizedBox(
                width: 160,
                child: CustomPaint(
                  painter: DonutPainter(
                    values: ExpenseCategory.values.map((c) => categoryMap[c] ?? 0).toList(),
                    colors: ExpenseCategory.values.map((c) => c.color).toList(),
                  ),
                  child: Center(
                    child: Text('\$${total.toStringAsFixed(0)}\nTotal', textAlign: TextAlign.center),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in ExpenseCategory.values)
                      _BreakdownRow(
                        color: c.color,
                        label: c.label,
                        percent: total == 0 ? 0 : ((categoryMap[c] ?? 0) / total) * 100,
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF3D8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8BC34A)),
          ),
          child: Text('💡 ${state.smartTip}'),
        ),
      ],
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(expense.category.icon, color: expense.category.color),
        title: Text(expense.note),
        subtitle: Text(_relativeLabel(expense.date)),
        trailing: Text('-\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _relativeLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    final y = DateTime(now.year, now.month, now.day - 1);
    if (date.year == y.year && date.month == y.month && date.day == y.day) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.color, required this.label, required this.percent});
  final Color color;
  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('${percent.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2.2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.butt;

    if (total <= 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2;
      paint.color = colors[i];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.initial});
  final double initial;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Monthly Budget'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(prefixText: '\$', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_controller.text.trim());
            if (value != null && value > 0) Navigator.pop(context, value);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
