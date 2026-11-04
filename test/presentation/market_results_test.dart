import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/data/models/market_model.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';
import 'package:store_automatization_app/presentation/widgets/market/market_results.dart';

const _offerJson = {
  'offerId': 'o1', 'distributorName': 'Hafen Naturkost', 'country': 'DE', 'city': 'Hamburgo',
  'currency': 'EUR', 'website': 'https://hafennaturkost.example', 'rating': 4.7, 'leadDays': 6,
  'productName': 'Avena 1 L', 'unit': 'L', 'notes': null, 'unitPrice': 1.45, 'minQty': 24,
  'packSize': 12, 'orderQty': 48, 'extraUnits': 8, 'goodsEur': 69.6, 'shippingEur': 0,
  'dutiesEur': 0, 'totalEur': 69.6, 'unitLandedEur': 1.45, 'outsideEu': false,
  'tags': ['cheapest'], 'overBudget': false,
};

MarketResearch _research({required bool demo}) => MarketModel.research({
  'searchId': 's1', 'query': 'avena', 'region': 'europe', 'monthlyQuantity': 40,
  'productName': 'Avena 1 L', 'compared': 3, 'countries': ['DE'],
  'offers': [_offerJson], 'webResults': [], 'fxSource': 'live',
  'demoDirectory': demo,
});

Widget _app(WidgetTester tester, MarketResearch research) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: MarketResults(research: research, onChoose: (_) {})),
    ),
  );
}

void main() {
  test('el modelo lee si el directorio es de demostración', () {
    expect(_research(demo: true).demoDirectory, isTrue);
    expect(_research(demo: false).demoDirectory, isFalse);
  });

  testWidgets('avisa de que los distribuidores son de demostración', (tester) async {
    await tester.pumpWidget(_app(tester, _research(demo: true)));
    await tester.pumpAndSettle();

    expect(find.text('Demo'), findsWidgets);
    expect(
      find.text('Demo directory: the distributors and their prices are fictional.'),
      findsOneWidget,
    );
  });

  testWidgets('sin directorio de demostración no aparece el aviso', (tester) async {
    await tester.pumpWidget(_app(tester, _research(demo: false)));
    await tester.pumpAndSettle();

    expect(find.text('Demo'), findsNothing);
    expect(
      find.text('Demo directory: the distributors and their prices are fictional.'),
      findsNothing,
    );
  });
}
