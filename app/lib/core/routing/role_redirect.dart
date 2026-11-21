import '../../features/auth/domain/app_role.dart';

const authPaths = {'/login', '/register', '/reset-password'};

/// Mobile app serves residents and workers. Administrators use the dashboard.
String? redirectFor({
  required bool bootstrapped,
  required bool signedIn,
  required AppRole? role,
  required String location,
}) {
  if (!bootstrapped) {
    return location == '/splash' ? null : '/splash';
  }
  if (!signedIn) {
    return authPaths.contains(location) ? null : '/login';
  }
  if (role == AppRole.admin) {
    return location == '/use-dashboard' ? null : '/use-dashboard';
  }
  final home = role == AppRole.worker ? '/worker/today' : '/resident/home';
  if (authPaths.contains(location) || location == '/splash' || location == '/use-dashboard') {
    return home;
  }
  if (role == AppRole.worker && location.startsWith('/resident')) return '/worker/today';
  if (role != AppRole.worker && location.startsWith('/worker')) return '/resident/home';
  return null;
}
