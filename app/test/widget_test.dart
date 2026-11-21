import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/core/widgets/status_chip.dart';
import 'package:netsu_app/features/schedules/domain/schedule_status.dart';

void main() {
  testWidgets('status chip shows text and an icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StatusChip(status: ScheduleStatus.delayed)),
      ),
    );
    expect(find.text('Delayed'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('empty state shows its title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: EmptyState(title: 'Nothing here yet', body: 'Later')),
      ),
    );
    expect(find.text('Nothing here yet'), findsOneWidget);
  });
}
