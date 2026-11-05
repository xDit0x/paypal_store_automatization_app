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

  test('arranca en inglés por defecto', () {
    expect(LocaleCubit().state, const Locale('en'));
    expect(LocaleCubit().effectiveLocale.languageCode, 'en');
  });

  test('guarda y recupera el idioma elegido', () {
    final cubit = LocaleCubit();

    // "Auto" se guarda para que siga el idioma del dispositivo.
    expect(cubit.toJson(null), {'locale': 'auto'});
    expect(cubit.toJson(const Locale('en')), {'locale': 'en'});
    expect(cubit.toJson(const Locale('es')), {'locale': 'es'});

    expect(cubit.fromJson({'locale': 'en'}), const Locale('en'));
    expect(cubit.fromJson({'locale': 'es'}), const Locale('es'));
    expect(cubit.fromJson({'locale': 'auto'}), isNull);
    // Un idioma que ya no se ofrece vuelve al de por defecto.
    expect(cubit.fromJson({'locale': 'fr'}), const Locale('en'));
    expect(cubit.fromJson(const {}), const Locale('en'));
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
