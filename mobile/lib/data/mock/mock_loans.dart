import '../../models/loan_model.dart';

final mockLoan = LoanModel(
  lender: 'Aashray Housing · Demo',
  nickname: 'Our first home',
  original: 350000000,
  balance: 300000000,
  rateBps: 700,
  months: 240,
  start: DateTime(2022, 11, 5),
  nextDue: DateTime(2026, 11, 5),
  principalPaid: 50000000,
  totalPaid: 132800000,
);
