import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/features/settings/locale_controller.dart';

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final code = ref.watch(localeControllerProvider).languageCode;
    return DropdownButtonFormField<String>(
      initialValue: code,
      decoration: InputDecoration(labelText: l10n.language),
      items: [
        DropdownMenuItem(value: 'en', child: Text(l10n.english)),
        DropdownMenuItem(value: 'am', child: Text(l10n.amharic)),
        DropdownMenuItem(value: 'om', child: Text(l10n.afaanOromo)),
      ],
      onChanged: (value) {
        if (value != null) {
          ref.read(localeControllerProvider.notifier).setCode(value);
        }
      },
    );
  }
}
