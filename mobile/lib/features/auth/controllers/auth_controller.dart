import '../../../services/pan_lookup_service.dart';
import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../models/user_model.dart';

class AuthController extends GetxController {
  final repository = AuthRepository();
  UserModel? user;
  PanLookupService? employeeApi;
  bool verify(String mobile, String otp) {
    final next = repository.verify(mobile, otp);
    if (next == null) return false;
    user = next;
    update();
    return true;
  }

  void logout() {
    employeeApi?.close();
    employeeApi = null;
    user = null;
    update();
  }

  @override
  void onClose() {
    employeeApi?.close();
    employeeApi = null;
    super.onClose();
  }
}
