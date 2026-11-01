import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Batches related form changes into one GetBuilder update.
abstract class ScreenController extends GetxController {
  void change(VoidCallback mutation) {
    if (isClosed) return;
    mutation();
    update();
  }
}
