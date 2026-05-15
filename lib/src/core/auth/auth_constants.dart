class AuthConstants {
  static const String jwtKey = 'jwt_token';
  static const String userFullNameKey = 'user_full_name';
  static const String userRoleKey = 'user_role';
  static const String userPermissionsKey = 'user_permissions';
}

/// Role constants — must match backend user.js enum exactly.
class AppRoles {
  static const String admin = 'admin';
  static const String manager = 'manager';
  static const String staff = 'staff';
  static const String user = 'user';
}
