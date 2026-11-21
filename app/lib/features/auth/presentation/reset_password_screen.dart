import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.resetBody),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/login'), child: Text(l10n.backToSignIn)),
          ],
        ),
      ),
    );
  }
}
