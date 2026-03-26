import 'package:flutter/material.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5FA3)),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;

  void _handleLoginSuccess() {
    setState(() => _isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn
        ? HomeShell(onLogout: () => setState(() => _isLoggedIn = false))
        : LoginScreen(onLoginSuccess: _handleLoginSuccess);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E5FA3), Color(0xFF498AD2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 54, color: Color(0xFF1E5FA3)),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to track your expenses',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your email';
                            if (!value.contains('@')) return 'Invalid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF1E5FA3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Demo credentials: any valid email + password (6+ chars)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        )
                      ],
                    ),
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
  const HomeShell({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const AddExpenseScreen(),
      const StatisticsScreen(),
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
        onDestinationSelected: (value) => setState(() => _index = value),
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
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E5FA3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mar 2026', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('\$248.50', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Total Spent This Month', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget: \$400'),
            Text('62%', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(value: 0.62, minHeight: 10),
        const SizedBox(height: 18),
        const Text('BY CATEGORY', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _CategoryChip(label: 'Food', color: Color(0xFFD8E8FF)),
            _CategoryChip(label: 'Transport', color: Color(0xFFFCE7DB)),
            _CategoryChip(label: 'Study', color: Color(0xFFDDF5DE)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('RECENT', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const _ExpenseTile(title: 'Lunch – Khmer Food', subtitle: 'Today, 12:30pm', amount: '-\$2.50', icon: Icons.restaurant),
        const _ExpenseTile(title: 'Taxi', subtitle: 'Today, 8:00am', amount: '-\$1.50', icon: Icons.local_taxi),
        const _ExpenseTile(title: 'Book – Book Store', subtitle: 'Yesterday', amount: '-\$8.50', icon: Icons.menu_book),
      ],
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _category = 'Food';
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (USD)',
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        const Text('BY CATEGORY', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Food', 'Transport', 'Study', 'Health', 'Fun', 'More']
              .map(
                (e) => ChoiceChip(
                  label: Text(e),
                  selected: _category == e,
                  onSelected: (_) => setState(() => _category = e),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder(), hintText: 'e.g. Lunch at...'),
        ),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(),
            hintText: 'Today - Mar 22, 2026',
            suffixIcon: Icon(Icons.keyboard_arrow_down),
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E5FA3),
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () {
            final amount = _amountController.text.trim();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved $amount USD in $_category category')),
            );
          },
          child: const Text('Save Expense'),
        ),
      ],
    );
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bars = [0.45, 0.58, 0.68, 0.34, 0.58, 0.22, 0.1];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(child: Text('Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Weekly', label: Text('Weekly')),
            ButtonSegment(value: 'Monthly', label: Text('Monthly')),
            ButtonSegment(value: 'Yearly', label: Text('Yearly')),
          ],
          selected: const {'Weekly'},
          onSelectionChanged: (_) {},
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final value in bars)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      height: 180 * value,
                      decoration: BoxDecoration(
                        color: value == 0.68 ? const Color(0xFF1E5FA3) : const Color(0xFFB7D8EC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('BREAKDOWN', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        const _BreakdownItem(label: 'Food', percent: '40%', color: Color(0xFF1E5FA3)),
        const _BreakdownItem(label: 'Transport', percent: '25%', color: Color(0xFFFFC107)),
        const _BreakdownItem(label: 'Study', percent: '18%', color: Color(0xFF4CAF50)),
        const _BreakdownItem(label: 'Other', percent: '17%', color: Color(0xFFBDBDBD)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF3D8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8BC34A)),
          ),
          child: const Text('💡 You saved 38% vs last week! Keep it up — you are on track.'),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(color: Color(0xFF1E5FA3), fontWeight: FontWeight.w600)),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.title, required this.subtitle, required this.amount, required this.icon});

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1E5FA3)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(amount, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  const _BreakdownItem({required this.label, required this.percent, required this.color});
  final String label;
  final String percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 14, height: 14, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(percent),
        ],
      ),
    );
  }
}
