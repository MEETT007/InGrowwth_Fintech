import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:home_finance/data/repositories/loan_repository.dart';
import 'package:home_finance/features/auth/controllers/login_controller.dart';
import 'package:home_finance/features/emi_protection/controllers/protection_controller.dart';
import 'package:home_finance/features/employee/pan_details_controller.dart';
import 'package:home_finance/services/pan_lookup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GetX batches calculator state and keeps controller instances isolated', () {
    final loan = LoanRepository().loan;
    final first = ProtectionController(loan)..onStart();
    final second = ProtectionController(loan)..onStart();
    expect(first, isA<GetxController>());
    var updates = 0;
    final remove = first.addListener(() => updates++);
    first.calculate();
    expect(updates, 1);
    expect(first.result, isNotNull);
    expect(first.dirty, isFalse);
    first.balance.text = '2500000';
    first.changed();
    expect(first.dirty, isTrue);
    expect(second.balance.text, isNot('2500000'));
    expect(second.result, isNull);
    remove();
    first.onDelete();
    second.onDelete();
    expect(first.isClosed, isTrue);
  });

  test('new OTP dialog starts with fresh state and closed forms ignore changes', () {
    final first = OtpController()..onStart();
    first.change(() {
      first.verifying = true;
      first.code.text = '123456';
    });
    first.onDelete();
    first.change(() => fail('Closed form must ignore late mutations'));
    final next = OtpController()..onStart();
    expect(next.verifying, isFalse);
    expect(next.error, isNull);
    expect(next.code.text, isEmpty);
    next.onDelete();
  });

  test('PAN response after screen closes cannot publish stale state', () async {
    final response = Completer<http.Response>();
    final api = PanLookupService(client: MockClient((_) => response.future));
    final controller = PanDetailsController(api)..onStart();
    var updates = 0;
    final remove = controller.addListener(() => updates++);
    final pending = controller.fetch('QWERT1234L');
    expect(controller.loading, isTrue);
    expect(updates, 1);
    controller.onDelete();
    response.complete(http.Response('{"message":"Not found"}', 404));
    await pending;
    expect(updates, 1);
    expect(controller.customer, isNull);
    expect(controller.error, isNull);
    remove();
    api.close();
  });
}
