import 'package:netsu_app/core/l10n/generated/app_localizations.dart';

String loadErrorMessage(Object error, AppLocalizations l10n) {
  final text = error.toString();
  if (text.contains('relation') || text.contains('auth_role') || text.contains('schema') || text.contains('PGRST')) {
    return l10n.schemaBanner;
  }
  return l10n.errorTitle;
}
