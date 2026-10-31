class PaymentModel {
  const PaymentModel(this.date, this.amount, this.late);
  final DateTime date;
  final int amount;
  final bool late;
}
