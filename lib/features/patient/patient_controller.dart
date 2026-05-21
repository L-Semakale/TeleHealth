import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models.dart';
import '../../core/services/api_service.dart';

class PatientDataState {
  final bool loading;
  final String? error;
  final TriageResult? triage;
  final List<Consultation> consultations;
  final List<Referral> referrals;
  final List<Facility> facilities;

  const PatientDataState({
    this.loading = false,
    this.error,
    this.triage,
    this.consultations = const [],
    this.referrals = const [],
    this.facilities = const [],
  });

  PatientDataState copyWith({
    bool? loading,
    String? error,
    TriageResult? triage,
    List<Consultation>? consultations,
    List<Referral>? referrals,
    List<Facility>? facilities,
  }) {
    return PatientDataState(
      loading: loading ?? this.loading,
      error: error,
      triage: triage ?? this.triage,
      consultations: consultations ?? this.consultations,
      referrals: referrals ?? this.referrals,
      facilities: facilities ?? this.facilities,
    );
  }
}

class PatientController extends StateNotifier<PatientDataState> {
  PatientController(this._api) : super(const PatientDataState()) {
    _attemptSyncOfflineSymptoms();
  }
  static const _offlineSymptomsKey = 'offline_symptom_queue';
  final ApiService _api;

  Future<TriageResult?> submitSymptoms(
    List<String> symptoms,
    int durationDays,
    String notes,
  ) async {
    state = state.copyWith(loading: true, error: null);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      await _queueOfflineSymptoms(symptoms, durationDays, notes);
      state = state.copyWith(loading: false, error: null);
      return null;
    }
    try {
      final triage = await _api.submitSymptoms(symptoms, durationDays, notes);
      state = state.copyWith(loading: false, triage: triage);
      return triage;
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return null;
    }
  }

  Future<void> _queueOfflineSymptoms(
    List<String> symptoms,
    int durationDays,
    String notes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_offlineSymptomsKey) ?? [];
    raw.add(jsonEncode({
      'symptoms': symptoms,
      'duration_days': durationDays,
      'additional_notes': notes,
    }));
    await prefs.setStringList(_offlineSymptomsKey, raw);
  }

  Future<void> _attemptSyncOfflineSymptoms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_offlineSymptomsKey) ?? [];
    if (raw.isEmpty) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;
    for (final item in raw) {
      final payload = jsonDecode(item) as Map<String, dynamic>;
      await _api.submitSymptoms(
        List<String>.from(payload['symptoms'] as List),
        payload['duration_days'] as int,
        payload['additional_notes'] as String,
      );
    }
    await prefs.remove(_offlineSymptomsKey);
  }

  Future<void> loadConsultations({int page = 1}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.consultations(page: page);
      state = state.copyWith(loading: false, consultations: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> loadReferrals() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.referrals();
      state = state.copyWith(loading: false, referrals: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> loadFacilities({String search = ''}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.facilities(search: search);
      state = state.copyWith(loading: false, facilities: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }
}

final patientControllerProvider =
    StateNotifierProvider<PatientController, PatientDataState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PatientController(api);
});
