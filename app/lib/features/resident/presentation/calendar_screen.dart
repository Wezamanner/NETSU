import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/addis_time.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/schedules/data/schedule_repository.dart';
import 'package:netsu_app/features/schedules/domain/area_schedule.dart';
import 'package:netsu_app/features/schedules/presentation/schedule_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final schedules = ref.watch(residentSchedulesProvider);

    return schedules.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: loadErrorMessage(error, l10n),
        onRetry: () => ref.invalidate(residentSchedulesProvider),
      ),
      data: (items) {
        final now = DateTime.now();
        final upcoming = items.where((item) => !item.expectedStart.isBefore(now)).toList();
        final previous = items.where((item) => item.expectedStart.isBefore(now)).toList().reversed.toList();
        final dayItems = _selectedDay == null
            ? const <AreaSchedule>[]
            : items.where((item) => AddisTime.isSameDay(item.expectedStart, _selectedDay!)).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(residentSchedulesProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(l10n.navCalendar, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              _MonthGrid(
                month: _visibleMonth,
                selectedDay: _selectedDay,
                schedules: items,
                onPrev: () => setState(() {
                  _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                }),
                onNext: () => setState(() {
                  _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                }),
                onSelectDay: (day) => setState(() {
                  _selectedDay = _selectedDay != null && _sameCalendarDay(_selectedDay!, day) ? null : day;
                }),
              ),
              if (_selectedDay != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.selectedDaySchedules} · ${AddisTime.formatDate(_selectedDay!)}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedDay = null),
                      child: Text(l10n.clearFilter),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (dayItems.isEmpty)
                  Text(l10n.noNextCollection)
                else
                  for (final item in dayItems) ...[ScheduleCard(schedule: item), const SizedBox(height: 12)],
              ],
              const SizedBox(height: 20),
              Text(l10n.upcoming, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (upcoming.isEmpty) Text(l10n.noNextCollection),
              for (final item in upcoming) ...[ScheduleCard(schedule: item), const SizedBox(height: 12)],
              const SizedBox(height: 8),
              Text(l10n.previousCollections, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (previous.isEmpty) Text(l10n.emptyTitle),
              for (final item in previous) ...[ScheduleCard(schedule: item), const SizedBox(height: 12)],
            ],
          ),
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.schedules,
    required this.onPrev,
    required this.onNext,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final List<AreaSchedule> schedules;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // Mon=1 .. Sun=7
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final scheduledDays = <int>{};
    for (final s in schedules) {
      final addis = AddisTime.wallClock(s.expectedStart);
      if (addis.year == month.year && addis.month == month.month) {
        scheduledDays.add(addis.day);
      }
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    '${month.year}-${month.month.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final label in labels)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final dayNum = index - leadingBlanks + 1;
                final dayDate = DateTime.utc(month.year, month.month, dayNum, 9);
                final hasSchedule = scheduledDays.contains(dayNum);
                final isSelected = selectedDay != null && _sameCalendarDay(selectedDay!, dayDate);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelectDay(dayDate),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : hasSchedule
                              ? theme.colorScheme.primaryContainer
                              : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: hasSchedule || isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (hasSchedule)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

bool _sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
