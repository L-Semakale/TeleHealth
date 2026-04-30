import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'role';
  static const _anonymousIdKey = 'anonymous_id';
  static const _fullNameKey = 'full_name';
  static const _phoneKey = 'phone';
  static const _facilityCacheKey = 'facilities_cache';
  static const _profileCacheKey = 'profile_cache';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveAuth({
    required String token,
    required String role,
    required String anonymousId,
    required String fullName,
    required String phone,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    await prefs.setString(_anonymousIdKey, anonymousId);
    await prefs.setString(_fullNameKey, fullName);
    await prefs.setString(_phoneKey, phone);
  }

  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);

  Future<Map<String, String?>> getUserMeta() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'role': prefs.getString(_roleKey),
      'anonymous_id': prefs.getString(_anonymousIdKey),
      'full_name': prefs.getString(_fullNameKey),
      'phone_number': prefs.getString(_phoneKey),
    };
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_anonymousIdKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_phoneKey);
  }

  Future<void> cacheFacilities(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_facilityCacheKey, jsonString);
  }

  Future<String?> getCachedFacilities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_facilityCacheKey);
  }

  Future<void> cacheProfile(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, jsonString);
  }

  Future<String?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileCacheKey);
  }
}
