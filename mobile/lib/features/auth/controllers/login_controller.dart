import 'package:flutter/material.dart';
import '../../../core/controllers/screen_controller.dart';

class LoginController extends ScreenController {
  final phone = TextEditingController();
  String? error;
  @override
  void onClose() {
    phone.dispose();
    super.onClose();
  }
}

class OtpController extends ScreenController {
  final code = TextEditingController();
  String? error;
  bool resent = false, verifying = false;
  @override
  void onClose() {
    code.dispose();
    super.onClose();
  }
}
