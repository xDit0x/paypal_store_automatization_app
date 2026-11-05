import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/widgets/market/adopt_sheet.dart';

MarketOption _option() => const MarketOption(
  offerId: 'o1',
  distributorName: 'Horta Verda',
  country: 'ES',
  city: 'Valencia',
  currency: 'EUR',
  website: null,
  rating: 4.6,
  leadDays: 2,
  productName: 'Avena 1 L',
  unit: 'L',
  notes: null,
  unitPrice: 1.2,
  minQty: 24,
  packSize: 12,
  orderQty: 24,
  extraUnits: 0,
  goodsEur: 28.8,
  shippingEur: 0,
  dutiesEur: 0,
  totalEur: 28.8,
  unitLandedEur: 1.2,
  outsideEu: false,
  tags: [MarketTag.cheapest],
  overBudget: false,
);

Future<AdoptChoice?> _openSheet(WidgetTester tester) async {
  AdoptChoice? result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showAdoptSheet(
                  context,
                  option: _option(),
                  monthlyQuantity: 40,
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('la cantidad de unidades al mes se puede escribir', (
    tester,
  ) async {
    AdoptChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showAdoptSheet(
                    context,
                    option: _option(),
                    monthlyQuantity: 40,
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Viene con la cantidad que se dijo en el chat.
    expect(find.text('40'), findsOneWidget);

    // Y se puede escribir a mano.
    await tester.enterText(find.byType(TextField), '120');
    await tester.pumpAndSettle();
    expect(find.text('120'), findsOneWidget);

    await tester.tap(find.text('Añadir a mi tienda'));
    await tester.pumpAndSettle();

    expect(result?.quantity, 120);
  });

  testWidgets('los botones siguen cambiando la cantidad escrita', (
    tester,
  ) async {
    await _openSheet(tester);

    await tester.tap(find.byIcon(CupertinoIcons.plus).first);
    await tester.pumpAndSettle();

    // 40 + 12 (tamaño de caja) = 52, y el campo refleja el cambio.
    expect(find.text('52'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.minus).first);
    await tester.pumpAndSettle();
    expect(find.text('40'), findsOneWidget);
  });
}
