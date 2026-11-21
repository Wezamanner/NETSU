import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/phone_number.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/settings/language_picker.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final phone = PhoneNumber.normalize(_phone.text);
    if (phone == null) {
      setState(() => _error = l10n.invalidPhone);
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = l10n.passwordShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await ref.read(authControllerProvider.notifier).signIn(phone: phone, password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) setState(() => _error = l10n.authFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/logo.jpg', height: 132),
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.signIn, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            l10n.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const LanguagePicker(),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.phone),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.password),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? l10n.loading : l10n.signIn),
          ),
          TextButton(onPressed: () => context.go('/reset-password'), child: Text(l10n.forgotPassword)),
          TextButton(onPressed: () => context.go('/register'), child: Text(l10n.noAccount)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
