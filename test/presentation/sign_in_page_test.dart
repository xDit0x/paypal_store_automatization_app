import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:store_automatization_app/core/configs/assets/app_assets.dart';
import 'package:store_automatization_app/domain/usecases/auth/check_auth_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/send_reset_password_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/resend_confirmation_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_in_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_out_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_up_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/watch_auth_usecase.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/pages/auth/sign_in_page.dart';
import 'package:store_automatization_app/preview/preview_repositories.dart';

class _MemoryStorage implements Storage {
  final _box = <String, dynamic>{};

  @override
  dynamic read(String key) => _box[key];

  @override
  Future<void> write(String key, dynamic value) async => _box[key] = value;

  @override
  Future<void> delete(String key) async => _box.remove(key);

  @override
  Future<void> clear() async => _box.clear();

  @override
  Future<void> close() async {}
}

AuthCubit _authCubit() {
  final auth = PreviewAuthRepository();
  return AuthCubit(
    signInUseCase: SignInUsecase(repository: auth),
    signUpUseCase: SignUpUsecase(repository: auth),
    signOutUseCase: SignOutUsecase(repository: auth),
    checkAuthUseCase: CheckAuthUsecase(repository: auth),
    watchAuthUseCase: WatchAuthUsecase(repository: auth),
    sendResetPasswordEmailUseCase: SendResetPasswordEmailUsecase(
      repository: auth,
    ),
    resendConfirmationEmailUseCase: ResendConfirmationEmailUsecase(
      repository: auth,
    ),
  );
}

Widget _signIn({Locale locale = const Locale('es')}) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => BlocProvider.value(
    value: _authCubit(),
    child: MaterialApp(
      theme: ThemeData.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SignInPage(),
    ),
  ),
);

/// Nombres de los assets que se están pintando en pantalla.
Iterable<String> _paintedAssets(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => image.image)
    .whereType<AssetImage>()
    .map((provider) => provider.assetName);

void main() {
  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
  });

  testWidgets('el inicio de sesión muestra el icono real de Restock', (
    tester,
  ) async {
    await tester.pumpWidget(_signIn());
    await tester.pumpAndSettle();

    expect(_paintedAssets(tester), contains(AppAssets.logo));
    expect(find.text('Restock'), findsOneWidget);
    expect(find.text('Pedidos automáticos con IA + PayPal'), findsOneWidget);
  });

  testWidgets('el inicio de sesión traduce la marca al inglés', (tester) async {
    await tester.pumpWidget(_signIn(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(_paintedAssets(tester), contains(AppAssets.logo));
    expect(find.text('Automatic orders with AI + PayPal'), findsOneWidget);
  });
}
