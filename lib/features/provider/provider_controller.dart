import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/services/api_service.dart';

class ProviderState {
  final bool loading;
  final String? error;
  final List<Consultation> consultations;
  final List<ChatMessage> messages;
  final int consultationPage;
  final int messagePage;
  final bool hasMoreConsultations;
  final bool hasMoreMessages;
  final String? selectedConsultationId;
  final List<ProviderSchedule> schedules;
  final List<Appointment> appointments;
  final List<Facility> facilities;

  const ProviderState({
    this.loading = false,
    this.error,
    this.consultations = const [],
    this.messages = const [],
    this.consultationPage = 1,
    this.messagePage = 1,
    this.hasMoreConsultations = true,
    this.hasMoreMessages = true,
    this.selectedConsultationId,
    this.schedules = const [],
    this.appointments = const [],
    this.facilities = const [],
  });

  ProviderState copyWith({
    bool? loading,
    String? error,
    List<Consultation>? consultations,
    List<ChatMessage>? messages,
    int? consultationPage,
    int? messagePage,
    bool? hasMoreConsultations,
    bool? hasMoreMessages,
    String? selectedConsultationId,
    List<ProviderSchedule>? schedules,
    List<Appointment>? appointments,
    List<Facility>? facilities,
  }) {
    return ProviderState(
      loading: loading ?? this.loading,
      error: error,
      consultations: consultations ?? this.consultations,
      messages: messages ?? this.messages,
      consultationPage: consultationPage ?? this.consultationPage,
      messagePage: messagePage ?? this.messagePage,
      hasMoreConsultations: hasMoreConsultations ?? this.hasMoreConsultations,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      selectedConsultationId: selectedConsultationId ?? this.selectedConsultationId,
      schedules: schedules ?? this.schedules,
      appointments: appointments ?? this.appointments,
      facilities: facilities ?? this.facilities,
    );
  }
}

class ProviderController extends StateNotifier<ProviderState> {
  ProviderController(this._api) : super(const ProviderState()) {
    loadConsultations(refresh: true);
  }
  final ApiService _api;

  Future<void> loadConsultations({bool refresh = false, String? status}) async {
    if (state.loading) return;
    final page = refresh ? 1 : state.consultationPage;
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.consultations(page: page, status: status);
      final combined = refresh ? result : [...state.consultations, ...result];
      state = state.copyWith(
        loading: false,
        consultations: combined,
        consultationPage: page + 1,
        hasMoreConsultations: result.isNotEmpty,
      );
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> selectConsultation(String consultationId, {bool refresh = true}) async {
    final page = refresh ? 1 : state.messagePage;
    state = state.copyWith(loading: true, error: null, selectedConsultationId: consultationId);
    try {
      final result = await _api.messages(consultationId, page: page);
      final merged = refresh ? result : [...state.messages, ...result];
      state = state.copyWith(
        loading: false,
        messages: merged,
        messagePage: page + 1,
        hasMoreMessages: result.isNotEmpty,
      );
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> sendMessage(String text) async {
    final consultationId = state.selectedConsultationId;
    if (consultationId == null || text.trim().isEmpty) return;
    try {
      await _api.sendMessage(consultationId, text.trim());
      await selectConsultation(consultationId);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> closeConsultation(String consultationId) async {
    try {
      await _api.closeConsultation(consultationId);
      await loadConsultations(refresh: true);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> issueReferral(String consultationId, String facilityId, String notes) async {
    try {
      await _api.issueReferral(consultationId, facilityId, notes);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> loadFacilitiesForReferral() async {
    try {
      final data = await _api.facilities();
      state = state.copyWith(facilities: data);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
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

  Future<void> loadProviderSchedule() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.getProviderSchedule();
      state = state.copyWith(loading: false, schedules: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> addSchedule({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.addProviderSchedule(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
      await loadProviderSchedule();
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> updateSchedule(String scheduleId, {
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.updateProviderSchedule(
        scheduleId,
        startTime: startTime,
        endTime: endTime,
        isAvailable: isAvailable,
      );
      await loadProviderSchedule();
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.deleteProviderSchedule(scheduleId);
      await loadProviderSchedule();
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> loadProviderAppointments({int page = 1, String? status}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.getProviderAppointments(page: page, status: status);
      state = state.copyWith(loading: false, appointments: data);
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> confirmAppointment(String appointmentId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.confirmAppointment(appointmentId);
      await loadProviderAppointments();
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> completeAppointment(String appointmentId, {String? notes}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.completeAppointment(appointmentId, notes: notes);
      await loadProviderAppointments();
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }
}

final providerControllerProvider = StateNotifierProvider<ProviderController, ProviderState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ProviderController(api);
});
