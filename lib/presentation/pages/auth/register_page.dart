import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/common/widgets/util_snackbar.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_state.dart';
import 'package:store_automatization_app/presentation/widgets/password_textfield.dart';

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
        appBar: AppBar(
          title: Text('Crear cuenta', style: TextStyle(color: scheme.onSurface)),
          backgroundColor: scheme.surface,
        ),
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
                    TextField(
                      controller: _storeController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Nombre de tu tienda',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      hint: 'Contraseña (mínimo 6 caracteres)',
                    ),
                    const SizedBox(height: 14),
                    PasswordTxtField(
                      controller: _confirmController,
                      hint: 'Repite la contraseña',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _register(),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: isLoading ? null : _register,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Registrarme'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Ya tengo cuenta'),
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
    final storeName = _storeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      UtilSnackbar.show(
        context,
        'Completa todos los campos',
        selection: UtilSnackbarType.warning,
      );
      return;
    }
    if (password.length < 6) {
      UtilSnackbar.show(
        context,
        'La contraseña debe tener al menos 6 caracteres',
        selection: UtilSnackbarType.warning,
      );
      return;
    }
    if (password != confirm) {
      UtilSnackbar.show(
        context,
        'Las contraseñas no coinciden',
        selection: UtilSnackbarType.bad,
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
