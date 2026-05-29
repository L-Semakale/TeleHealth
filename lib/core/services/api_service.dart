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
  Future<void> closeConsultation(String consultationId);
  Future<void> issueReferral(String consultationId, String facilityId, String notes);
  Future<List<AdminUser>> adminUsers({int page = 1, int limit = 20});
  Future<void> assignProviderRole(String userId);
  Future<void> setUserStatus(String userId, bool isActive);
  Future<TriageAnalytics> triageAnalytics();
  Future<SystemHealth> systemHealth();
  Future<Facility> addFacility(Facility facility);
  Future<Facility> updateFacility(Facility facility);
  Future<void> deleteFacility(String facilityId);
  Future<void> markReferralViewed(String referralId);
  Future<Consultation> startConsultation({String? reportId});
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  });
  Future<List<Consultation>> adminConsultations({String? status});
}

class AppException implements Exception {
  final String message;
  final int? status;
  const AppException(this.message, {this.status});
}

class RealApiService implements ApiService {
  RealApiService(this._storage, {this.onUnauthorized})
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
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _storage;
  final void Function()? onUnauthorized;

  List<Consultation> _mapConsultations(dynamic data) {
    final items = data is Map<String, dynamic>
        ? (data['consultations'] as List<dynamic>? ?? [])
        : (data as List<dynamic>? ?? []);
    return items.map(_mapConsultation).toList();
  }

  Consultation _mapConsultation(dynamic e) {
    final m = e as Map<String, dynamic>;
    final created = m['created_at'] ?? m['started_at'];
    return Consultation(
      id: m['consultation_id'] as String? ?? '',
      status: m['status'] as String? ?? 'open',
      patientAnonymousId: m['patient_anonymous_id'] as String? ?? '',
      providerId: m['assigned_provider_id'] as String? ?? m['provider_id'] as String? ?? '',
      triageClassification: m['triage_classification'] as String? ?? 'routine',
      createdAt: DateTime.tryParse(created?.toString() ?? '') ?? DateTime.now(),
      lastMessageAt: m['last_message_at'] != null
          ? DateTime.tryParse(m['last_message_at'].toString())
          : null,
      lastMessagePreview: m['last_message_preview'] as String? ?? '',
      unreadCount: m['unread_count'] as int? ?? 0,
    );
  }

  List<ChatMessage> _mapMessages(dynamic data) {
    final items = data is Map<String, dynamic>
        ? (data['messages'] as List<dynamic>? ?? [])
        : (data as List<dynamic>? ?? []);
    return items
        .map((e) {
          final m = e as Map<String, dynamic>;
          final sent = m['sent_at'] ?? m['created_at'];
          return ChatMessage(
            id: m['id'] as String? ?? m['message_id'] as String? ?? '',
            senderRole: m['sender_role'] as String? ?? 'patient',
            body: m['body'] as String? ?? '',
            createdAt: DateTime.tryParse(sent?.toString() ?? '') ?? DateTime.now(),
          );
        })
        .toList();
  }

  List<Referral> _mapReferrals(dynamic data) {
    final items = data is Map<String, dynamic>
        ? (data['referrals'] as List<dynamic>? ?? [])
        : (data as List<dynamic>? ?? []);
    return items
        .map((e) {
          final m = e as Map<String, dynamic>;
          final issued = m['issued_at'] ?? m['issued_date'];
          return Referral(
            id: m['id'] as String? ?? m['referral_id'] as String? ?? '',
            facilityName: m['facility_name'] as String? ?? '',
            address: m['address'] as String? ?? m['facility_address'] as String? ?? '',
            phone: m['phone'] as String? ?? m['facility_phone'] as String? ?? '',
            notes: m['notes'] as String? ?? '',
            issuedDate: DateTime.tryParse(issued?.toString() ?? '') ?? DateTime.now(),
            status: (m['status'] as String?) == 'viewed'
                ? ReferralStatus.viewed
                : ReferralStatus.newReferral,
          );
        })
        .toList();
  }

  List<Facility> _mapFacilities(dynamic data) {
    final items = data is Map<String, dynamic>
        ? (data['facilities'] as List<dynamic>? ?? [])
        : (data as List<dynamic>? ?? []);
    return items
        .map((e) {
          final m = e as Map<String, dynamic>;
          return Facility(
            id: m['id'] as String? ?? m['facility_id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            address: m['address'] as String? ?? '',
            phone: m['phone'] as String? ?? '',
            latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList();
  }

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
        reportId: response.data['report_id'] as String?,
      );
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<List<Consultation>> consultations({int page = 1, String? status}) async {
    try {
      final response = await _dio.get('/api/consultations', queryParameters: {
        'page': page,
        if (status != null) 'status': status,
      });
      return _mapConsultations(response.data);
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<List<ChatMessage>> messages(String consultationId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/api/consultations/$consultationId/messages',
        queryParameters: {'page': page},
      );
      return _mapMessages(response.data);
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> sendMessage(String consultationId, String body) async {
    try {
      await _dio.post('/api/consultations/$consultationId/messages', data: {'body': body});
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<List<Referral>> referrals() async {
    try {
      final response = await _dio.get('/api/referrals');
      return _mapReferrals(response.data);
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> markReferralViewed(String referralId) async {
    try {
      await _dio.put('/api/referrals/$referralId/viewed');
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<List<Facility>> facilities({String search = ''}) async {
    try {
      final response = await _dio.get('/api/facilities', queryParameters: {'search': search});
      return _mapFacilities(response.data);
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> closeConsultation(String consultationId) async {
    try {
      await _dio.put('/api/consultations/$consultationId/close');
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> issueReferral(String consultationId, String facilityId, String notes) async {
    try {
      await _dio.post('/api/consultations/$consultationId/referrals', data: {'facility_id': facilityId, 'notes': notes});
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<List<AdminUser>> adminUsers({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/api/admin/users', queryParameters: {'page': page, 'limit': limit});
      final items = (response.data['users'] as List<dynamic>? ?? []);
      return items
          .map((e) {
            final m = e as Map<String, dynamic>;
            return AdminUser(
              id: m['id'] as String? ?? m['user_id'] as String? ?? '',
              fullName: m['full_name'] as String? ?? '',
              phoneNumber: m['phone_number'] as String? ?? '',
              role: m['role'] as String? ?? 'patient',
              createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
              isActive: m['is_active'] as bool? ?? true,
            );
          })
          .toList();
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> assignProviderRole(String userId) async {
    try {
      await _dio.put('/api/admin/users/$userId/role', data: {'role': 'provider'});
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> setUserStatus(String userId, bool isActive) async {
    try {
      await _dio.put('/api/admin/users/$userId/status', data: {'is_active': isActive});
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<TriageAnalytics> triageAnalytics() async {
    try {
      final response = await _dio.get('/api/admin/analytics/triage');
      final d = response.data as Map<String, dynamic>;
      final byClass = d['by_classification'] as Map<String, dynamic>? ?? {};
      return TriageAnalytics(
        totalReports: d['total_reports'] as int? ?? 0,
        urgent: (byClass['urgent'] as num?)?.toInt() ?? (d['urgent'] as int? ?? 0),
        routine: (byClass['routine'] as num?)?.toInt() ?? (d['routine'] as int? ?? 0),
        selfCare: (byClass['self-care'] as num?)?.toInt() ?? (d['self_care'] as int? ?? 0),
        averageConfidence: (d['average_confidence_score'] as num?)?.toDouble() ?? 0,
        last7Days: d['reports_last_7_days'] as int? ?? d['last_7_days'] as int? ?? 0,
      );
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<SystemHealth> systemHealth() async {
    try {
      final response = await _dio.get('/api/admin/health');
      final d = response.data as Map<String, dynamic>;
      return SystemHealth(
        apiStatus: d['api_status'] as String? ?? 'unknown',
        databaseStatus: d['database_status'] as String? ?? 'unknown',
        mlServiceStatus: d['ml_service_status'] as String? ?? 'unknown',
        redisStatus: d['redis_status'] as String? ?? 'unknown',
        uptimeSeconds: d['uptime_seconds'] as int? ?? 0,
      );
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<Facility> addFacility(Facility facility) async {
    try {
      final response = await _dio.post('/api/admin/facilities', data: {
        'name': facility.name,
        'address': facility.address,
        'phone': facility.phone,
        'latitude': facility.latitude,
        'longitude': facility.longitude,
      });
      final d = response.data as Map<String, dynamic>;
      return Facility(
        id: d['id'] as String? ?? d['facility_id'] as String? ?? '',
        name: d['name'] as String? ?? facility.name,
        address: d['address'] as String? ?? facility.address,
        phone: d['phone'] as String? ?? facility.phone,
        latitude: (d['latitude'] as num?)?.toDouble() ?? facility.latitude,
        longitude: (d['longitude'] as num?)?.toDouble() ?? facility.longitude,
      );
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<Facility> updateFacility(Facility facility) async {
    try {
      final response = await _dio.put('/api/admin/facilities/${facility.id}', data: {
        'name': facility.name,
        'address': facility.address,
        'phone': facility.phone,
        'latitude': facility.latitude,
        'longitude': facility.longitude,
      });
      final d = response.data as Map<String, dynamic>;
      return Facility(
        id: d['id'] as String? ?? facility.id,
        name: d['name'] as String? ?? facility.name,
        address: d['address'] as String? ?? facility.address,
        phone: d['phone'] as String? ?? facility.phone,
        latitude: (d['latitude'] as num?)?.toDouble() ?? facility.latitude,
        longitude: (d['longitude'] as num?)?.toDouble() ?? facility.longitude,
      );
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> deleteFacility(String facilityId) async {
    try {
      await _dio.delete('/api/admin/facilities/$facilityId');
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<Consultation> startConsultation({String? reportId}) async {
    try {
      final response = await _dio.post('/api/consultations', data: {
        if (reportId != null) 'report_id': reportId,
      });
      return _mapConsultation(response.data);
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      await _dio.put('/api/users/profile', data: {
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
      });
    } catch (e) {
      _throwApiError(e);
    }
  }

  @override
  Future<List<Consultation>> adminConsultations({String? status}) async {
    try {
      final response = await _dio.get(
        '/api/admin/consultations',
        queryParameters: {if (status != null) 'status': status},
      );
      return _mapConsultations(response.data);
    } catch (e) {
      _throwApiError(e);
    }
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
    final triageOptions = ['urgent', 'routine', 'routine', 'self-care'];
    final previews = [
      'I have been having chest pain since yesterday.',
      'The fever has not gone down for 3 days.',
      'Feeling better but still have a mild cough.',
      'I ran out of my prescription, need a refill.',
    ];
    final list = List.generate(
      12,
      (i) => Consultation(
        id: 'CONSULT-${page}_$i',
        status: i < 8 ? 'open' : 'closed',
        patientAnonymousId: 'ANON-${2000 + i}',
        providerId: 'PROV-100',
        triageClassification: triageOptions[i % triageOptions.length],
        createdAt: DateTime.now().subtract(Duration(hours: (i + 1) * 2)),
        lastMessageAt: DateTime.now().subtract(Duration(minutes: (i + 1) * 15)),
        lastMessagePreview: previews[i % previews.length],
        unreadCount: i.isEven ? (i % 4) : 0,
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
  Future<void> closeConsultation(String consultationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> issueReferral(String consultationId, String facilityId, String notes) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<Referral>> referrals() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return [
      Referral(
        id: 'REF-001',
        facilityName: 'City Health Center',
        address: '12 Main Road',
        phone: '+266500001',
        notes: 'Chest x-ray recommended. Present this referral at the radiology desk.',
        issuedDate: DateTime.now().subtract(const Duration(days: 1)),
        status: ReferralStatus.newReferral,
      ),
      Referral(
        id: 'REF-002',
        facilityName: 'Sunrise Specialist Clinic',
        address: '45 Hospital Road',
        phone: '+266500003',
        notes: 'Follow-up for blood pressure monitoring.',
        issuedDate: DateTime.now().subtract(const Duration(days: 5)),
        status: ReferralStatus.viewed,
      ),
    ];
  }

  @override
  Future<void> markReferralViewed(String referralId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
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

  @override
  Future<List<AdminUser>> adminUsers({int page = 1, int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return List.generate(
      limit,
      (i) => AdminUser(
        id: 'USER-${page}_$i',
        fullName: 'User ${((page - 1) * limit) + i}',
        phoneNumber: '+2665000${((page - 1) * limit) + i}',
        role: i % 4 == 0 ? 'provider' : 'patient',
        createdAt: DateTime.now().subtract(Duration(days: i)),
        isActive: i.isEven,
      ),
    );
  }

  @override
  Future<void> assignProviderRole(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<void> setUserStatus(String userId, bool isActive) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<TriageAnalytics> triageAnalytics() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const TriageAnalytics(
      totalReports: 8401,
      urgent: 593,
      routine: 5302,
      selfCare: 2506,
      averageConfidence: 0.81,
      last7Days: 446,
    );
  }

  @override
  Future<SystemHealth> systemHealth() async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return const SystemHealth(
      apiStatus: 'healthy',
      databaseStatus: 'healthy',
      mlServiceStatus: 'degraded',
      redisStatus: 'healthy',
      uptimeSeconds: 981234,
    );
  }

  @override
  Future<Facility> addFacility(Facility facility) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return Facility(
      id: 'FAC-${DateTime.now().millisecondsSinceEpoch}',
      name: facility.name,
      address: facility.address,
      phone: facility.phone,
      latitude: facility.latitude,
      longitude: facility.longitude,
    );
  }

  @override
  Future<Facility> updateFacility(Facility facility) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return facility;
  }

  @override
  Future<void> deleteFacility(String facilityId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<Consultation> startConsultation({String? reportId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return Consultation(
      id: 'CONSULT-NEW-${DateTime.now().millisecondsSinceEpoch}',
      status: 'open',
      patientAnonymousId: 'ANON-34021',
      providerId: 'PROV-100',
      triageClassification: 'routine',
      createdAt: DateTime.now(),
      lastMessagePreview: '',
      unreadCount: 0,
    );
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<List<Consultation>> adminConsultations({String? status}) async {
    return consultations(status: status);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final onUnauthorizedProvider = Provider<void Function()>((ref) => () {});

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  if (AppConfig.useMockApi) return MockApiService(storage);
  return RealApiService(storage, onUnauthorized: () async {
    await storage.clear();
    ref.invalidateSelf();
  });
});
