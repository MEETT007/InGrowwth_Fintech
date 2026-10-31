import 'dart:async';
import 'dart:math' as math;

/// Local session data only. This repository never makes network requests.
class BankingApi {
  final _events = StreamController<String>.broadcast();
  final List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic>? _user;
  final _loan = <String, dynamic>{
    'id': 'demo',
    'applicantName': 'Demo borrower',
    'stage': 'ACTIVE',
    'requestedAmount': 4500000,
    'outstanding': 4500000,
    'annualRate': 8.5,
    'tenureMonths': 240,
    'remainingMonths': 240,
    'emi': 39052.05,
    'paidInterest': 0,
    'paidPrincipal': 0,
    'dueDate': 'Demo schedule',
  };
  Future<dynamic> request(String path, [Map<String, dynamic>? body]) async {
    if (path == 'auth/session') return {'user': _user};
    if (path == 'auth/login') {
      return _user = {'name': 'Demo borrower', 'role': 'BORROWER'};
    }
    if (path == 'auth/logout') {
      _user = null;
      return {};
    }
    if (path == 'planner') return compare(body!);
    if (path == 'loans') return [Map<String, dynamic>.from(_loan)];
    if (path == 'loans/demo') {
      return {
        'loan': Map<String, dynamic>.from(_loan),
        'documents': [],
        'queries': [],
        'events': [],
        'payments': _payments.map((p) => Map<String, dynamic>.from(p)).toList(),
      };
    }
    if (path == 'loans/demo/payments') {
      final p = <String, dynamic>{
        ...body!,
        'id': '${_payments.length}',
        'status': 'PENDING',
        'reference': null,
      };
      _payments.add(p);
      _events.add('changed');
      return p;
    }
    if (path.endsWith('/cancel')) {
      _payments.firstWhere((p) => p['id'] == path.split('/')[3])['status'] =
          'CANCELLED';
      _events.add('changed');
      return {};
    }
    throw UnsupportedError('Unavailable in the local demo.');
  }

  Map<String, dynamic> compare(Map<String, dynamic> p) {
    final principal = (p['principal'] as num).toDouble(),
        rate = (p['annualRate'] as num).toDouble() / 1200;
    final months = p['months'] as int;
    if (!principal.isFinite ||
        principal < 1000 ||
        principal > 1e9 ||
        !rate.isFinite ||
        rate < 0 ||
        rate > .025 ||
        months < 1 ||
        months > 360) {
      throw ArgumentError('Enter valid balance, rate and tenure.');
    }
    for (final k in ['extraMonthly', 'annualExtra', 'oneTime']) {
      final v = (p[k] as num).toDouble();
      if (!v.isFinite || v < 0) {
        throw ArgumentError('Extra payments must be non-negative.');
      }
    }
    final oneMonth = p['oneTimeMonth'] as int;
    if (oneMonth < 0 ||
        oneMonth > months ||
        ((p['oneTime'] as num) > 0 && oneMonth == 0)) {
      throw ArgumentError('Choose a payment month within the tenure.');
    }
    double round(double v) => (v * 100).round() / 100;
    double emi(double b, int n) =>
        round(rate == 0 ? b / n : b * rate / (1 - math.pow(1 + rate, -n)));
    Map<String, dynamic> schedule(bool extras) {
      var balance = principal, total = 0.0, payment = emi(principal, months);
      final rows = <Map<String, dynamic>>[];
      final start = DateTime.parse(p['startDate'] as String);
      for (var m = 1; balance > 0 && m <= 1200; m++) {
        final interest = round(balance * rate),
            due = math.min(payment, balance + round(balance * rate));
        if (due <= interest) {
          throw StateError('Payment does not cover interest.');
        }
        final extra = extras
            ? math.min(
                balance - due + interest,
                (p['extraMonthly'] as num).toDouble() +
                    (m % 12 == 0 ? (p['annualExtra'] as num).toDouble() : 0) +
                    (m == oneMonth ? (p['oneTime'] as num).toDouble() : 0),
              )
            : 0.0;
        balance = round(balance - due + interest - extra);
        total += interest;
        rows.add({
          'month': m,
          'closing': balance,
          'date': DateTime(
            start.year,
            start.month + m - 1,
            start.day,
          ).toIso8601String().substring(0, 10),
        });
        if (extra > 0 && balance > 0 && p['prepayMode'] == 'EMI') {
          payment = emi(balance, math.max(1, months - m));
        }
      }
      if (balance > 0) throw StateError('Scenario exceeds modelling limit.');
      return {
        'interest': round(total),
        'months': rows.length,
        'payoffDate': rows.last['date'],
        'rows': rows,
      };
    }

    final baseline = schedule(false), planned = schedule(true);
    return {
      'baseline': baseline,
      'planned': planned,
      'interestSaved': round(
        (baseline['interest'] as double) - (planned['interest'] as double),
      ),
      'monthsSaved': (baseline['months'] as int) - (planned['months'] as int),
      'assumptions': [
        'Local estimate, monthly reducing balance, constant rate and rounded monthly interest. No server connection.',
      ],
    };
  }

  Stream<String> updates() => _events.stream;
  void dispose() {
    _events.close();
  }
}
