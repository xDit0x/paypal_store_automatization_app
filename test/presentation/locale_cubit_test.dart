import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:store_automatization_app/presentation/blocs/locale/locale_cubit.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
  });

  test('arranca en "Auto": sin Locale propio', () {
    expect(LocaleCubit().state, isNull);
  });

  test('guarda y recupera el idioma elegido', () {
    final cubit = LocaleCubit();

    expect(cubit.toJson(null), isNull);
    expect(cubit.toJson(const Locale('en')), {'locale': 'en'});

    expect(cubit.fromJson({'locale': 'en'}), const Locale('en'));
    expect(cubit.fromJson({'locale': 'es'}), const Locale('es'));
    // Un idioma que ya no se ofrece vuelve a "Auto".
    expect(cubit.fromJson({'locale': 'fr'}), isNull);
    expect(cubit.fromJson(const {}), isNull);
  });

  test('los textos siguen al idioma elegido', () {
    final cubit = LocaleCubit();

    cubit.updateLocale(const Locale('en'));
    expect(cubit.l10n.tabRules, 'Rules');

    cubit.updateLocale(const Locale('es'));
    expect(cubit.l10n.tabRules, 'Reglas');

    cubit.updateLocale(null);
    expect(cubit.effectiveLocale, isNotNull);
  });
}
