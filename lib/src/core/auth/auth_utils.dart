import 'dart:convert';

// Minimal, dependency-free JWT payload decoder to check exp safely.
// Returns the payload map or null on malformed token.
Map<String, dynamic>? decodeJwtPayload(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    // Base64 decode with proper padding
    var normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> map = jsonDecode(decoded) as Map<String, dynamic>;
    return map;
  } catch (_) {
    return null;
  }
}

bool isJwtExpired(String? token) {
  final payload = decodeJwtPayload(token);
  if (payload == null) return true; // treat malformed as expired/invalid
  try {
    final exp = payload['exp'];
    if (exp == null) return false; // no exp claim -> assume non-expiring
    final expInt = (exp is int) ? exp : int.parse(exp.toString());
    final expiry = DateTime.fromMillisecondsSinceEpoch(expInt * 1000);
    return DateTime.now().isAfter(expiry);
  } catch (_) {
    return true;
  }
}

String? safeGetRoleFromPayload(String? token) {
  final payload = decodeJwtPayload(token);
  if (payload == null) return null;
  // common claim names: role, roles, r
  final role = payload['role'] ?? payload['roles'] ?? payload['r'];
  if (role == null) return null;
  if (role is String) return role;
  if (role is List && role.isNotEmpty) return role.first.toString();
  return null;
}
