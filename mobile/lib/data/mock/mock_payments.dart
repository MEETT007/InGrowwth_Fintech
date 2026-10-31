import '../../models/payment_model.dart';
import '../../core/utils/date_formatter.dart';

List<PaymentModel> mockPayments(DateTime nextDue, int emi) => List.generate(
  4,
  (i) => PaymentModel(monthAfter(nextDue, -i - 1), emi, i == 2),
);
