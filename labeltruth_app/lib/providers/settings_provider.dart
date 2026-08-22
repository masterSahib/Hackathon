import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';

class SettingsState {
  final bool avoidPalmOil;
  final bool diabeticMode;
  final bool lowSodium;
  final bool vegan;
  final bool avoidArtificialSweeteners;
  final List<String> allergies;
  final String backendUrl;

  SettingsState({
    this.avoidPalmOil = true,
    this.diabeticMode = false,
    this.lowSodium = false,
    this.vegan = false,
    this.avoidArtificialSweeteners = true,
    this.allergies = const [],
    this.backendUrl = ApiEndpoints.defaultBaseUrl,
  });

  SettingsState copyWith({
    bool? avoidPalmOil,
    bool? diabeticMode,
    bool? lowSodium,
    bool? vegan,
    bool? avoidArtificialSweeteners,
    List<String>? allergies,
    String? backendUrl,
  }) {
    return SettingsState(
      avoidPalmOil: avoidPalmOil ?? this.avoidPalmOil,
      diabeticMode: diabeticMode ?? this.diabeticMode,
      lowSodium: lowSodium ?? this.lowSodium,
      vegan: vegan ?? this.vegan,
      avoidArtificialSweeteners: avoidArtificialSweeteners ?? this.avoidArtificialSweeteners,
      allergies: allergies ?? this.allergies,
      backendUrl: backendUrl ?? this.backendUrl,
    );
  }

  Map<String, dynamic> toDietaryPreferencesMap() => {
    'avoid_palm_oil': avoidPalmOil,
    'diabetic_mode': diabeticMode,
    'low_sodium': lowSodium,
    'vegan': vegan,
    'avoid_artificial_sweeteners': avoidArtificialSweeteners,
    'allergies': allergies,
  };
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        avoidPalmOil: prefs.getBool('avoid_palm_oil') ?? true,
        diabeticMode: prefs.getBool('diabetic_mode') ?? false,
        lowSodium: prefs.getBool('low_sodium') ?? false,
        vegan: prefs.getBool('vegan') ?? false,
        avoidArtificialSweeteners: prefs.getBool('avoid_sweeteners') ?? true,
        allergies: prefs.getStringList('allergies') ?? [],
        backendUrl: prefs.getString('backend_url') ?? ApiEndpoints.defaultBaseUrl,
      );
    } catch (_) {}
  }

  Future<void> updateAvoidPalmOil(bool val) async {
    state = state.copyWith(avoidPalmOil: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('avoid_palm_oil', val);
  }

  Future<void> updateDiabeticMode(bool val) async {
    state = state.copyWith(diabeticMode: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('diabetic_mode', val);
  }

  Future<void> updateLowSodium(bool val) async {
    state = state.copyWith(lowSodium: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('low_sodium', val);
  }

  Future<void> updateVegan(bool val) async {
    state = state.copyWith(vegan: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vegan', val);
  }

  Future<void> updateAvoidArtificialSweeteners(bool val) async {
    state = state.copyWith(avoidArtificialSweeteners: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('avoid_sweeteners', val);
  }

  Future<void> toggleAllergy(String allergen) async {
    final list = List<String>.from(state.allergies);
    if (list.contains(allergen)) {
      list.remove(allergen);
    } else {
      list.add(allergen);
    }
    state = state.copyWith(allergies: list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('allergies', list);
  }

  Future<void> updateBackendUrl(String url) async {
    state = state.copyWith(backendUrl: url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_url', url);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
