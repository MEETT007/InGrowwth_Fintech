import '../../../services/pan_lookup_service.dart';
import '../../../core/constants/demo_config.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});
  final AuthController auth;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  String? error;
  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> getOtp() async {
    if (!widget.auth.repository.validMobile(phone.text)) {
      setState(() => error = S.invalidMobile);
      return;
    }
    setState(() => error = null);
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SizedBox(
          width: 508,
          child: OtpDialog(auth: widget.auth, mobile: phone.text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackdrop(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.home_rounded,
                    size: 52,
                    color: AppColors.deepBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    S.brand,
                    style: AppTextStyles.responsive(
                      context,
                      AppTextStyles.title,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    S.loginTitle,
                    style: AppTextStyles.responsive(
                      context,
                      AppTextStyles.heading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.loginBody,
                    style: AppTextStyles.responsive(
                      context,
                      AppTextStyles.caption,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 108,
                        child: AppDropdown<String>(
                          compact: true,
                          value: '+91',
                          label: S.country,
                          options: const {'+91': '+91'},
                          onChanged: (_) {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phone,
                          style: AppTextStyles.body,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onSubmitted: (_) => getOtp(),
                          decoration: InputDecoration(
                            labelText: S.mobile,
                            error: error == null
                                ? null
                                : Text(error!, softWrap: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: getOtp,
                      child: Text(S.getOtp),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const InfoNote(S.demoOtp),
                  const SizedBox(height: 48),
                  const InfoNote(S.offline),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class OtpDialog extends StatefulWidget {
  const OtpDialog({super.key, required this.auth, required this.mobile});
  final AuthController auth;
  final String mobile;
  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final code = TextEditingController();
  String? error;
  bool resent = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  bool verifying = false;
  Future<void> verify() async {
    if (verifying) return;
    if (widget.mobile == DemoConfig.specialMobile &&
        code.text == DemoConfig.otp) {
      setState(() => verifying = true);
      final api = PanLookupService();
      try {
        await api.signIn(widget.mobile, code.text);
        if (!mounted) {
          api.close();
          return;
        }
        widget.auth.employeeApi = api;
      } catch (_) {
        api.close();
        if (mounted) {
          setState(() {
            verifying = false;
            error = 'Employee sign-in failed. Start the backend and try again.';
          });
        }
        return;
      }
    }
    if (!mounted) return;
    if (widget.auth.verify(widget.mobile, code.text)) {
      Navigator.pop(context);
    } else {
      setState(() => error = S.invalidOtp);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      S.verifyTitle,
                      style: AppTextStyles.responsive(
                        context,
                        AppTextStyles.title,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: S.close,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(S.phone(widget.mobile)),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                controller: code,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => verify(),
                decoration: InputDecoration(
                  labelText: S.otpLabel,
                  error: error == null ? null : Text(error!, softWrap: true),
                ),
              ),
              const SizedBox(height: 16),
              const InfoNote(S.demoOtp),
              if (resent) const InfoNote(S.resent),
              TextButton(
                onPressed: () => setState(() {
                  code.clear();
                  error = null;
                  resent = true;
                }),
                child: Text(S.resend),
              ),
              FilledButton(
                onPressed: verifying ? null : verify,
                child: Text(verifying ? 'Signing in…' : S.verify),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

