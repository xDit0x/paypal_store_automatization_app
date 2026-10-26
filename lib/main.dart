import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:store_automatization_app/core/audio/restock_sounds.dart';
import 'package:store_automatization_app/core/configs/env.dart';
import 'package:store_automatization_app/core/configs/supabase/supabase_config.dart';
import 'package:store_automatization_app/core/configs/theme/app_theme.dart';
import 'package:store_automatization_app/core/service_locator.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_in_usecase.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/sound/sound_cubit.dart';
import 'package:store_automatization_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:store_automatization_app/presentation/pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sin audio (navegador sin permisos, plataforma rara) la app sigue.
  try {
    await SoLoud.instance.init();
  } catch (error) {
    debugPrint('No se pudo inicializar el audio: $error');
  }

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
    // Las ondas se generan al arrancar para que el primer toque no tarde.
    RestockSounds.instance.enabled = sl<SoundCubit>().state;
    await RestockSounds.instance.warmUp();
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
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(create: (_) => sl<AuthCubit>()),
          BlocProvider.value(value: sl<SoundCubit>()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return BlocBuilder<LocaleCubit, Locale?>(
              builder: (context, locale) => MaterialApp(
                title: 'Restock',
                // `null` = el Locale del dispositivo; con un Locale elegido
                // se fuerza ese idioma.
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                home: BlocListener<SoundCubit, bool>(
                  listenWhen: (previous, current) => previous != current,
                  listener: (context, enabled) {
                    RestockSounds.instance.enabled = enabled;
                    if (enabled) RestockSounds.instance.play(RSound.success);
                  },
                  child: const AuthGate(),
                ),
              ),
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
                Text(
                  'Config error: unable to start app.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  textAlign: TextAlign.center,
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
