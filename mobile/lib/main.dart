import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';

void main() => runApp(const HomeFinanceApp());
String money(dynamic value) {
  final n = (value as num? ?? 0).round().toString();
  if (n.length <= 3) {
    return '₹$n';
  }
  final tail = n.substring(n.length - 3), head = n.substring(0, n.length - 3);
  final pairs = <String>[];
  for (int i = head.length; i > 0; i -= 2) {
    pairs.insert(0, head.substring(i - 2 < 0 ? 0 : i - 2, i));
  }
  return '₹${pairs.join(',')},$tail';
}

String label(dynamic value) =>
    value.toString().toLowerCase().replaceAll('_', ' ');

ThemeData financeTheme(Brightness brightness) {
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xff1e3a8a),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceContainerLowest,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
    ),
  );
}

class HomeFinanceApp extends StatelessWidget {
  const HomeFinanceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'InGrowwth Home Finance',
    debugShowCheckedModeBanner: false,
    theme: financeTheme(Brightness.light),
    darkTheme: financeTheme(Brightness.dark),
    home: const FinanceHome(),
  );
}

class FinanceHome extends StatefulWidget {
  const FinanceHome({super.key});
  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> {
  final api = BankingApi();
  final email = TextEditingController(), password = TextEditingController();
  Map<String, dynamic>? user, detail;
  List<dynamic> loans = [];
  String? error;
  bool busy = false;
  int tab = 0;
  StreamSubscription<String>? subscription;
  Timer? reconnect;
  bool disposed = false;
  @override
  void initState() {
    super.initState();
    session();
  }

  Future<void> session() async {
    try {
      final s = await api.request('auth/session');
      if (mounted) {
        setState(() => user = s['user']);
      }
      if (user != null) {
        await refresh();
        live();
      }
    } catch (e) {
      fail(e);
    }
  }

  void fail(Object e) {
    if (mounted) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> run(Future<void> Function() work) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await work();
    } catch (e) {
      fail(e);
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> refresh([String? id]) async {
    final list = await api.request('loans') as List<dynamic>;
    final selected =
        id ?? detail?['loan']['id'] ?? (list.isEmpty ? null : list.first['id']);
    final next = selected == null ? null : await api.request('loans/$selected');
    if (mounted) {
      setState(() {
        loans = list;
        detail = next;
      });
    }
  }

  void live() {
    subscription?.cancel();
    subscription = api.updates().listen(
      (_) => refresh().catchError(fail),
      onError: (Object e) {
        if (!disposed) {
          reconnect?.cancel();
          reconnect = Timer(const Duration(seconds: 5), live);
        }
      },
      onDone: () {
        if (!disposed) {
          reconnect?.cancel();
          reconnect = Timer(const Duration(seconds: 5), live);
        }
      },
    );
  }

  Future<void> action(String name, {String? target, String? note}) async {
    final l = detail!['loan'];
    await api.request('loans/${l['id']}/actions', {
      'action': name,
      'revision': l['revision'],
      'targetId': target,
      'note': note,
    });
    await refresh();
  }

  Future<void> payment(String kind, double amount, String mode) async {
    await api.request('loans/${detail!['loan']['id']}/payments', {
      'kind': kind,
      'amount': amount,
      'mode': mode,
      'idempotencyKey': 'mobile-${DateTime.now().microsecondsSinceEpoch}',
    });
    await refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sandbox request recorded. An officer must confirm receipt.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    disposed = true;
    reconnect?.cancel();
    subscription?.cancel();
    api.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InGrowwth · Home finance'),
        actions: user == null
            ? []
            : [
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          await api.request('auth/logout', {});
                          subscription?.cancel();
                          reconnect?.cancel();
                          setState(() {
                            user = null;
                            detail = null;
                            loans = [];
                          });
                          await api.request('auth/session');
                        }),
                  icon: const Icon(Icons.logout),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              MaterialBanner(
                content: Text(error!, semanticsLabel: 'Error: $error'),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => error = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(
              child: user == null
                  ? login()
                  : tab == 1
                  ? Planner(api: api, loan: detail?['loan'])
                  : workspace(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: user == null
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() => tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'My home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calculate_outlined),
                  label: 'Repayment planner',
                ),
              ],
            ),
    );
  }

  Widget login() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.account_balance_outlined, size: 48),
          const SizedBox(height: 24),
          Text(
            'A clearer path to your own home',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Track your application, understand your EMI, and compare ways to repay earlier.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy
                ? null
                : () => run(() async {
                    user = await api.request('auth/login', {
                      'email': email.text.trim(),
                      'password': password.text,
                    });
                    await refresh();
                    live();
                  }),
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create your applicant account in the web portal first. This companion uses the same secure Java service and account.',
          ),
        ],
      ),
    ),
  );
  Widget workspace() => RefreshIndicator(
    onRefresh: () => run(() => refresh()),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome, ${user!['name']}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (loans.isEmpty)
          const Text(
            'No applications yet. Start a home-loan application in the web portal.',
          ),
        if (loans.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: detail?['loan']['id'],
            decoration: const InputDecoration(labelText: 'Select application'),
            items: loans
                .map(
                  (l) => DropdownMenuItem<String>(
                    value: l['id'],
                    child: Text(
                      '${l['applicantName']} · ${label(l['stage'])}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) => run(() => refresh(id)),
          ),
        const SizedBox(height: 20),
        if (detail != null) ...summary(),
      ],
    ),
  );
  List<Widget> summary() {
    final l = detail!['loan'];
    final active = l['stage'] == 'ACTIVE';
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label(l['stage']).toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Text(
                money(active ? l['outstanding'] : l['requestedAmount']),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text(active ? 'Outstanding principal' : 'Requested loan'),
              const SizedBox(height: 16),
              Text(
                'Rate ${l['annualRate']}% · ${active ? l['remainingMonths'] : l['tenureMonths']} months',
              ),
              if (active) ...[
                const Divider(),
                Text('Monthly EMI ${money(l['emi'])}'),
                Text('Next due ${l['dueDate'] ?? 'To be confirmed'}'),
                Text('Interest paid ${money(l['paidInterest'])}'),
                Text('Principal repaid ${money(l['paidPrincipal'])}'),
              ],
            ],
          ),
        ),
      ),
      if (user!['role'] == 'BORROWER' && l['stage'] == 'DRAFT')
        FilledButton(
          onPressed: busy ? null : () => run(() => action('SUBMIT')),
          child: const Text('Submit for review'),
        ),
      if (user!['role'] == 'BORROWER' && l['stage'] == 'SANCTIONED')
        FilledButton(
          onPressed: busy ? null : () => run(() => action('ACCEPT_SANCTION')),
          child: const Text('Accept sandbox sanction terms'),
        ),
      if (l['stage'] == 'DISBURSEMENT' &&
          l['disbursed'] > 0 &&
          user!['role'] == 'BORROWER') ...[
        Text(
          'Estimated monthly pre-EMI: ${money((l['outstanding'] as num) * (l['annualRate'] as num) / 1200)}',
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () => run(
                  () => payment(
                    'PRE_EMI',
                    ((l['outstanding'] as num) *
                                (l['annualRate'] as num) /
                                1200 *
                                100)
                            .round() /
                        100,
                    'TENURE',
                  ),
                ),
          child: const Text('Request sandbox pre-EMI'),
        ),
      ],
      if (l['stage'] == 'CLOSED') ...[
        Text(
          'Closure checklist',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        for (final task in [
          ['closureCertificate', 'No-dues certificate'],
          ['originalsReturned', 'Original property documents'],
          ['securityReleased', 'Release of security'],
        ])
          ListTile(
            title: Text(task[1]),
            subtitle: Text(
              l[task[0]] == true ? 'Complete' : 'Awaiting lender completion',
            ),
          ),
      ],
      if (active && user!['role'] == 'BORROWER') ...[
        FilledButton(
          onPressed: busy
              ? null
              : () => run(
                  () => payment('EMI', (l['emi'] as num).toDouble(), 'TENURE'),
                ),
          child: const Text('Record sandbox EMI request'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: busy ? null : prepay,
          child: const Text('Plan a principal prepayment'),
        ),
        const SizedBox(height: 12),
        const Text(
          'These requests do not move money. Officer confirmation updates the loan ledger.',
        ),
      ],
      const SizedBox(height: 24),
      Text('Documents', style: Theme.of(context).textTheme.titleLarge),
      for (final d in detail!['documents'])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            d['verified']
                ? Icons.check_circle_outline
                : Icons.description_outlined,
          ),
          title: Text(label(d['kind'])),
          subtitle: Text(
            '${d['filename']} · ${d['verified'] ? 'Verified' : 'Awaiting verification'}',
          ),
        ),
      const Text('Upload and download protected documents in the web portal.'),
      const SizedBox(height: 24),
      Text('Clarifications', style: Theme.of(context).textTheme.titleLarge),
      for (final q in detail!['queries'])
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['question']),
                if (q['response'] != null)
                  Text('Your response: ${q['response']}'),
                Text(q['resolved'] ? 'Resolved' : 'Open'),
                if (!q['resolved'] &&
                    q['response'] == null &&
                    user!['role'] == 'BORROWER')
                  TextButton(
                    onPressed: () => respond(q['id']),
                    child: const Text('Respond'),
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 24),
      Text('Payment requests', style: Theme.of(context).textTheme.titleLarge),
      for (final p in detail!['payments'])
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${label(p['kind'])} · ${money(p['amount'])}'),
          trailing: p['status'] == 'PENDING'
              ? TextButton(
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          await api.request(
                            'loans/${l['id']}/payments/${p['id']}/cancel',
                            {},
                          );
                          await refresh();
                        }),
                  child: const Text('Cancel'),
                )
              : null,
          subtitle: Text(
            '${p['status']}${p['reference'] == null ? '' : ' · ${p['reference']}'}',
          ),
        ),
      const SizedBox(height: 24),
      Text(
        'Application timeline',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      for (final e in detail!['events'])
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, size: 20),
          title: Text(e['message']),
          subtitle: Text(e['createdAt'].toString().substring(0, 10)),
        ),
    ];
  }

  Future<void> respond(String id) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Respond to officer'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: 'Your response'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Send response'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text != null && text.trim().length >= 5) {
      await run(() => action('RESPOND', target: id, note: text));
    }
  }

  Future<void> prepay() async {
    final controller = TextEditingController();
    String mode = 'TENURE';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Principal prepayment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: mode,
                items: const [
                  DropdownMenuItem(
                    value: 'TENURE',
                    child: Text('Reduce tenure'),
                  ),
                  DropdownMenuItem(value: 'EMI', child: Text('Reduce EMI')),
                ],
                onChanged: (v) => set(() => mode = v!),
                decoration: const InputDecoration(labelText: 'How to apply it'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, {
                'amount': double.tryParse(controller.text),
                'mode': mode,
              }),
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result != null) {
      final amount = result['amount'];
      if (amount == null || amount <= 0) {
        fail('Enter a positive amount.');
        return;
      }
      await run(() => payment('PREPAYMENT', amount, result['mode']));
    }
  }
}

class Planner extends StatefulWidget {
  const Planner({super.key, required this.api, this.loan});
  final BankingApi api;
  final Map<String, dynamic>? loan;
  @override
  State<Planner> createState() => _PlannerState();
}

class _PlannerState extends State<Planner> {
  late final List<TextEditingController> fields;
  Map<String, dynamic>? result;
  String mode = 'TENURE';
  String? error;
  bool busy = false, dirty = true;
  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    fields = [
      TextEditingController(
        text:
            '${l != null && l['stage'] == 'ACTIVE' ? l['outstanding'] : l?['requestedAmount'] ?? 4500000}',
      ),
      TextEditingController(text: '${l?['annualRate'] ?? 8.5}'),
      TextEditingController(
        text:
            '${l != null && l['stage'] == 'ACTIVE' ? l['remainingMonths'] : l?['tenureMonths'] ?? 240}',
      ),
      TextEditingController(text: '5000'),
      TextEditingController(text: '25000'),
      TextEditingController(text: '100000'),
      TextEditingController(text: '12'),
    ];
    for (final f in fields) {
      f.addListener(() => setState(() => dirty = true));
    }
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> calculate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final values = fields.map((f) => double.tryParse(f.text)).toList();
      if (values.any((n) => n == null)) {
        throw Exception('Enter valid numbers in every field.');
      }
      final now = DateTime.now();
      final date = DateTime(
        now.year,
        now.month + 1,
        5,
      ).toIso8601String().substring(0, 10);
      final next = await widget.api.request('planner', {
        'principal': values[0],
        'annualRate': values[1],
        'months': values[2]!.toInt(),
        'extraMonthly': values[3],
        'annualExtra': values[4],
        'oneTime': values[5],
        'oneTimeMonth': values[6]!.toInt(),
        'prepayMode': mode,
        'resetMonth': 0,
        'resetRate': values[1],
        'resetMode': 'EMI',
        'fees': 0,
        'startDate': date,
      });
      if (mounted) {
        setState(() {
          result = next;
          dirty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Outstanding principal (₹)',
      'Annual interest (%)',
      'Remaining months',
      'Extra every month (₹)',
      'Extra every year (₹)',
      'One-time extra (₹)',
      'One-time payment month',
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Own your future sooner',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Compare a standard EMI with extra principal repayments. Keep a cash reserve before choosing an extra payment.',
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: fields[i],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: labels[i]),
            ),
          ),
        DropdownButtonFormField<String>(
          initialValue: mode,
          decoration: const InputDecoration(labelText: 'Prepayment goal'),
          items: const [
            DropdownMenuItem(value: 'TENURE', child: Text('Finish earlier')),
            DropdownMenuItem(value: 'EMI', child: Text('Lower monthly EMI')),
          ],
          onChanged: (v) => setState(() {
            mode = v!;
            dirty = true;
          }),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: busy ? null : calculate,
          child: Text(busy ? 'Calculating…' : 'Compare repayment'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              semanticsLabel: 'Error: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (result != null) ...[
          if (dirty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Inputs changed. Update the comparison to refresh these results.',
              ),
            ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated interest saved',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    money(result!['interestSaved']),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text('${result!['monthsSaved']} months earlier'),
                  Text('Projected payoff: ${result!['planned']['payoffDate']}'),
                  const Divider(),
                  Text(
                    'Baseline interest: ${money(result!['baseline']['interest'])}',
                  ),
                  Text(
                    'Planned interest: ${money(result!['planned']['interest'])}',
                  ),
                ],
              ),
            ),
          ),
          ExpansionTile(
            title: const Text('First 12 months: interest and principal'),
            children: [
              for (final row in (result!['planned']['rows'] as List).take(12))
                ListTile(
                  title: Text(
                    'Month ${row['month']} · EMI ${money(row['emi'])}',
                  ),
                  subtitle: Text(
                    'Interest ${money(row['interest'])} · Principal ${money(row['principal'])}\nExtra ${money(row['extra'])} · Balance ${money(row['closing'])}',
                  ),
                ),
            ],
          ),
          ExpansionTile(
            title: const Text('Calculation assumptions'),
            children: [
              for (final assumption in result!['assumptions'])
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(assumption),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'These are estimates. Your lender’s rate, payment date, rounding, and contractual charges determine the actual repayment. Use the web planner for rate resets, refinancing fees, and complete schedules.',
        ),
      ],
    );
  }
}
