import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:link_2_chat/core/design/app_context.dart';
import 'package:link_2_chat/core/design/app_radii.dart';
import 'package:link_2_chat/core/design/app_spacing.dart';
import 'package:link_2_chat/core/design/components/app_button.dart';
import 'package:link_2_chat/core/design/components/app_text_field.dart';
import 'package:link_2_chat/core/ui/failure_toast.dart';
import 'package:link_2_chat/features/auth/application/auth_providers.dart';
import 'package:link_2_chat/features/auth/presentation/routes.dart';
import 'package:link_2_chat/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The inline validation errors of the sign-in form: an error sentence per
/// field, resolved in the app language on submit and cleared on the next
/// keystroke. Null where the field is valid or not yet validated.
final signInFormErrorsProvider =
    NotifierProvider<SignInFormErrors, ({String? email, String? password})>(
      SignInFormErrors.new,
    );

class SignInFormErrors extends Notifier<({String? email, String? password})> {
  @override
  ({String? email, String? password}) build() => (email: null, password: null);

  void show({required String? email, required String? password}) =>
      state = (email: email, password: password);

  void clear() => state = (email: null, password: null);
}

/// The entry screen: email + password against the device-local accounts, or
/// guest mode. Success navigation is the router's redirect, so this screen
/// never calls `go` after an action.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // One keystroke clears both errors; they reappear on the next submit.
    _emailController.addListener(
      () => ref.read(signInFormErrorsProvider.notifier).clear(),
    );
    _passwordController.addListener(
      () => ref.read(signInFormErrorsProvider.notifier).clear(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = _emailError(l10n, email);
    final passwordError = password.isEmpty ? l10n.authPasswordRequired : null;
    if (emailError != null || passwordError != null) {
      ref
          .read(signInFormErrorsProvider.notifier)
          .show(email: emailError, password: passwordError);
      return;
    }
    ref
        .read(signInActionProvider.notifier)
        .signIn(email: email, password: password);
  }

  void _enterAsGuest() {
    ref.read(guestSignInActionProvider.notifier).enterAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errors = ref.watch(signInFormErrorsProvider);
    final signingIn = ref.watch(signInActionProvider).isLoading;
    ref.listen(signInActionProvider, (previous, next) {
      if (isFreshFailure(next)) showFailureToast(context, next.error!);
    });
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const _AuthHeader(),
              const SizedBox(height: AppSpacing.xxl),
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
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: signingIn ? l10n.authLoggingIn : l10n.authLogin,
                isLoading: signingIn,
                onPressed: signingIn ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.go(authRegisterPath),
                  child: Text(l10n.authNoAccount),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton(
                onPressed: _enterAsGuest,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Text(l10n.authContinueAsGuest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The logo, the app title and the tagline shared by the public screens.
class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Center(
      child: Column(
        children: [
          Icon(Icons.link, size: 80, color: colors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.primary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.authTagline,
            style: TextStyle(color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The email rule carried over from the pre-refactor screens: required, then
/// a plain shape check. The sentence comes from l10n.
String? _emailError(AppLocalizations l10n, String value) {
  if (value.isEmpty) return l10n.authEmailRequired;
  final valid = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  return valid ? null : l10n.authEmailInvalid;
}
