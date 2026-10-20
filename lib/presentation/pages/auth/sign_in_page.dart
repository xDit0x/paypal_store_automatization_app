import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_state.dart';
import 'package:store_automatization_app/presentation/pages/auth/auth_widgets.dart';
import 'package:store_automatization_app/presentation/pages/auth/register_page.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Inicio de sesión con el estilo de la app: marca, tarjeta con los campos
/// y los avisos flotantes nuevos.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final l10n = context.l10n;
    final isLoading =
        context.watch<AuthCubit>().state.status == AuthStatus.loading;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current.error != null && current.error != previous.error,
      listener: (context, state) {
        if (state.error != null) {
          showRestockSnack(
            context,
            l10n.describeDetail(state.error!),
            tone: RSnackTone.warning,
          );
        }
      },
      child: Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: RBrandMark()),
                    const SizedBox(height: 18),
                    Text(
                      'Restock',
                      textAlign: TextAlign.center,
                      style: t.largeTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.appTagline,
                      textAlign: TextAlign.center,
                      style: t.subhead,
                    ),
                    const SizedBox(height: 30),
                    RCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RAuthField(
                            label: l10n.authEmail,
                            controller: _emailController,
                            hint: l10n.authEmailHint,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthPasswordField(
                            label: l10n.authPassword,
                            controller: _passwordController,
                            hint: l10n.authPasswordHint,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signIn(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    RPrimaryButton(
                      l10n.actionSignIn,
                      loading: isLoading,
                      onPressed: isLoading ? null : _signIn,
                    ),
                    const SizedBox(height: 6),
                    RTextLink(
                      l10n.actionForgotPassword,
                      onTap: isLoading ? null : _forgotPassword,
                    ),
                    const SizedBox(height: 18),
                    RCard(
                      color: p.blueSoft,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.authFirstTime,
                            style: t.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.authFirstTimeBody,
                            style: t.footnote,
                          ),
                          const SizedBox(height: 10),
                          RTextLink(
                            l10n.actionCreateAccount,
                            onTap: isLoading ? null : _openRegister,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    HapticFeedback.mediumImpact();
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showRestockSnack(
        context,
        l10n.authMissingFieldsBody,
        title: l10n.authMissingFields,
        tone: RSnackTone.warning,
      );
      return;
    }

    await context.read<AuthCubit>().signIn(email, password);
  }

  void _openRegister() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
    );
  }

  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showRestockSnack(
        context,
        l10n.authMissingEmailBody,
        title: l10n.authMissingEmail,
        tone: RSnackTone.warning,
      );
      return;
    }

    await context.read<AuthCubit>().sendResetPasswordEmail(email);
    if (!mounted) return;
    showRestockSnack(
      context,
      l10n.authEmailSentBody,
      title: l10n.authEmailSent,
      tone: RSnackTone.success,
    );
  }
}
