import 'package:home_finance/api.dart';

Future<void> main() async {
  final repository = BankingApi();
  await repository.request('auth/login', {});
  final loans = await repository.request('loans') as List;
  if (loans.isEmpty) throw StateError('Missing local demo');
  repository.dispose();
}
