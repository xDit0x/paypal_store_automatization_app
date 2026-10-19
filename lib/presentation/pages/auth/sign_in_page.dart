import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/widgets/util_snackbar.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_state.dart';
import 'package:store_automatization_app/presentation/pages/auth/register_page.dart';
import 'package:store_automatization_app/presentation/widgets/password_textfield.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final isLoading =
        context.watch<AuthCubit>().state.status == AuthStatus.loading;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current.error != null && current.error != previous.error,
      listener: (context, state) {
        if (state.error != null) {
          UtilSnackbar.show(
            context,
            state.error!,
            selection: UtilSnackbarType.bad,
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Restock',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pedidos automáticos con IA + PayPal',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Correo',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PasswordTxtField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _signIn(),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: isLoading ? null : _signIn,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: isLoading ? null : _openRegister,
                      child: const Text('Crear una cuenta'),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : _forgotPassword,
                      child: const Text('¿Olvidaste tu contraseña?'),
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
      UtilSnackbar.show(
        context,
        'Completa todos los campos',
        selection: UtilSnackbarType.warning,
      );
      return;
    }

    await context.read<AuthCubit>().signIn(email, password);
  }

  void _openRegister() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      UtilSnackbar.show(
        context,
        'Escribe tu correo primero',
        selection: UtilSnackbarType.warning,
      );
      return;
    }

    await context.read<AuthCubit>().sendResetPasswordEmail(email);
    if (!mounted) return;
    UtilSnackbar.show(
      context,
      'Si el correo existe, te enviamos un enlace de recuperación',
      selection: UtilSnackbarType.ok,
    );
  }
}
