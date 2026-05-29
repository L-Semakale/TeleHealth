import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/services/api_service.dart';
import '../../core/storage/token_storage.dart';

class AuthState {
  final AuthUser? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  AuthState copyWith({AuthUser? user, bool? loading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api, this._storage) : super(const AuthState()) {
    hydrate();
  }
  final ApiService _api;
  final TokenStorage _storage;

  Future<void> hydrate() async {
    final token = await _storage.getToken();
    final meta = await _storage.getUserMeta();
    if (token == null) return;
    final role = UserRole.values.firstWhere(
      (e) => e.name == (meta['role'] ?? 'patient'),
      orElse: () => UserRole.patient,
    );
    state = state.copyWith(
      user: AuthUser(
        token: token,
        role: role,
        anonymousId: meta['anonymous_id'] ?? '',
        fullName: meta['full_name'] ?? 'User',
        phoneNumber: meta['phone_number'] ?? '',
      ),
    );
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _api.login(phone, password);
      await _storage.saveAuth(
        token: user.token,
        role: user.role.name,
        anonymousId: user.anonymousId,
        fullName: user.fullName,
        phone: user.phoneNumber,
      );
      state = state.copyWith(loading: false, user: user, error: null);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    }
  }

  Future<String?> register(String fullName, String phone, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final anonymousId = await _api.register(fullName, phone, password);
      state = state.copyWith(loading: false);
      return anonymousId;
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState();
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _api.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      final current = state.user;
      if (current != null) {
        final updated = AuthUser(
          token: current.token,
          role: current.role,
          anonymousId: current.anonymousId,
          fullName: fullName ?? current.fullName,
          phoneNumber: phoneNumber ?? current.phoneNumber,
        );
        await _storage.saveAuth(
          token: updated.token,
          role: updated.role.name,
          anonymousId: updated.anonymousId,
          fullName: updated.fullName,
          phone: updated.phoneNumber,
        );
        state = state.copyWith(loading: false, user: updated);
      } else {
        state = state.copyWith(loading: false);
      }
      return true;
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(tokenStorageProvider);
  return AuthController(api, storage);
});
