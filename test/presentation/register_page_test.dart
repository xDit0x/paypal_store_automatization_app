import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:store_automatization_app/domain/usecases/auth/check_auth_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/resend_confirmation_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/send_reset_password_email_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_in_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_out_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/sign_up_usecase.dart';
import 'package:store_automatization_app/domain/usecases/auth/watch_auth_usecase.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';
import 'package:store_automatization_app/presentation/pages/auth/register_page.dart';
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

Widget _register() => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => BlocProvider.value(
    value: _authCubit(),
    child: MaterialApp(
      theme: ThemeData.light(),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RegisterPage(),
    ),
  ),
);

void main() {
  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
  });

  testWidgets('el interruptor copia el correo de la cuenta en PayPal', (
    tester,
  ) async {
    await tester.pumpWidget(_register());
    await tester.pumpAndSettle();

    // Tienda, correo, contraseña, confirmación y PayPal, en ese orden.
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(5));

    await tester.enterText(fields.at(1), 'ana@example.com');
    await tester.ensureVisible(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump();

    final paypal = tester.widget<TextField>(fields.at(4));
    expect(paypal.controller?.text, 'ana@example.com');
    expect(paypal.readOnly, isTrue);

    // Al cambiar el correo de la cuenta, PayPal se mantiene sincronizado.
    await tester.enterText(fields.at(1), 'otra@example.com');
    await tester.pump();
    expect(
      tester.widget<TextField>(fields.at(4)).controller?.text,
      'otra@example.com',
    );
  });

  testWidgets('el interruptor se puede desactivar para editar PayPal', (
    tester,
  ) async {
    await tester.pumpWidget(_register());
    await tester.pumpAndSettle();

    final switchFinder = find.byType(CupertinoSwitch);
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pump();
    await tester.tap(switchFinder);
    await tester.pump();

    final paypal = tester.widget<TextField>(find.byType(TextField).at(4));
    expect(paypal.readOnly, isFalse);
  });
}
