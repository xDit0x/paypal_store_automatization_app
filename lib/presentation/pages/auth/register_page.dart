import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_state.dart';
import 'package:store_automatization_app/presentation/pages/auth/auth_widgets.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

/// Alta de cuenta: nombre de la tienda, correo y contraseña.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _storeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _storeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
            state.error!,
            title: l10n.authCreateFailed,
            tone: RSnackTone.warning,
          );
        }
      },
      child: Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RBackLink(l10n.actionSignIn),
                    ),
                    const SizedBox(height: 6),
                    RLargeTitle(
                      l10n.authCreateTitle,
                      subtitle: l10n.authCreateSubtitle,
                    ),
                    const SizedBox(height: 22),
                    RCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RAuthField(
                            label: l10n.authStoreName,
                            controller: _storeController,
                            hint: l10n.authStoreNameHint,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthField(
                            label: l10n.authEmail,
                            controller: _emailController,
                            hint: l10n.authEmailHint,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthPasswordField(
                            label: l10n.authPassword,
                            controller: _passwordController,
                            hint: l10n.authPasswordHint,
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthPasswordField(
                            label: l10n.authConfirmPassword,
                            controller: _confirmController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _register(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    RPrimaryButton(
                      l10n.actionCreateMyStore,
                      loading: isLoading,
                      onPressed: isLoading ? null : _register,
                    ),
                    const SizedBox(height: 6),
                    RTextLink(
                      l10n.actionAlreadyHaveAccount,
                      onTap: isLoading ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.authCreateFooter,
                      textAlign: TextAlign.center,
                      style: t.caption,
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

  Future<void> _register() async {
    HapticFeedback.mediumImpact();
    final l10n = context.l10n;
    final storeName = _storeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      showRestockSnack(
        context,
        l10n.authCreateMissingFieldsBody,
        title: l10n.authMissingFields,
        tone: RSnackTone.warning,
      );
      return;
    }
    if (password.length < 6) {
      showRestockSnack(
        context,
        l10n.authPasswordTooShort,
        title: l10n.authPasswordTooShortTitle,
        tone: RSnackTone.warning,
      );
      return;
    }
    if (password != confirm) {
      showRestockSnack(
        context,
        l10n.authPasswordsMismatch,
        title: l10n.authPasswordsMismatchTitle,
        tone: RSnackTone.warning,
      );
      return;
    }

    await context.read<AuthCubit>().signUp(
      email,
      password,
      storeName: storeName.isEmpty ? null : storeName,
    );
  }
}
