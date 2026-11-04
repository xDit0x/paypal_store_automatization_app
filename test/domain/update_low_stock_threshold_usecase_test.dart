import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/usecases/catalog/update_low_stock_threshold_usecase.dart';
import 'package:store_automatization_app/preview/preview_repositories.dart';

void main() {
  late PreviewDb db;
  late UpdateLowStockThresholdUsecase usecase;

  setUp(() {
    db = PreviewDb();
    usecase = UpdateLowStockThresholdUsecase(
      repository: PreviewProductRepository(db),
    );
  });

  test('guarda el mínimo de bajo stock del producto', () async {
    final product = db.products.first;

    final result = await usecase(db.store.id, product.uid, 42);

    expect(result.isRight(), isTrue);
    final saved = db.products.firstWhere((p) => p.uid == product.uid);
    expect(saved.lowStockThreshold, 42);
  });

  test('el producto pasa a estar bajo mínimo con el nuevo umbral', () async {
    final product = db.products.firstWhere((p) => p.stock > 0);
    final stock = product.stock;

    // Con el umbral por encima del stock, el producto queda bajo mínimo.
    await usecase(db.store.id, product.uid, stock + 5);

    final saved = db.products.firstWhere((p) => p.uid == product.uid);
    expect(saved.isLowStock, isTrue);
  });

  test('rechaza un mínimo negativo', () async {
    final result = await usecase(db.store.id, db.products.first.uid, -1);

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.code, AppErrorCode.stockNegative),
      (_) => fail('debería fallar'),
    );
  });

  test('rechaza una tienda vacía', () async {
    final result = await usecase('', db.products.first.uid, 5);

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.code, AppErrorCode.storeNotFound),
      (_) => fail('debería fallar'),
    );
  });

  test('rechaza un producto sin UID', () async {
    final result = await usecase(db.store.id, '', 5);

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.code, AppErrorCode.productMissing),
      (_) => fail('debería fallar'),
    );
  });
}
