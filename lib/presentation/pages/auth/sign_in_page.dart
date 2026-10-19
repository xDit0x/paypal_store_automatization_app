import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            title: 'No se pudo iniciar sesión',
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
                      'Pedidos automáticos con IA + PayPal',
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
                            label: 'Correo',
                            controller: _emailController,
                            hint: 'tu@tienda.com',
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthPasswordField(
                            label: 'Contraseña',
                            controller: _passwordController,
                            hint: 'Mínimo 6 caracteres',
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signIn(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    RPrimaryButton(
                      'Iniciar sesión',
                      loading: isLoading,
                      onPressed: isLoading ? null : _signIn,
                    ),
                    const SizedBox(height: 6),
                    RTextLink(
                      '¿Olvidaste tu contraseña?',
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
                            '¿Primera vez en Restock?',
                            style: t.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Crea tu tienda y deja que el agente reponga el stock.',
                            style: t.footnote,
                          ),
                          const SizedBox(height: 10),
                          RTextLink(
                            'Crear una cuenta',
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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showRestockSnack(
        context,
        'Completa el correo y la contraseña.',
        title: 'Faltan datos',
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
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showRestockSnack(
        context,
        'Escribe tu correo primero.',
        title: 'Falta el correo',
        tone: RSnackTone.warning,
      );
      return;
    }

    await context.read<AuthCubit>().sendResetPasswordEmail(email);
    if (!mounted) return;
    showRestockSnack(
      context,
      'Si el correo existe, te enviamos un enlace de recuperación.',
      title: 'Correo enviado',
      tone: RSnackTone.success,
    );
  }
}
