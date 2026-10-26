import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Si la app puede sonar.
///
/// Solo guarda la preferencia: quien la aplica al motor de audio es la app,
/// para que este cubit se pueda probar sin tarjeta de sonido.
class SoundCubit extends HydratedCubit<bool> {
  SoundCubit() : super(true);

  void updateEnabled(bool value) => emit(value);

  void toggle() => emit(!state);

  @override
  bool? fromJson(Map<String, dynamic> json) {
    final value = json['sounds'];
    return value is bool ? value : true;
  }

  @override
  Map<String, dynamic>? toJson(bool state) => {'sounds': state};
}
