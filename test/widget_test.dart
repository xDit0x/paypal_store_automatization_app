import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/core/configs/theme/app_theme.dart';
import 'package:store_automatization_app/presentation/pages/splash/splash_page.dart';

void main() {
  testWidgets('Splash muestra la marca Restock', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const SplashPage()),
    );

    expect(find.text('Restock'), findsOneWidget);
    expect(find.text('Pedidos automáticos con IA + PayPal'), findsOneWidget);
  });
}
