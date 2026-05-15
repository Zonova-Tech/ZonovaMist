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

/// Only 'admin' is a backend admin role (matches user.js enum).
const Set<String> _adminRoles = {
  'admin',
};

/// Permissions per role — must stay in sync with backend user.js role enum:
/// admin | manager | staff | user
final Map<String, Set<AppPermission>> rolePermissions = {
  // Admin — full access, all mutations allowed
  'admin': AppPermission.values.toSet(),

  // Manager — full access, all mutations allowed
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

  // Staff — view-only: can see everything, cannot create/update/delete
  // Backend staffReadOnly middleware enforces this at the API level too.
  'staff': {
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

  // User — dashboard only, read-only
  // Backend staffReadOnly middleware blocks mutations for this role too.
  'user': {
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
  static bool isAdmin(String role) {
    if (role.isEmpty) return false;
    return _isAdminRole(role.toLowerCase());
  }

  /// Internal helper: check if normalized role is admin (role should already be lowercase).
  static bool _isAdminRole(String normalizedRole) {
    return _adminRoles.contains(normalizedRole);
  }

  /// Check if a role can perform mutations (create, update, delete).
  /// Returns false for staff and user roles — matches backend staffReadOnly middleware.
  ///
  /// Usage: Hide/disable mutation UI if !Rbac.canMutate(role)
  static bool canMutate(String role) {
    if (role.isEmpty) return false;
    final normalized = role.toLowerCase();
    if (normalized == 'staff' || normalized == 'user') return false;
    return true;
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
