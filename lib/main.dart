import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:store_automatization_app/core/configs/env.dart';
import 'package:store_automatization_app/core/configs/supabase/supabase_config.dart';
import 'package:store_automatization_app/core/configs/theme/app_theme.dart';
import 'package:store_automatization_app/core/service_locator.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_in_usecase.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:store_automatization_app/presentation/pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  try {
    await SupabaseConfig.initialize();
    await initializeDependencies();
    await _signInDemoIfConfigured();
    runApp(const RestockApp());
  } catch (error) {
    runApp(ConfigErrorApp(message: error.toString()));
  }
}

Future<void> _signInDemoIfConfigured() async {
  if (Env.demoEmail.isEmpty || Env.demoPassword.isEmpty) return;
  if (SupabaseConfig.client.auth.currentUser != null) return;

  final result = await sl<SignInUsecase>()(Env.demoEmail, Env.demoPassword);
  result.fold(
    (error) => debugPrint('No se pudo iniciar sesión demo: $error'),
    (_) {},
  );
}

class RestockApp extends StatelessWidget {
  const RestockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => sl<AuthCubit>()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return MaterialApp(
              title: 'Restock',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              home: const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Configuración incompleta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
