import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/core/l10n/app_localizations_delegates.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/core/widgets/status_chip.dart';
import 'package:netsu_app/features/schedules/domain/schedule_status.dart';

void main() {
  testWidgets('status chip shows text and an icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: StatusChip(status: ScheduleStatus.delayed)),
      ),
    );
    expect(find.text('Delayed'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('empty state shows its title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: EmptyState(title: 'Nothing here yet', body: 'Later')),
      ),
    );
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  for (final code in ['en', 'am', 'om']) {
    testWidgets('MaterialApp builds cleanly for locale $code', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(code),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text(AppLocalizations.of(context).appTitle)),
              body: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
