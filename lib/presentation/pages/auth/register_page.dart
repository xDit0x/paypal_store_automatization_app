import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            title: 'No se pudo crear la cuenta',
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
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: RBackLink('Iniciar sesión'),
                    ),
                    const SizedBox(height: 6),
                    const RLargeTitle(
                      'Crear cuenta',
                      subtitle: 'Crea tu tienda y empieza a reponer en segundos',
                    ),
                    const SizedBox(height: 22),
                    RCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RAuthField(
                            label: 'Nombre de tu tienda',
                            controller: _storeController,
                            hint: 'Tienda Lumbre',
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthField(
                            label: 'Correo',
                            controller: _emailController,
                            hint: 'tu@tienda.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthPasswordField(
                            label: 'Contraseña',
                            controller: _passwordController,
                            hint: 'Mínimo 6 caracteres',
                          ),
                          const SizedBox(height: 14),
                          Divider(height: 1, color: p.separator),
                          const SizedBox(height: 14),
                          RAuthPasswordField(
                            label: 'Repite la contraseña',
                            controller: _confirmController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _register(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    RPrimaryButton(
                      'Crear mi tienda',
                      loading: isLoading,
                      onPressed: isLoading ? null : _register,
                    ),
                    const SizedBox(height: 6),
                    RTextLink(
                      'Ya tengo cuenta',
                      onTap: isLoading ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Crear la tienda es gratis. Solo pagas los pedidos que el agente '
                      'prepare y tú apruebes, dentro de tus reglas.',
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
    final storeName = _storeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      showRestockSnack(
        context,
        'Completa el correo y las dos contraseñas.',
        title: 'Faltan datos',
        tone: RSnackTone.warning,
      );
      return;
    }
    if (password.length < 6) {
      showRestockSnack(
        context,
        'La contraseña debe tener al menos 6 caracteres.',
        title: 'Contraseña corta',
        tone: RSnackTone.warning,
      );
      return;
    }
    if (password != confirm) {
      showRestockSnack(
        context,
        'Las contraseñas no coinciden.',
        title: 'No coinciden',
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
