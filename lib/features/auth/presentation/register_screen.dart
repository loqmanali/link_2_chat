import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_text_field.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/auth/application/auth_providers.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The inline validation errors of the register form, the same pattern as the
/// sign-in form. Null where the field is valid or not yet validated.
final registerFormErrorsProvider = NotifierProvider<
  RegisterFormErrors,
  ({String? name, String? email, String? password, String? confirm})
>(RegisterFormErrors.new);

class RegisterFormErrors
    extends
        Notifier<
          ({String? name, String? email, String? password, String? confirm})
        > {
  @override
  ({String? name, String? email, String? password, String? confirm}) build() =>
      (name: null, email: null, password: null, confirm: null);

  void show({
    required String? name,
    required String? email,
    required String? password,
    required String? confirm,
  }) =>
      state = (name: name, email: email, password: password, confirm: confirm);

  void clear() =>
      state = (name: null, email: null, password: null, confirm: null);
}

/// The account creation screen. The passwords-mismatch rule is checked here,
/// before the action; the six-character minimum lives in the action.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _emailController,
      _passwordController,
      _confirmController,
    ]) {
      controller.addListener(
        () => ref.read(registerFormErrorsProvider.notifier).clear(),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final errors = (
      name: _nameController.text.trim().isEmpty ? l10n.authNameRequired : null,
      email: _emailError(l10n, email),
      password: password.isEmpty ? l10n.authRegisterPasswordRequired : null,
      confirm:
          _confirmController.text.isEmpty
              ? l10n.authConfirmPasswordRequired
              : _confirmController.text == password
              ? null
              : l10n.authPasswordsMismatch,
    );
    if (errors.name != null ||
        errors.email != null ||
        errors.password != null ||
        errors.confirm != null) {
      ref
          .read(registerFormErrorsProvider.notifier)
          .show(
            name: errors.name,
            email: errors.email,
            password: errors.password,
            confirm: errors.confirm,
          );
      return;
    }
    ref
        .read(signUpActionProvider.notifier)
        .signUp(
          name: _nameController.text.trim(),
          email: email,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final errors = ref.watch(registerFormErrorsProvider);
    final creating = ref.watch(signUpActionProvider).isLoading;
    ref.listen(signUpActionProvider, (previous, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authRegisterTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: l10n.authFullNameLabel,
                errorText: errors.name,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _emailController,
                label: l10n.authEmailLabel,
                errorText: errors.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _passwordController,
                label: l10n.authPasswordLabel,
                errorText: errors.password,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _confirmController,
                label: l10n.authConfirmPasswordLabel,
                errorText: errors.confirm,
                obscureText: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label:
                    creating
                        ? l10n.authCreatingAccount
                        : l10n.authRegisterTitle,
                isLoading: creating,
                onPressed: creating ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.authPasswordTooShort,
                style: TextStyle(color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The same email rule as the sign-in screen: required, then a plain shape
/// check. The sentence comes from l10n.
String? _emailError(AppLocalizations l10n, String value) {
  if (value.isEmpty) return l10n.authEmailRequired;
  final valid = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  return valid ? null : l10n.authEmailInvalid;
}
