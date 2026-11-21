import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/routing/role_redirect.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/auth/presentation/login_screen.dart';
import 'package:netsu_app/features/auth/presentation/register_screen.dart';
import 'package:netsu_app/features/auth/presentation/reset_password_screen.dart';
import 'package:netsu_app/features/auth/presentation/use_dashboard_screen.dart';
import 'package:netsu_app/features/notifications/presentation/notifications_screen.dart';
import 'package:netsu_app/features/profile/presentation/profile_screen.dart';
import 'package:netsu_app/features/reports/presentation/report_screen.dart';
import 'package:netsu_app/features/resident/presentation/calendar_screen.dart';
import 'package:netsu_app/features/resident/presentation/resident_home_screen.dart';
import 'package:netsu_app/features/shell/app_shell.dart';
import 'package:netsu_app/features/worker/presentation/worker_schedule_screen.dart';
import 'package:netsu_app/features/worker/presentation/worker_today_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, _) {
    refresh.value++;
  });

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/splash',
    redirect: (_, state) {
      final auth = ref.read(authControllerProvider);
      return redirectFor(
        bootstrapped: auth.bootstrapped,
        signedIn: auth.signedIn,
        role: auth.role,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const Scaffold(body: LoadingView())),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/reset-password', builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(path: '/use-dashboard', builder: (_, _) => const UseDashboardScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) {
          return AppShell(
            navigationShell: shell,
            destinations: residentDestinations(AppLocalizations.of(context)),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/resident/home', builder: (_, _) => const ResidentHomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/resident/calendar', builder: (_, _) => const CalendarScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/resident/report', builder: (_, _) => const ReportScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/resident/notifications', builder: (_, _) => const NotificationsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/resident/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, _, shell) {
          return AppShell(
            navigationShell: shell,
            destinations: workerDestinations(AppLocalizations.of(context)),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/worker/today', builder: (_, _) => const WorkerTodayScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/worker/schedule', builder: (_, _) => const WorkerScheduleScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/worker/notifications', builder: (_, _) => const NotificationsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/worker/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
