import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/location/device_location.dart';
import 'package:netsu_app/core/utils/addis_time.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/osm_map_view.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/profile/data/profile_repository.dart';
import 'package:netsu_app/features/reports/data/report_repository.dart';
import 'package:netsu_app/features/reports/domain/garbage_report.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _description = TextEditingController();
  final _address = TextEditingController();
  LatLng? _pin;
  XFile? _photo;
  String? _message;
  bool _error = false;
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    final point = await DeviceLocation.ask(context);
    if (!mounted) return;
    setState(() {
      if (point == null) {
        _error = true;
        _message = AppLocalizations.of(context).locationDenied;
      } else {
        _pin = point;
        _error = false;
        _message = null;
      }
    });
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 70);
    if (!mounted || file == null) return;
    setState(() => _photo = file);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final profile = ref.read(profileProvider).asData?.value;
    if (_description.text.trim().isEmpty) {
      setState(() {
        _error = true;
        _message = l10n.fieldRequired;
      });
      return;
    }
    final pin = _pin;
    if (pin == null || profile?.areaId == null) {
      setState(() {
        _error = true;
        _message = pin == null ? l10n.locationRequired : l10n.schemaBanner;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = false;
      _message = null;
    });
    try {
      await ref.read(reportRepositoryProvider).submit(
        areaId: profile!.areaId!,
        description: _description.text.trim(),
        address: _address.text.trim(),
        lat: pin.latitude,
        lng: pin.longitude,
        photo: _photo,
      );
      if (!mounted) return;
      _description.clear();
      _address.clear();
      setState(() {
        _pin = null;
        _photo = null;
        _message = l10n.reportSent;
      });
      ref.invalidate(myReportsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = l10n.reportFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(myReportsProvider);
    final pin = _pin ?? const LatLng(7.6667, 36.8333);
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myReportsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(l10n.navReport, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.mapDisclaimer, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(controller: _description, maxLines: 3, decoration: InputDecoration(labelText: l10n.reportHint)),
          const SizedBox(height: 12),
          TextField(controller: _address, decoration: InputDecoration(labelText: l10n.reportAddress)),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: OsmMapView(
              key: ValueKey('${pin.latitude.toStringAsFixed(5)},${pin.longitude.toStringAsFixed(5)}'),
              center: pin,
              points: _pin == null ? const [] : [pin],
              onTap: (point) => setState(() => _pin = point),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _pin == null ? l10n.locationRequired : '${l10n.coordinates}: ${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _useLocation, child: Text(l10n.useMyLocation)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _pickPhoto, child: Text(_photo == null ? l10n.addPhoto : l10n.photoReady)),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : theme.colorScheme.primary)),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? l10n.loading : l10n.submitReport)),
          const SizedBox(height: 28),
          Text(l10n.myReports, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          reports.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(message: loadErrorMessage(error, l10n), onRetry: () => ref.invalidate(myReportsProvider)),
            data: (items) {
              if (items.isEmpty) return Text(l10n.emptyTitle);
              return Column(
                children: [
                  for (final report in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReportCard(report: report),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final GarbageReport report;

  static const _steps = ['received', 'assigned', 'in_progress', 'completed'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isCancelled = report.status == 'cancelled';
    final currentIdx = _steps.indexOf(report.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.description, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${AddisTime.formatDate(report.createdAt)} · ${AddisTime.formatTime(report.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (report.address != null && report.address!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(report.address!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            if (isCancelled)
              Row(
                children: [
                  Icon(Icons.cancel_outlined, size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Text(l10n.statusCancelled, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    _StepPill(
                      label: _statusLabel(l10n, _steps[i]),
                      done: currentIdx >= i,
                      active: currentIdx == i,
                    ),
                ],
              ),
            if (report.adminNote != null && report.adminNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${l10n.adminNoteLabel}: ${report.adminNote!.trim()}', style: theme.textTheme.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'received' => l10n.statusReceived,
      'assigned' => l10n.statusAssigned,
      'in_progress' => l10n.statusInProgress,
      'completed' => l10n.statusCompleted,
      'cancelled' => l10n.statusCancelled,
      _ => status,
    };
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.done, required this.active});

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = done ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
