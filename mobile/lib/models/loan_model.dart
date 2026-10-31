class LoanModel {
  const LoanModel({
    required this.lender,
    required this.nickname,
    required this.original,
    required this.balance,
    required this.rateBps,
    required this.months,
    required this.start,
    required this.nextDue,
    required this.principalPaid,
    required this.totalPaid,
  });
  final String lender, nickname;
  final int original, balance, rateBps, months, principalPaid, totalPaid;
  final DateTime start, nextDue;
}
