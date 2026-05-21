class ApiError {
  final String code;
  final String message;
  final int status;

  ApiError({required this.code, required this.message, required this.status});
}

enum UserRole { patient, provider, admin }

class AuthUser {
  final String token;
  final UserRole role;
  final String anonymousId;
  final String fullName;
  final String phoneNumber;

  const AuthUser({
    required this.token,
    required this.role,
    required this.anonymousId,
    required this.fullName,
    required this.phoneNumber,
  });
}

class TriageResult {
  final String classification;
  final double confidenceScore;
  final String recommendedAction;

  const TriageResult({
    required this.classification,
    required this.confidenceScore,
    required this.recommendedAction,
  });
}

class Facility {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;

  const Facility({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });
}

enum ReferralStatus { newReferral, viewed }

class Consultation {
  final String id;
  final String status;
  final String patientAnonymousId;
  final String providerId;
  final String triageClassification;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final int unreadCount;

  const Consultation({
    required this.id,
    required this.status,
    required this.patientAnonymousId,
    required this.providerId,
    this.triageClassification = 'routine',
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessagePreview = '',
    this.unreadCount = 0,
  });

  Duration get waitingTime => DateTime.now().difference(createdAt);

  String get waitingLabel {
    final d = waitingTime;
    if (d.inMinutes < 60) return '${d.inMinutes}m waiting';
    return '${d.inHours}h ${d.inMinutes % 60}m waiting';
  }
}

class ChatMessage {
  final String id;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });
}

class Referral {
  final String id;
  final String facilityName;
  final String address;
  final String phone;
  final String notes;
  final DateTime issuedDate;
  final ReferralStatus status;

  const Referral({
    required this.id,
    required this.facilityName,
    required this.address,
    required this.phone,
    required this.notes,
    required this.issuedDate,
    this.status = ReferralStatus.newReferral,
  });
}

class AdminUser {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    required this.isActive,
  });
}

class TriageAnalytics {
  final int totalReports;
  final int urgent;
  final int routine;
  final int selfCare;
  final double averageConfidence;
  final int last7Days;

  const TriageAnalytics({
    required this.totalReports,
    required this.urgent,
    required this.routine,
    required this.selfCare,
    required this.averageConfidence,
    required this.last7Days,
  });
}

class SystemHealth {
  final String apiStatus;
  final String databaseStatus;
  final String mlServiceStatus;
  final String redisStatus;
  final int uptimeSeconds;

  const SystemHealth({
    required this.apiStatus,
    required this.databaseStatus,
    required this.mlServiceStatus,
    required this.redisStatus,
    required this.uptimeSeconds,
  });
}
