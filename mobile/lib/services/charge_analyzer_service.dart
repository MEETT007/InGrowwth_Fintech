class ChargeEstimate {
  const ChargeEstimate(this.returnFee, this.penal, this.tax, this.interest);
  final int? returnFee, penal, tax, interest;
  int get subtotal =>
      (returnFee ?? 0) + (penal ?? 0) + (tax ?? 0) + (interest ?? 0);
}

class ChargeAnalyzerService {
  ChargeEstimate calculate({
    required int overdue,
    required int days,
    int? returnFee,
    int? penal,
    int? taxBps,
    int? overdueRateBps,
  }) {
    if (overdue < 0 ||
        days < 0 ||
        days > 3650 ||
        [
          returnFee,
          penal,
          taxBps,
          overdueRateBps,
        ].any((v) => v != null && v < 0) ||
        (taxBps ?? 0) > 10000 ||
        (overdueRateBps ?? 0) > 10000) {
      throw const FormatException();
    }
    return ChargeEstimate(
      returnFee,
      penal,
      taxBps == null || returnFee == null || penal == null
          ? null
          : (((returnFee + penal) * taxBps + 5000) ~/ 10000),
      overdueRateBps == null
          ? null
          : ((BigInt.from(overdue) *
                            BigInt.from(overdueRateBps) *
                            BigInt.from(days) +
                        BigInt.from(1825000)) ~/
                    BigInt.from(3650000))
                .toInt(),
    );
  }
}
