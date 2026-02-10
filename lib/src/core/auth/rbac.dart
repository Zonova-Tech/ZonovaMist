import 'package:Zonova_Mist/src/core/auth/auth_constants.dart';

enum AppPermission {
  dashboard,
  bookings,
  reservations,
  todos,
  settings,
  rooms,
  roomRates,
  expenses,
  partnerHotels,
  staff,
  assets,
}

const Map<AppPermission, String> permissionKeys = {
  AppPermission.dashboard: 'dashboard',
  AppPermission.bookings: 'bookings',
  AppPermission.reservations: 'reservations',
  AppPermission.todos: 'todos',
  AppPermission.settings: 'settings',
  AppPermission.rooms: 'rooms',
  AppPermission.roomRates: 'room_rates',
  AppPermission.expenses: 'expenses',
  AppPermission.partnerHotels: 'partner_hotels',
  AppPermission.staff: 'staff',
  AppPermission.assets: 'assets',
};

const Map<AppPermission, String> permissionLabels = {
  AppPermission.dashboard: 'Dashboard',
  AppPermission.bookings: 'Bookings',
  AppPermission.reservations: 'Reservations',
  AppPermission.todos: 'Todos',
  AppPermission.settings: 'Settings',
  AppPermission.rooms: 'Rooms',
  AppPermission.roomRates: 'Room Rates',
  AppPermission.expenses: 'Expenses',
  AppPermission.partnerHotels: 'Partner Hotels',
  AppPermission.staff: 'Guest Staff',
  AppPermission.assets: 'Assets',
};

/// Admin roles that bypass all permission checks.
/// Backend guarantees these roles ALWAYS have access.
/// Roles from backend are lowercase: 'admin', 'super_admin', 'guest_house_admin', etc.
const Set<String> _adminRoles = {
  'admin',
  'super_admin',
  'guest_house_admin',
};

final Map<String, Set<AppPermission>> rolePermissions = {
  // Admin roles - have all permissions (backend admin bypass)
  'admin': AppPermission.values.toSet(),
  'super_admin': AppPermission.values.toSet(),
  'guest_house_admin': AppPermission.values.toSet(),

  // Manager role
  'manager': {
    AppPermission.dashboard,
    AppPermission.bookings,
    AppPermission.reservations,
    AppPermission.todos,
    AppPermission.settings,
    AppPermission.rooms,
    AppPermission.roomRates,
    AppPermission.expenses,
    AppPermission.partnerHotels,
    AppPermission.staff,
    AppPermission.assets,
  },

  // Specialist roles
  'maintenance': {
    AppPermission.dashboard,
    AppPermission.rooms,
    AppPermission.roomRates,
    AppPermission.assets,
  },
  'receptionist': {
    AppPermission.dashboard,
    AppPermission.bookings,
    AppPermission.reservations,
    AppPermission.todos,
    AppPermission.settings,
  },
  'housekeeping': {
    AppPermission.dashboard,
    AppPermission.rooms,
    AppPermission.todos,
  },
  'finance': {
    AppPermission.dashboard,
    AppPermission.expenses,
  },
  'staff': {
    AppPermission.dashboard,
  },
  'user': {
    AppPermission.dashboard,
  },
  'guest': {
    AppPermission.dashboard,
  },
};

class Rbac {
  /// Check if a user role has access to a specific permission.
  ///
  /// Admin roles ALWAYS have access (matches backend admin bypass logic).
  /// Role comparison is case-insensitive (normalized to lowercase).
  /// Returns true only if: role is admin OR role has explicit permission.
  static bool canAccess({
    required String role,
    required List<String> permissions,
    required AppPermission permission,
  }) {
    try {
      if (role.isEmpty) return false;

      // Normalize role to lowercase for comparison (backend roles are lowercase)
      final normalizedRole = role.toLowerCase();

      // Admin bypass: admins have access to EVERYTHING
      // This matches backend behavior where admin is a super-role
      if (_isAdminRole(normalizedRole)) {
        return true;
      }

      // For non-admin roles, check explicit permissions list first
      if (permissions.isNotEmpty) {
        return _permissionMatches(permissions, permission);
      }

      // Fall back to role-based permissions mapping
      final rolePermissionSet = rolePermissions[normalizedRole];
      return rolePermissionSet?.contains(permission) ?? false;
    } catch (_) {
      // Fail safely - deny access on error
      return false;
    }
  }

  /// Check if a role string is an admin role (case-insensitive).
  ///
  /// Returns true for admin, super_admin, guest_house_admin.
  static bool isAdmin(String role) {
    if (role.isEmpty) return false;
    return _isAdminRole(role.toLowerCase());
  }

  /// Internal helper: check if normalized role is admin (role should already be lowercase).
  static bool _isAdminRole(String normalizedRole) {
    return _adminRoles.contains(normalizedRole);
  }

  /// Match explicit permissions against required permission (case-insensitive).
  static bool _permissionMatches(
    List<String> permissions,
    AppPermission permission,
  ) {
    final key = permissionKeys[permission] ?? permission.name;
    final normalizedKey = key.toLowerCase();

    return permissions.any((perm) {
      final normalizedPerm = perm.toLowerCase();
      return normalizedPerm == normalizedKey || normalizedPerm.contains(normalizedKey);
    });
  }
}
