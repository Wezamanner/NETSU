import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/location/device_location.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/areas/domain/service_area.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/feedback/data/feedback_repository.dart';
import 'package:netsu_app/features/profile/data/profile_repository.dart';
import 'package:netsu_app/features/profile/domain/user_profile.dart';
import 'package:netsu_app/features/schedules/data/schedule_repository.dart';
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
  List<ServiceArea>? _areas;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final list = await ref.read(authRepositoryProvider).activeAreas();
      if (mounted) setState(() => _areas = list);
    } catch (_) {
      // Optional dropdown; profile still renders cleanly without it.
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _updateArea(String areaId) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(profileRepositoryProvider).updateArea(areaId);
      ref.invalidate(profileProvider);
      ref.invalidate(residentSchedulesProvider);
      if (!mounted) return;
      setState(() {
        _error = false;
        _message = l10n.kebeleUpdated;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = l10n.errorTitle;
      });
    }
  }

  Future<void> _togglePref(UserProfile person, String key, bool value) async {
    final l10n = AppLocalizations.of(context);
    final updated = <String, bool>{
      'in_app': person.pref('in_app'),
      'push': person.pref('push'),
      'sms': false,
      'day_before': person.pref('day_before'),
      'same_day': person.pref('same_day'),
      'on_the_way': person.pref('on_the_way'),
      'completed': person.pref('completed'),
      key: value,
    };
    try {
      await ref.read(profileRepositoryProvider).updateNotificationPrefs(updated);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      setState(() {
        _error = false;
        _message = l10n.prefsSaved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = l10n.errorTitle;
      });
    }
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
        final areas = _areas;
        final currentAreaInList = areas != null && areas.any((a) => a.id == person.areaId);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      _initials(person.fullName),
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(person.fullName, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 2),
                        Text(person.phone, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
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
                      if (areas != null && areas.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(person.areaId),
                          initialValue: currentAreaInList ? person.areaId : null,
                          decoration: InputDecoration(labelText: l10n.changeKebele),
                          items: [
                            for (final area in areas)
                              DropdownMenuItem(value: area.id, child: Text('${area.kebeleCode} · ${area.name}')),
                          ],
                          onChanged: (value) {
                            if (value != null && value != person.areaId) _updateArea(value);
                          },
                        ),
                      ],
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
              if (person.role == 'resident') ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.notifPrefsTitle, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(l10n.essentialNoticesLocked, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.prefInApp),
                          value: person.pref('in_app'),
                          onChanged: (v) => _togglePref(person, 'in_app', v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.prefPush),
                          value: person.pref('push'),
                          onChanged: (v) => _togglePref(person, 'push', v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.prefSms),
                          subtitle: Text(l10n.comingSoonBadge),
                          value: false,
                          onChanged: null,
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.prefDayBefore),
                          value: person.pref('day_before'),
                          onChanged: (v) => _togglePref(person, 'day_before', v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.prefSameDay),
                          value: person.pref('same_day'),
                          onChanged: (v) => _togglePref(person, 'same_day', v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.prefOnTheWay),
                          value: person.pref('on_the_way'),
                          onChanged: (v) => _togglePref(person, 'on_the_way', v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.prefCompleted),
                          value: person.pref('completed'),
                          onChanged: (v) => _togglePref(person, 'completed', v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          ),
        );
      },
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2);
  final chosen = parts.take(2).toList();
  if (chosen.isEmpty) return 'N';
  return chosen.map((part) => part.substring(0, 1).toUpperCase()).join();
}
