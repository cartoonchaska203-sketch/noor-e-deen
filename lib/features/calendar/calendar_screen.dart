import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';

/// Islamic calendar: Hijri month grid + key Islamic dates.
///
/// Dates that depend on moon sighting carry an explicit disclaimer —
/// the app never presents estimated dates as certain.
class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late int _year;
  late int _month;
  final HijriCalendar _cal = HijriCalendar();

  @override
  void initState() {
    super.initState();
    final now = HijriCalendar.now();
    _year = now.hYear;
    _month = now.hMonth;
  }

  void _shiftMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      while (m < 1) {
        m += 12;
        y--;
      }
      while (m > 12) {
        m -= 12;
        y++;
      }
      _month = m;
      _year = y;
    });
  }

  // Key dates as (month, day) → label key. Approximate — moon-sighting
  // dependent; the disclaimer below says so plainly.
  static const _keyDates = <String, List<int>>{
    'cal_ramadan_start': [9, 1],
    'cal_laylat_qadr': [9, 27],
    'cal_eid_fitr': [10, 1],
    'cal_arafah': [12, 9],
    'cal_eid_adha': [12, 10],
    'cal_ashura': [1, 10],
    'cal_mawlid': [3, 12],
    'cal_meraj': [7, 27],
    'cal_shab_barat': [8, 15],
  };

  @override
  Widget build(BuildContext context) {
    final today = HijriCalendar.now();
    final year = _year;
    final month = _month;
    final monthLength = _cal.getDaysInMonth(year, month);
    final firstWeekday =
        _cal.hijriToGregorian(year, month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'cal_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftMonth(-1),
              ),
              Column(
                children: [
                  Text(
                    '${_monthName(month)} $year',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${S.of(context, 'cal_today')}: ${today.hDay} ${_monthName(today.hMonth)} ${today.hYear}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday header
          Row(
            children: [
              for (final d in [
                S.of(context, 'cal_sun'),
                S.of(context, 'cal_mon'),
                S.of(context, 'cal_tue'),
                S.of(context, 'cal_wed'),
                S.of(context, 'cal_thu'),
                S.of(context, 'cal_fri'),
                S.of(context, 'cal_sat'),
              ])
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday + monthLength,
            itemBuilder: (context, i) {
              if (i < firstWeekday) return const SizedBox();
              final day = i - firstWeekday + 1;
              final isToday = year == today.hYear &&
                  month == today.hMonth &&
                  day == today.hDay;
              final keyDate = _keyDateOn(month, day);
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : keyDate != null
                          ? Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.18)
                          : null,
                  borderRadius: BorderRadius.circular(10),
                  border: keyDate != null && !isToday
                      ? Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.5))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontWeight:
                        isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context, 'cal_moon_disclaimer'),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          SectionTitle(S.of(context, 'cal_key_dates')),
          for (final e in _keyDates.entries)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(S.of(context, e.key)),
                subtitle: Text(
                    '${e.value[1]} ${_monthName(e.value[0])} · ${S.of(context, 'cal_approx')}'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String? _keyDateOn(int month, int day) {
    for (final e in _keyDates.entries) {
      if (e.value[0] == month && e.value[1] == day) return e.key;
    }
    return null;
  }

  String _monthName(int m) {
    const keys = [
      '',
      'cal_muharram',
      'cal_safar',
      'cal_rabi1',
      'cal_rabi2',
      'cal_jumada1',
      'cal_jumada2',
      'cal_rajab',
      'cal_shaban',
      'cal_ramadan',
      'cal_shawwal',
      'cal_dhulqadah',
      'cal_dhulhijjah',
    ];
    return S.of(context, keys[m]);
  }
}
