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

class Consultation {
  final String id;
  final String status;
  final String patientAnonymousId;
  final String providerId;

  const Consultation({
    required this.id,
    required this.status,
    required this.patientAnonymousId,
    required this.providerId,
  });
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
  final String facilityName;
  final String address;
  final String phone;
  final String notes;
  final DateTime issuedDate;

  const Referral({
    required this.facilityName,
    required this.address,
    required this.phone,
    required this.notes,
    required this.issuedDate,
  });
}
