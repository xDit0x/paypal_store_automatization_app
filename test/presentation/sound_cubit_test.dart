import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:store_automatization_app/presentation/blocs/sound/sound_cubit.dart';

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

  test('los sonidos vienen activados', () {
    expect(SoundCubit().state, isTrue);
  });

  test('guarda y recupera la preferencia', () {
    final cubit = SoundCubit();

    expect(cubit.toJson(true), {'sounds': true});
    expect(cubit.fromJson({'sounds': false}), isFalse);
    // Un valor corrupto no deja la app en silencio sin querer.
    expect(cubit.fromJson(const {}), isTrue);
    expect(cubit.fromJson({'sounds': 'no'}), isTrue);
  });

  test('toggle cambia el estado', () {
    final cubit = SoundCubit();

    cubit.toggle();
    expect(cubit.state, isFalse);

    cubit.updateEnabled(true);
    expect(cubit.state, isTrue);
  });
}
