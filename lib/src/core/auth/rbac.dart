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

final Map<String, Set<AppPermission>> rolePermissions = {
  'admin': AppPermission.values.toSet(),
  'owner': AppPermission.values.toSet(),
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
  'technician': {
    AppPermission.dashboard,
    AppPermission.rooms,
    AppPermission.roomRates,
    AppPermission.assets,
  },
  'reception': {
    AppPermission.dashboard,
    AppPermission.bookings,
    AppPermission.reservations,
    AppPermission.todos,
    AppPermission.settings,
  },
  'cleaning': {
    AppPermission.dashboard,
    AppPermission.rooms,
    AppPermission.todos,
  },
};

class Rbac {
  static bool canAccess({
    required String role,
    required List<String> permissions,
    required AppPermission permission,
  }) {
    if (permissions.isNotEmpty) {
      return _permissionMatches(permissions, permission);
    }

    final roleKey = role.toLowerCase();
    final allowed = rolePermissions[roleKey];
    if (allowed == null) {
      return false;
    }
    return allowed.contains(permission);
  }

  static bool _permissionMatches(List<String> permissions, AppPermission permission) {
    final key = permissionKeys[permission] ?? permission.name;
    final normalizedKey = key.toLowerCase();
    final normalized = permissions.map((perm) => perm.toLowerCase());
    return normalized.any(
      (perm) => perm == normalizedKey || perm.contains(normalizedKey),
    );
  }
}
