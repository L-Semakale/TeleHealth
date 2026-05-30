import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models.dart';
import '../../core/services/api_service.dart';
import '../../core/storage/token_storage.dart';

class PatientDataState {
  final bool loading;
  final String? error;
  final TriageResult? triage;
  final String? lastReportId;
  final List<Consultation> consultations;
  final List<Referral> referrals;
  final List<Facility> facilities;
  final List<Appointment> appointments;
  final List<AvailableProvider> availableProviders;

  const PatientDataState({
    this.loading = false,
    this.error,
    this.triage,
    this.lastReportId,
    this.consultations = const [],
    this.referrals = const [],
    this.facilities = const [],
    this.appointments = const [],
    this.availableProviders = const [],
  });

  PatientDataState copyWith({
    bool? loading,
    String? error,
    TriageResult? triage,
    String? lastReportId,
    List<Consultation>? consultations,
    List<Referral>? referrals,
    List<Facility>? facilities,
    List<Appointment>? appointments,
    List<AvailableProvider>? availableProviders,
  }) {
    return PatientDataState(
      loading: loading ?? this.loading,
      error: error,
      triage: triage ?? this.triage,
      lastReportId: lastReportId ?? this.lastReportId,
      consultations: consultations ?? this.consultations,
      referrals: referrals ?? this.referrals,
      facilities: facilities ?? this.facilities,
      appointments: appointments ?? this.appointments,
      availableProviders: availableProviders ?? this.availableProviders,
    );
  }
}

class PatientController extends StateNotifier<PatientDataState> {
  PatientController(this._api, this._storage) : super(const PatientDataState()) {
    _init();
  }
  static const _offlineSymptomsKey = 'offline_symptom_queue';
  final ApiService _api;
  final TokenStorage _storage;

  Future<void> _init() async {
    await _attemptSyncOfflineSymptoms();
    await Future.wait([
      loadConsultations(),
      loadReferrals(),
      loadFacilities(),
    ]);
  }

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
      state = state.copyWith(
        loading: false,
        triage: triage,
        lastReportId: triage.reportId,
      );
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
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      final cached = await _storage.getCachedFacilities();
      if (cached != null) {
        final items = (jsonDecode(cached) as List<dynamic>)
            .map((e) => Facility(
                  id: e['id'] as String? ?? '',
                  name: e['name'] as String? ?? '',
                  address: e['address'] as String? ?? '',
                  phone: e['phone'] as String? ?? '',
                  latitude: (e['latitude'] as num?)?.toDouble() ?? 0,
                  longitude: (e['longitude'] as num?)?.toDouble() ?? 0,
                ))
            .toList();
        state = state.copyWith(loading: false, facilities: items);
      } else {
        state = state.copyWith(loading: false, error: 'No connection. Cached data unavailable.');
      }
      return;
    }
    try {
      final data = await _api.facilities(search: search);
      state = state.copyWith(loading: false, facilities: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<List<ChatMessage>> loadMessages(String consultationId) async {
    return _api.messages(consultationId);
  }

  Future<void> sendMessage(String consultationId, String body) async {
    await _api.sendMessage(consultationId, body);
  }

  Future<Consultation?> startConsultation({String? reportId}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final consultation = await _api.startConsultation(
        reportId: reportId ?? state.lastReportId,
      );
      state = state.copyWith(
        loading: false,
        consultations: [consultation, ...state.consultations],
      );
      return consultation;
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return null;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      await _api.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> markReferralViewed(String referralId) async {
    try {
      await _api.markReferralViewed(referralId);
      final updated = state.referrals.map((r) {
        if (r.id == referralId) {
          return Referral(
            id: r.id,
            facilityName: r.facilityName,
            address: r.address,
            phone: r.phone,
            notes: r.notes,
            issuedDate: r.issuedDate,
            status: ReferralStatus.viewed,
          );
        }
        return r;
      }).toList();
      state = state.copyWith(referrals: updated);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> loadAppointments({int page = 1, String? status}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.getMyAppointments(page: page, status: status);
      state = state.copyWith(loading: false, appointments: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> loadAvailableProviders({DateTime? date}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.getAvailableProviders(date: date);
      state = state.copyWith(loading: false, availableProviders: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<Appointment?> bookAppointment({
    required String providerId,
    String? facilityId,
    required DateTime scheduledAt,
    int duration = 30,
    String type = 'in_person',
    String? notes,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final appointment = await _api.bookAppointment(
        providerId: providerId,
        facilityId: facilityId,
        scheduledAt: scheduledAt,
        duration: duration,
        type: type,
        notes: notes,
      );
      state = state.copyWith(
        loading: false,
        appointments: [appointment, ...state.appointments],
      );
      return appointment;
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return null;
    }
  }

  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.cancelAppointment(appointmentId, reason: reason);
      final updated = state.appointments.map((a) {
        if (a.id == appointmentId) {
          return Appointment(
            id: a.id,
            patientId: a.patientId,
            providerId: a.providerId,
            providerName: a.providerName,
            facilityId: a.facilityId,
            facilityName: a.facilityName,
            facilityAddress: a.facilityAddress,
            scheduledAt: a.scheduledAt,
            duration: a.duration,
            status: AppointmentStatus.cancelled,
            type: a.type,
            notes: a.notes,
            createdAt: a.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return a;
      }).toList();
      state = state.copyWith(loading: false, appointments: updated);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }
}

final patientControllerProvider =
    StateNotifierProvider<PatientController, PatientDataState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(tokenStorageProvider);
  return PatientController(api, storage);
});
