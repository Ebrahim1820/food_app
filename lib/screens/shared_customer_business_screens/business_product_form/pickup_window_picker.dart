// lib/screens/shared_customer_business_screens/business_product_form/pickup_window_picker.dart
import 'package:flutter/material.dart';
import 'package:food_app/screens/shared_customer_business_screens/business_product_form/pickup_window_strings.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart' hide TextDirection;

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
//
//  PickupWindowPicker.show(context, initialStart: ..., initialEnd: ...)
//    → Future<({DateTime start, DateTime end})?>
//
//  PickupWindowField(start: ..., end: ..., onTap: ...)
//    → compact display chip that opens the picker on tap
// ─────────────────────────────────────────────────────────────────────────────

class PickupWindowPicker extends StatefulWidget {
  const PickupWindowPicker._({
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;

  static Future<({DateTime start, DateTime end})?> show(
    BuildContext context, {
    DateTime? initialStart,
    DateTime? initialEnd,
  }) {
    return showModalBottomSheet<({DateTime start, DateTime end})>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickupWindowPicker._(
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    );
  }

  @override
  State<PickupWindowPicker> createState() => _PickupWindowPickerState();
}

// ─────────────────────────────────────────────────────────────────────────────

class _PickupWindowPickerState extends State<PickupWindowPicker> {
  static const _green = AppColors.primary;
  static const _greenLight = AppColors.primaryLight;
  static final _displayFmt = DateFormat('MMM d, HH:mm');

  // Which end we're editing
  bool _editingStart = true;

  // Calendar state
  late DateTime _focusedMonth;
  DateTime? _start;
  DateTime? _end;

  // Time state (stored as int so both ends are independent)
  late int _startHour;
  late int _startMin; // always a multiple of 15
  late int _endHour;
  late int _endMin;

  // Wheel controllers (single pair, jumped-to when tab switches)
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = widget.initialStart;
    _end = widget.initialEnd;

    _startHour = widget.initialStart?.hour ?? now.hour;
    _startMin = _snap(widget.initialStart?.minute ?? 0);
    _endHour = widget.initialEnd?.hour ?? ((now.hour + 2) % 24);
    _endMin = _snap(widget.initialEnd?.minute ?? 0);

    _focusedMonth = DateTime(
      _start?.year ?? now.year,
      _start?.month ?? now.month,
    );

    _hourCtrl = FixedExtentScrollController(initialItem: _startHour);
    _minCtrl = FixedExtentScrollController(initialItem: _startMin ~/ 15);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  int _snap(int m) => (m ~/ 15) * 15;

  // ── tab switch ─────────────────────────────────────────────────────────────

  void _switchTab(bool toStart) {
    if (_editingStart == toStart) return;
    setState(() {
      _editingStart = toStart;
      _hourCtrl.jumpToItem(toStart ? _startHour : _endHour);
      _minCtrl.jumpToItem(toStart ? _startMin ~/ 15 : _endMin ~/ 15);
    });
  }

  // ── day selection ──────────────────────────────────────────────────────────

  void _onDayTap(DateTime day) {
    setState(() {
      if (_editingStart) {
        _start = DateTime(day.year, day.month, day.day, _startHour, _startMin);
        if (_end != null && !_end!.isAfter(_start!)) _end = null;
      } else {
        final candidate = DateTime(
          day.year,
          day.month,
          day.day,
          _endHour,
          _endMin,
        );
        if (_start == null || candidate.isAfter(_start!)) {
          _end = candidate;
        } else {
          // tapping before start → swap
          _end = _start;
          _start = candidate;
        }
      }
    });
  }

  // ── time wheel callbacks ───────────────────────────────────────────────────

  void _onHourChanged(int idx) => setState(() {
    if (_editingStart) {
      _startHour = idx;
      if (_start != null) {
        _start = DateTime(
          _start!.year,
          _start!.month,
          _start!.day,
          idx,
          _startMin,
        );
      }
    } else {
      _endHour = idx;
      if (_end != null) {
        _end = DateTime(_end!.year, _end!.month, _end!.day, idx, _endMin);
      }
    }
  });

  void _onMinChanged(int idx) {
    final min = idx * 15;
    setState(() {
      if (_editingStart) {
        _startMin = min;
        if (_start != null) {
          _start = DateTime(
            _start!.year,
            _start!.month,
            _start!.day,
            _startHour,
            min,
          );
        }
      } else {
        _endMin = min;
        if (_end != null) {
          _end = DateTime(_end!.year, _end!.month, _end!.day, _endHour, min);
        }
      }
    });
  }

  // ── confirm ────────────────────────────────────────────────────────────────

  bool get _canConfirm =>
      _start != null && _end != null && _end!.isAfter(_start!);

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context).pop((start: _start!, end: _end!));
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: screenH * 0.88,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            _tabRow(),
            const Divider(height: 1, color: AppColors.gray100),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    _calendar(),
                    const Divider(height: 1, color: AppColors.gray100),
                    _timePicker(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _confirmButton(),
            SizedBox(height: bottomPad + 8),
          ],
        ),
      ),
    );
  }

  // ── header / handle ────────────────────────────────────────────────────────

  Widget _handle() => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 8, 10),
    child: Row(
      children: [
        Text(
          PickupWindowStrings.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.gray500),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  // ── start / end tab row ────────────────────────────────────────────────────

  Widget _tabRow() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      children: [
        Expanded(child: _tabCard(isStart: true)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: AppColors.gray400,
          ),
        ),
        Expanded(child: _tabCard(isStart: false)),
      ],
    ),
  );

  Widget _tabCard({required bool isStart}) {
    final selected = _editingStart == isStart;
    final value = isStart ? _start : _end;

    return GestureDetector(
      onTap: () => _switchTab(isStart),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _green : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _green : AppColors.gray200,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStart
                  ? PickupWindowStrings.tabStart
                  : PickupWindowStrings.tabEnd,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.white.withValues(alpha: 0.75)
                    : AppColors.gray500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value == null
                  ? PickupWindowStrings.notSet
                  : _displayFmt.format(value),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.navy,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── calendar ───────────────────────────────────────────────────────────────

  Widget _calendar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
    child: Column(
      children: [
        _monthNav(),
        const SizedBox(height: 8),
        _weekdayRow(),
        const SizedBox(height: 4),
        _dateGrid(),
      ],
    ),
  );

  Widget _monthNav() {
    final label = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Row(
      children: [
        _navBtn(Icons.chevron_left_rounded, () {
          setState(() {
            _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month - 1,
            );
          });
        }),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        _navBtn(Icons.chevron_right_rounded, () {
          setState(() {
            _focusedMonth = DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
            );
          });
        }),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 22, color: AppColors.navy),
    ),
  );

  Widget _weekdayRow() {
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      children: labels
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _dateGrid() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startOffset = (first.weekday - 1) % 7; // Mon = 0
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final rowCount = ((startOffset + daysInMonth) / 7).ceil();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Column(
      children: List.generate(rowCount, (row) {
        return Row(
          children: List.generate(7, (col) {
            final dayNum = row * 7 + col - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 38));
            }
            final day = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              dayNum,
            );
            return Expanded(child: _dayCell(day, todayDate));
          }),
        );
      }),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime day) {
    if (_start == null || _end == null) return false;
    final s = DateTime(_start!.year, _start!.month, _start!.day);
    final e = DateTime(_end!.year, _end!.month, _end!.day);
    return day.isAfter(s) && day.isBefore(e);
  }

  Widget _dayCell(DateTime day, DateTime todayDate) {
    final isStart = _start != null && _sameDay(day, _start!);
    final isEnd = _end != null && _sameDay(day, _end!);
    final inRange = _inRange(day);
    final isToday = _sameDay(day, todayDate);
    final isPast = day.isBefore(todayDate);

    final leftGreen = inRange || isEnd;
    final rightGreen = inRange || isStart;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isPast ? null : () => _onDayTap(day),
      child: SizedBox(
        height: 38,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Range background — left / right halves independently coloured
            if (leftGreen || rightGreen)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: leftGreen ? _greenLight : Colors.transparent,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: rightGreen ? _greenLight : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            // Selection dot
            if (isStart || isEnd)
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
            // Today ring (unselected)
            if (isToday && !isStart && !isEnd)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 1.5),
                ),
              ),
            // Date label
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: (isStart || isEnd || isToday)
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: (isStart || isEnd)
                    ? AppColors.white
                    : isPast
                    ? AppColors.gray300
                    : inRange
                    ? AppColors.successDark
                    : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── time picker ────────────────────────────────────────────────────────────

  Widget _timePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: _green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _editingStart
                    ? PickupWindowStrings.timeStart
                    : PickupWindowStrings.timeEnd,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _wheel(
                controller: _hourCtrl,
                count: 24,
                label: (i) => i.toString().padLeft(2, '0'),
                onChanged: _onHourChanged,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
              _wheel(
                controller: _minCtrl,
                count: 4, // 0, 15, 30, 45
                label: (i) => (i * 15).toString().padLeft(2, '0'),
                onChanged: _onMinChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      width: 88,
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection highlight
          Positioned(
            top: 38,
            left: 6,
            right: 6,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 44,
            perspective: 0.004,
            diameterRatio: 2.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (_, idx) {
                final sel = idx == controller.selectedItem;
                return Center(
                  child: Text(
                    label(idx),
                    style: TextStyle(
                      fontSize: sel ? 24 : 17,
                      fontWeight: sel ? FontWeight.bold : FontWeight.w400,
                      color: sel ? _green : AppColors.gray400,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── confirm button ─────────────────────────────────────────────────────────

  Widget _confirmButton() {
    final ready = _canConfirm;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ready ? _green : AppColors.gray100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: ready ? _confirm : null,
          child: Text(
            ready
                ? PickupWindowStrings.confirmReady
                : PickupWindowStrings.confirmPending,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ready ? AppColors.white : AppColors.gray400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PickupWindowField — compact display row used in create & edit screens
// ─────────────────────────────────────────────────────────────────────────────

class PickupWindowField extends StatelessWidget {
  const PickupWindowField({
    super.key,
    required this.start,
    required this.end,
    required this.onTap,
  });

  final DateTime? start;
  final DateTime? end;
  final VoidCallback onTap;

  static final _dateFmt = DateFormat('EEE, MMM d');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final hasRange = start != null && end != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasRange
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.gray200,
          ),
        ),
        child: hasRange ? _range() : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Row(
    children: [
      const Icon(
        Icons.calendar_month_rounded,
        size: 20,
        color: AppColors.gray400,
      ),
      const SizedBox(width: 10),
      Text(
        PickupWindowStrings.placeholder,
        style: const TextStyle(color: AppColors.gray400, fontSize: 14),
      ),
      const Spacer(),
      const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.gray400,
      ),
    ],
  );

  Widget _range() {
    final sameDay =
        start!.year == end!.year &&
        start!.month == end!.month &&
        start!.day == end!.day;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateFmt.format(start!),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _timeChip(_timeFmt.format(start!), isStart: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      sameDay ? '→' : '– ${_dateFmt.format(end!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                  _timeChip(_timeFmt.format(end!), isStart: false),
                ],
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.gray400,
        ),
      ],
    );
  }

  Widget _timeChip(String label, {required bool isStart}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: isStart ? AppColors.primaryLight : AppColors.gray100,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isStart ? AppColors.primary : AppColors.gray600,
      ),
    ),
  );
}
