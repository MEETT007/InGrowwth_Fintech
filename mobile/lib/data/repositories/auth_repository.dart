import '../../core/constants/demo_config.dart';
import '../../models/user_model.dart';

class AuthRepository {
  bool validMobile(String mobile) => RegExp(r'^[6-9]\d{9}$').hasMatch(mobile);
  UserModel? verify(String mobile, String otp) =>
      validMobile(mobile) && otp == DemoConfig.otp
      ? UserModel(
          mobile: mobile,
          name: 'Aarav',
          isSpecial: mobile == DemoConfig.specialMobile,
        )
      : null;
}
