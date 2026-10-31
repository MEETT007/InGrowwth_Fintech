class RepaymentRow {
  const RepaymentRow(
    this.month,
    this.opening,
    this.emi,
    this.interest,
    this.principal,
    this.extra,
    this.closing,
  );
  final int month, opening, emi, interest, principal, extra, closing;
}

class RepaymentPlan {
  const RepaymentPlan(this.rows);
  final List<RepaymentRow> rows;
  int get interest => rows.fold(0, (s, r) => s + r.interest);
  int get extras => rows.fold(0, (s, r) => s + r.extra);
  int get months => rows.length;
}

enum AdjustmentPolicy { emi, tenure }
