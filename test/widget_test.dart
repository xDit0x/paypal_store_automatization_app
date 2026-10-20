import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/core/configs/assets/app_assets.dart';
import 'package:store_automatization_app/core/configs/theme/app_theme.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/pages/splash/splash_page.dart';

Widget _splash({Locale locale = const Locale('es')}) => MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashPage(),
    );

void main() {
  testWidgets('Splash muestra la marca Restock', (WidgetTester tester) async {
    await tester.pumpWidget(_splash());

    expect(find.text('Restock'), findsOneWidget);
    expect(find.text('Pedidos automáticos con IA + PayPal'), findsOneWidget);
  });

  testWidgets('Splash traduce el lema al inglés', (WidgetTester tester) async {
    await tester.pumpWidget(_splash(locale: const Locale('en')));

    expect(find.text('Automatic orders with AI + PayPal'), findsOneWidget);
  });

  testWidgets('Splash muestra el logo de la app', (WidgetTester tester) async {
    await tester.pumpWidget(_splash());

    final Image logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, AppAssets.logoForeground);
  });
}
