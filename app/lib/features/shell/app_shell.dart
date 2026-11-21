import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, required this.destinations, super.key});

  final StatefulNavigationShell navigationShell;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: navigationShell.goBranch,
      ),
    );
  }
}

List<NavigationDestination> residentDestinations(AppLocalizations l10n) {
  return [
    NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.navHome),
    NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), label: l10n.navCalendar),
    NavigationDestination(icon: const Icon(Icons.report_outlined), label: l10n.navReport),
    NavigationDestination(icon: const Icon(Icons.notifications_outlined), label: l10n.navNotifications),
    NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.navProfile),
  ];
}

List<NavigationDestination> workerDestinations(AppLocalizations l10n) {
  return [
    NavigationDestination(icon: const Icon(Icons.today_outlined), label: l10n.navToday),
    NavigationDestination(icon: const Icon(Icons.event_note_outlined), label: l10n.navSchedule),
    NavigationDestination(icon: const Icon(Icons.notifications_outlined), label: l10n.navNotifications),
    NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.navProfile),
  ];
}
