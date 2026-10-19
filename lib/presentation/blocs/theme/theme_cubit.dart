import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void updateTheme(ThemeMode themeMode) => emit(themeMode);

  void toggleTheme() =>
      emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    final index = json['themeMode'];
    if (index is! int || index < 0 || index >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[index];
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    return {'themeMode': state.index};
  }
}
