import '../../../services/pan_lookup_service.dart';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final repository = AuthRepository();
  UserModel? user;
  PanLookupService? employeeApi;
  bool verify(String mobile, String otp) {
    final next = repository.verify(mobile, otp);
    if (next == null) return false;
    user = next;
    notifyListeners();
    return true;
  }

  void logout() {
    employeeApi?.close();
    employeeApi = null;
    user = null;
    notifyListeners();
  }
}
