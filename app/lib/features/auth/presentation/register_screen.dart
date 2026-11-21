import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/phone_number.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/areas/domain/service_area.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  List<ServiceArea>? _areas;
  String? _areaId;
  String? _error;
  bool _consent = false;
  bool _busy = false;
  bool _loadingAreas = true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _loadingAreas = true;
      _error = null;
    });
    try {
      final areas = await ref.read(authRepositoryProvider).activeAreas();
      if (!mounted) return;
      setState(() {
        _areas = areas;
        _loadingAreas = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAreas = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final phone = PhoneNumber.normalize(_phone.text);
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    if (phone == null) {
      setState(() => _error = l10n.invalidPhone);
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = l10n.passwordShort);
      return;
    }
    if (_areaId == null) {
      setState(() => _error = l10n.selectKebele);
      return;
    }
    if (!_consent) {
      setState(() => _error = l10n.consentRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await ref.read(authControllerProvider.notifier).signUp(
      fullName: _name.text.trim(),
      phone: phone,
      password: _password.text,
      areaId: _areaId!,
      address: _address.text.trim(),
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) setState(() => _error = l10n.registerFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loadingAreas) {
      return const Scaffold(body: LoadingView());
    }
    final areas = _areas;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
      body: areas == null
          ? ErrorView(message: l10n.schemaBanner, onRetry: _loadAreas)
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(controller: _name, decoration: InputDecoration(labelText: l10n.fullName)),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _areaId,
                  decoration: InputDecoration(labelText: l10n.kebele),
                  items: [
                    for (final area in areas)
                      DropdownMenuItem(value: area.id, child: Text('${area.kebeleCode} · ${area.name}')),
                  ],
                  onChanged: (value) => setState(() => _areaId = value),
                ),
                const SizedBox(height: 12),
                TextField(controller: _address, decoration: InputDecoration(labelText: l10n.address)),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _consent,
                  onChanged: (value) => setState(() => _consent = value ?? false),
                  title: Text(l10n.consentLabel),
                ),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? l10n.loading : l10n.register),
                ),
                TextButton(onPressed: () => context.go('/login'), child: Text(l10n.haveAccount)),
              ],
            ),
    );
  }
}
