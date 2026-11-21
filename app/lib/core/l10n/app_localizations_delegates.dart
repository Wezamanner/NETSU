import 'package:material_ui/material_ui.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';

/// Localization delegates for `material_ui`'s [MaterialApp].
///
/// Uses `material_ui`'s [GlobalMaterialLocalizations.delegates] (matching
/// `material_ui` and `cupertino_ui` types) and wraps each system delegate with
/// an English fallback so locales like Afaan Oromo (`om`)—which are supported
/// by [AppLocalizations] but not yet bundled in Flutter's global delegates—do
/// not trigger missing-localization exceptions.
final List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates.map(_EnglishFallbackDelegate.new),
    ];

class _EnglishFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _EnglishFallbackDelegate(this._inner);

  final LocalizationsDelegate<T> _inner;

  @override
  Type get type => _inner.type;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) =>
      _inner.load(_inner.isSupported(locale) ? locale : const Locale('en'));

  @override
  bool shouldReload(covariant _EnglishFallbackDelegate<T> old) =>
      _inner.shouldReload(old._inner);
}
