import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
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
  final _paypalController = TextEditingController();
  bool _useEmailForPaypal = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_syncPaypalWithEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_syncPaypalWithEmail);
    _storeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _paypalController.dispose();
    super.dispose();
  }

  /// Mantiene el correo de PayPal igual al de la cuenta mientras el interruptor
  /// «Usar el mismo correo» está activo.
  void _syncPaypalWithEmail() {
    if (!_useEmailForPaypal) return;
    final email = _emailController.text.trim();
    if (_paypalController.text == email) return;
    _paypalController.text = email;
  }

  /// Activa o desactiva que PayPal use el mismo correo que la cuenta.
  void _toggleSameEmail(bool value) {
    HapticFeedback.selectionClick();
    setState(() {
      _useEmailForPaypal = value;
      if (value) {
        FocusScope.of(context).unfocus();
        _paypalController.text = _emailController.text.trim();
      }
    });
  }

  /// Reenvía el correo de confirmación desde el propio registro, por si la
  /// cuenta ya existía pero seguía sin confirmar.
  Future<void> _resendConfirmation(String email) async {
    if (email.isEmpty) return;
    final l10n = context.l10n;
    final sent = await context.read<AuthCubit>().resendConfirmationEmail(email);
    if (!mounted) return;
    showRestockSnack(
      context,
      sent ? l10n.authResendEmailSentBody : l10n.errorAuthResendConfirmFailed,
      title: sent ? l10n.authResendEmailSent : l10n.authCreateFailed,
      tone: sent ? RSnackTone.success : RSnackTone.warning,
    );
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
          current.status == AuthStatus.authenticated ||
          (current.error != null && current.error != previous.error),
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
        final error = state.error;
        if (error == null) return;
        // Con la confirmación por correo activada, la cuenta se crea pero no
        // hay sesión: se avisa del éxito y se vuelve a "Iniciar sesión".
        if (error.code == AppErrorCode.authConfirmEmail) {
          showRestockSnack(
            context,
            l10n.describeDetail(error),
            title: l10n.authAccountCreated,
            tone: RSnackTone.success,
          );
          Navigator.of(context).pop();
          return;
        }
        // El alta falló por el límite de correos de Supabase: la cuenta no
        // existe, así que se deja el formulario abierto para reintentar luego.
        if (error.code == AppErrorCode.authSignUpEmailRateLimited) {
          showRestockSnack(
            context,
            l10n.describeDetail(error),
            title: l10n.authCreateFailed,
            tone: RSnackTone.warning,
          );
          return;
        }
        // Si el correo ya existe puede ser una cuenta sin confirmar: se ofrece
        // reenviar el correo desde aquí mismo.
        if (error.code == AppErrorCode.authEmailTaken) {
          showRestockSnack(
            context,
            l10n.describeDetail(error),
            tone: RSnackTone.warning,
            actionLabel: l10n.authResendEmail,
            onAction: () => _resendConfirmation(_emailController.text.trim()),
          );
          return;
        }
        showRestockSnack(
          context,
          l10n.describeDetail(error),
          tone: RSnackTone.warning,
        );
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    RCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: p.blueSoft,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  CupertinoIcons.creditcard,
                                  size: 17,
                                  color: p.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.authPaypalSectionTitle,
                                  style: t.headline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RAuthField(
                            label: l10n.authPaypalEmail,
                            controller: _paypalController,
                            hint: l10n.authPaypalEmailHint,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            readOnly: _useEmailForPaypal,
                            onSubmitted: (_) => _register(),
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.authPaypalEmailHelp, style: t.caption),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.authPaypalSameEmail,
                                  style: t.body,
                                ),
                              ),
                              Semantics(
                                label: l10n.authPaypalSameEmail,
                                child: CupertinoSwitch(
                                  value: _useEmailForPaypal,
                                  activeTrackColor: p.accent,
                                  onChanged: _toggleSameEmail,
                                ),
                              ),
                            ],
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
                      onTap: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
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
    final paypalEmail = _useEmailForPaypal
        ? email
        : _paypalController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      showRestockSnack(
        context,
        l10n.authCreateMissingFieldsBody,
        title: l10n.authMissingFields,
        tone: RSnackTone.warning,
      );
      return;
    }
    if (paypalEmail.isNotEmpty && !paypalEmail.contains('@')) {
      showRestockSnack(
        context,
        l10n.authPaypalEmailInvalid,
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
      paypalMerchantEmail: paypalEmail.isEmpty ? null : paypalEmail,
    );
  }
}
