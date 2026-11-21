import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/location/device_location.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/feedback/data/feedback_repository.dart';
import 'package:netsu_app/features/profile/data/profile_repository.dart';
import 'package:netsu_app/features/settings/language_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _comment = TextEditingController();
  String _kind = 'feedback';
  int _rating = 5;
  String? _message;
  bool _error = false;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    final l10n = AppLocalizations.of(context);
    final point = await DeviceLocation.ask(context);
    if (!mounted) return;
    if (point == null) {
      setState(() {
        _error = true;
        _message = l10n.locationDenied;
      });
      return;
    }
    try {
      await ref.read(profileRepositoryProvider).saveLocation(lat: point.latitude, lng: point.longitude);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      setState(() {
        _error = false;
        _message = '${l10n.locationSaved} ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = l10n.errorTitle;
      });
    }
  }

  Future<void> _sendFeedback() async {
    final l10n = AppLocalizations.of(context);
    if (_comment.text.trim().isEmpty) {
      setState(() {
        _error = true;
        _message = l10n.fieldRequired;
      });
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(feedbackRepositoryProvider).send(comment: _comment.text.trim(), kind: _kind, rating: _rating);
      _comment.clear();
      if (!mounted) return;
      setState(() {
        _error = false;
        _message = l10n.feedbackSent;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = l10n.feedbackFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    final theme = Theme.of(context);
    return profile.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(message: loadErrorMessage(error, l10n), onRetry: () => ref.invalidate(profileProvider)),
      data: (person) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(person.fullName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(person.phone, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.kebele, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(person.kebeleCode == null ? l10n.emptyTitle : '${person.kebeleCode} · ${person.areaName ?? ''}'),
                    if (person.address != null) ...[const SizedBox(height: 8), Text(person.address!)],
                    const SizedBox(height: 8),
                    Text(l10n.kebeleConfirm, style: theme.textTheme.bodySmall),
                    if (person.lat != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${l10n.coordinates}: ${person.lat!.toStringAsFixed(5)}, ${person.lng!.toStringAsFixed(5)}'),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _saveLocation, child: Text(l10n.saveLocation)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const LanguagePicker(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : theme.colorScheme.primary)),
            ],
            if (person.role == 'resident') ...[
              const SizedBox(height: 24),
              Text(l10n.feedbackTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: l10n.feedbackTitle),
                items: [
                  DropdownMenuItem(value: 'feedback', child: Text(l10n.kindFeedback)),
                  DropdownMenuItem(value: 'complaint', child: Text(l10n.kindComplaint)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      onPressed: () => setState(() => _rating = star),
                      icon: Icon(star <= _rating ? Icons.star : Icons.star_border),
                      tooltip: '$star',
                    ),
                ],
              ),
              TextField(controller: _comment, maxLines: 3, decoration: InputDecoration(labelText: l10n.feedbackHint)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _busy ? null : _sendFeedback, child: Text(_busy ? l10n.loading : l10n.sendFeedback)),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              child: Text(l10n.signOut),
            ),
          ],
        );
      },
    );
  }
}
