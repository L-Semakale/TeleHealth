import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/services/api_service.dart';

class AdminState {
  final bool loading;
  final String? error;
  final List<AdminUser> users;
  final List<Consultation> consultations;
  final List<Facility> facilities;
  final TriageAnalytics? analytics;
  final SystemHealth? health;
  final int usersPage;
  final bool hasMoreUsers;

  const AdminState({
    this.loading = false,
    this.error,
    this.users = const [],
    this.consultations = const [],
    this.facilities = const [],
    this.analytics,
    this.health,
    this.usersPage = 1,
    this.hasMoreUsers = true,
  });

  AdminState copyWith({
    bool? loading,
    String? error,
    List<AdminUser>? users,
    List<Consultation>? consultations,
    List<Facility>? facilities,
    TriageAnalytics? analytics,
    SystemHealth? health,
    int? usersPage,
    bool? hasMoreUsers,
  }) {
    return AdminState(
      loading: loading ?? this.loading,
      error: error,
      users: users ?? this.users,
      consultations: consultations ?? this.consultations,
      facilities: facilities ?? this.facilities,
      analytics: analytics ?? this.analytics,
      health: health ?? this.health,
      usersPage: usersPage ?? this.usersPage,
      hasMoreUsers: hasMoreUsers ?? this.hasMoreUsers,
    );
  }
}

class AdminController extends StateNotifier<AdminState> {
  AdminController(this._api) : super(const AdminState());
  final ApiService _api;

  Future<void> loadDashboard() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final analytics = await _api.triageAnalytics();
      final health = await _api.systemHealth();
      final consults = await _api.adminConsultations();
      state = state.copyWith(
        loading: false,
        analytics: analytics,
        consultations: consults,
        health: health,
      );
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> loadUsers({bool refresh = false}) async {
    if (state.loading) return;
    final page = refresh ? 1 : state.usersPage;
    state = state.copyWith(loading: true, error: null);
    try {
      final users = await _api.adminUsers(page: page, limit: 20);
      state = state.copyWith(
        loading: false,
        users: refresh ? users : [...state.users, ...users],
        usersPage: page + 1,
        hasMoreUsers: users.isNotEmpty,
      );
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> setProviderRole(String userId) async {
    try {
      await _api.assignProviderRole(userId);
      await loadUsers(refresh: true);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _api.setUserStatus(userId, isActive);
      await loadUsers(refresh: true);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> loadFacilities({String search = ''}) async {
    try {
      final facilities = await _api.facilities(search: search);
      state = state.copyWith(facilities: facilities);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> createFacility(Facility facility) async {
    try {
      await _api.addFacility(facility);
      await loadFacilities();
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> editFacility(Facility facility) async {
    try {
      await _api.updateFacility(facility);
      await loadFacilities();
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> removeFacility(String id) async {
    try {
      await _api.deleteFacility(id);
      await loadFacilities();
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> loadHealth() async {
    try {
      final health = await _api.systemHealth();
      state = state.copyWith(health: health);
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }
}

final adminControllerProvider = StateNotifierProvider<AdminController, AdminState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AdminController(api);
});
