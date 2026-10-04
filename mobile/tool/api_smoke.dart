import '../lib/api.dart';

Future<void> main() async {
  final api = BankingApi();
  try {
    await api.request('auth/session');
    final user = await api.request('auth/login', {
      'email': 'borrower@demo.ingrowwth',
      'password': const String.fromEnvironment(
        'DEMO_PASSWORD',
        defaultValue: 'DemoHome!2026',
      ),
    });
    if (user['role'] != 'BORROWER') {
      throw StateError('Wrong authenticated role');
    }
    final loans = await api.request('loans') as List;
    if (loans.isEmpty) {
      throw StateError('Missing loan records');
    }
    final d = await api.request('loans/${loans.first['id']}');
    if (d['loan']['id'] != loans.first['id']) {
      throw StateError('Case mismatch');
    }
    final result = await api.request('planner', {
      'principal': 4500000,
      'annualRate': 8.5,
      'months': 240,
      'extraMonthly': 5000,
      'annualExtra': 25000,
      'oneTime': 100000,
      'oneTimeMonth': 12,
      'prepayMode': 'TENURE',
      'resetMonth': 0,
      'resetRate': 9.5,
      'resetMode': 'EMI',
      'fees': 0,
      'startDate': '2026-11-05',
    });
    if (result['interestSaved'] <= 0 || result['monthsSaved'] <= 0) {
      throw StateError('Invalid repayment comparison');
    }
    await api.request('auth/logout', {});
    print(
      'Mobile Java connection passed: CSRF, session login, owned loans, detail, planner and logout.',
    );
  } finally {
    api.dispose();
  }
}
