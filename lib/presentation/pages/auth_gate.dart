import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_state.dart';
import 'package:store_automatization_app/presentation/pages/auth/sign_in_page.dart';
import 'package:store_automatization_app/presentation/pages/shell/restock_shell.dart';
import 'package:store_automatization_app/presentation/pages/splash/splash_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const SplashPage();
          case AuthStatus.authenticated:
            return const RestockShell();
          case AuthStatus.unauthenticated:
          case AuthStatus.loading:
            return const SignInPage();
        }
      },
    );
  }
}
