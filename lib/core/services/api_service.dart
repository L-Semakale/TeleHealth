import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';
import '../models.dart';
import '../storage/token_storage.dart';

abstract class ApiService {
  Future<AuthUser> login(String phoneNumber, String password);
  Future<String> register(String fullName, String phoneNumber, String password);
  Future<TriageResult> submitSymptoms(
    List<String> symptoms,
    int durationDays,
    String notes,
  );
  Future<List<Consultation>> consultations({int page = 1, String? status});
  Future<List<ChatMessage>> messages(String consultationId, {int page = 1});
  Future<void> sendMessage(String consultationId, String body);
  Future<List<Referral>> referrals();
  Future<List<Facility>> facilities({String search = ''});
}

class AppException implements Exception {
  final String message;
  final int? status;
  const AppException(this.message, {this.status});
}

class RealApiService implements ApiService {
  RealApiService(this._storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: AppConfig.apiTimeout,
            receiveTimeout: AppConfig.apiTimeout,
            sendTimeout: AppConfig.apiTimeout,
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _storage;

  Never _throwApiError(Object error) {
    if (error is TimeoutException) {
      throw const AppException(
        'Request timed out. Please retry when network is stable.',
      );
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (status == 401) {
        throw const AppException('Session expired. Please login again.', status: 401);
      }
      if (status == 403) {
        throw const AppException('Access denied for this action.', status: 403);
      }
      if (status == 409) {
        throw const AppException('Conflict detected. Please refresh and retry.', status: 409);
      }
      if (data is Map && data['error'] is Map) {
        throw AppException(data['error']['message'] as String? ?? 'Unexpected error', status: status);
      }
      throw AppException(error.message ?? 'Network error', status: status);
    }
    throw const AppException('Unexpected error');
  }

  @override
  Future<AuthUser> login(String phoneNumber, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'phone_number': phoneNumber,
        'password': password,
      });
      final role = (response.data['role'] as String?) ?? 'patient';
      return AuthUser(
        token: response.data['token'] as String? ?? '',
        role: UserRole.values.firstWhere((e) => e.name == role, orElse: () => UserRole.patient),
        anonymousId: response.data['anonymous_id'] as String? ?? '',
        fullName: response.data['full_name'] as String? ?? 'User',
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<String> register(String fullName, String phoneNumber, String password) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'password': password,
      });
      return response.data['anonymous_id'] as String? ?? 'ANON-UNKNOWN';
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<TriageResult> submitSymptoms(List<String> symptoms, int durationDays, String notes) async {
    try {
      final response = await _dio.post('/api/symptoms', data: {
        'symptoms': symptoms,
        'duration_days': durationDays,
        'additional_notes': notes,
      });
      final triage = response.data['triage'] as Map<String, dynamic>;
      return TriageResult(
        classification: triage['classification'] as String? ?? 'routine',
        confidenceScore: (triage['confidence_score'] as num?)?.toDouble() ?? 0,
        recommendedAction: triage['recommended_action'] as String? ?? '',
      );
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<List<Consultation>> consultations({int page = 1, String? status}) async {
    return [];
  }

  @override
  Future<List<ChatMessage>> messages(String consultationId, {int page = 1}) async {
    return [];
  }

  @override
  Future<void> sendMessage(String consultationId, String body) async {}

  @override
  Future<List<Referral>> referrals() async {
    return [];
  }

  @override
  Future<List<Facility>> facilities({String search = ''}) async {
    return [];
  }
}

class MockApiService implements ApiService {
  MockApiService(this._storage);
  final TokenStorage _storage;

  @override
  Future<AuthUser> login(String phoneNumber, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    UserRole role = UserRole.patient;
    if (phoneNumber.endsWith('99')) role = UserRole.admin;
    if (phoneNumber.endsWith('88')) role = UserRole.provider;
    return AuthUser(
      token: 'mock-jwt-token',
      role: role,
      anonymousId: 'ANON-34021',
      fullName: role == UserRole.patient ? 'Patient User' : 'Dashboard User',
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<String> register(String fullName, String phoneNumber, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return 'ANON-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  Future<TriageResult> submitSymptoms(
    List<String> symptoms,
    int durationDays,
    String notes,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final urgent = symptoms.contains('chest pain') || symptoms.contains('shortness of breath');
    return TriageResult(
      classification: urgent ? 'urgent' : 'routine',
      confidenceScore: urgent ? 0.91 : 0.76,
      recommendedAction: urgent
          ? 'Visit a clinic or hospital immediately.'
          : 'Book consultation and monitor symptoms.',
    );
  }

  @override
  Future<List<Consultation>> consultations({int page = 1, String? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final list = List.generate(
      12,
      (i) => Consultation(
        id: 'CONSULT-${page}_$i',
        status: i.isEven ? 'open' : 'closed',
        patientAnonymousId: 'ANON-${2000 + i}',
        providerId: 'PROV-100',
      ),
    );
    if (status == null) return list;
    return list.where((e) => e.status == status).toList();
  }

  @override
  Future<List<ChatMessage>> messages(String consultationId, {int page = 1}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return List.generate(
      10,
      (i) => ChatMessage(
        id: '$consultationId-$page-$i',
        senderRole: i.isEven ? 'provider' : 'patient',
        body: i.isEven ? 'Please share your recent symptoms.' : 'I am having persistent cough.',
        createdAt: DateTime.now().subtract(Duration(minutes: i * page)),
      ),
    );
  }

  @override
  Future<void> sendMessage(String consultationId, String body) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<List<Referral>> referrals() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return [
      Referral(
        facilityName: 'City Health Center',
        address: '12 Main Road',
        phone: '+266500001',
        notes: 'Chest x-ray recommended.',
        issuedDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<Facility>> facilities({String search = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final data = [
      const Facility(
        id: 'FAC-1',
        name: 'City Health Center',
        address: '12 Main Road',
        phone: '+266500001',
        latitude: -29.3167,
        longitude: 27.4833,
      ),
      const Facility(
        id: 'FAC-2',
        name: 'Sunrise Clinic',
        address: '89 Green Street',
        phone: '+266500002',
        latitude: -29.3000,
        longitude: 27.4100,
      ),
    ];
    final filtered = data
        .where((f) => f.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
    await _storage.cacheFacilities(
      jsonEncode(
        filtered
            .map((e) => {
                  'id': e.id,
                  'name': e.name,
                  'address': e.address,
                  'phone': e.phone,
                  'latitude': e.latitude,
                  'longitude': e.longitude,
                })
            .toList(),
      ),
    );
    return filtered;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return AppConfig.useMockApi ? MockApiService(storage) : RealApiService(storage);
});
