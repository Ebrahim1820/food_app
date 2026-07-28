import 'package:flutter/material.dart';
import 'package:food_app/constants/food/business_constants/business_settings_strings.dart';
import 'package:food_app/widgets/common/custom_dynamic_button.dart';
import 'package:design_system/design_system.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Operating Hours Screen
//
// Lets the business owner set which days they're open and their opening /
// closing times for each day.
//
// State is kept locally for now — in a real app you'd POST to the backend
// when the user taps "Save Changes".
// ---------------------------------------------------------------------------

class BusinessOperatingHoursScreen extends StatefulWidget {
  const BusinessOperatingHoursScreen({super.key});

  @override
  State<BusinessOperatingHoursScreen> createState() =>
      _BusinessOperatingHoursScreenState();
}

class _BusinessOperatingHoursScreenState
    extends State<BusinessOperatingHoursScreen> {
  // One entry per weekday. Each day starts with sensible defaults.
  // Initialized in initState so translated names are read after the locale loads.
  late List<_DaySchedule> _schedule;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _schedule = [
      _DaySchedule(
        BusinessHoursStrings.monday,
        open: true,
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 22, minute: 0),
      ),
      _DaySchedule(
        BusinessHoursStrings.tuesday,
        open: true,
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 22, minute: 0),
      ),
      _DaySchedule(
        BusinessHoursStrings.wednesday,
        open: true,
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 22, minute: 0),
      ),
      _DaySchedule(
        BusinessHoursStrings.thursday,
        open: true,
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 22, minute: 0),
      ),
      _DaySchedule(
        BusinessHoursStrings.friday,
        open: true,
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 23, minute: 0),
      ),
      _DaySchedule(
        BusinessHoursStrings.saturday,
        open: true,
        from: const TimeOfDay(hour: 10, minute: 0),
        to: const TimeOfDay(hour: 23, minute: 0),
      ),
      _DaySchedule(
        BusinessHoursStrings.sunday,
        open: false,
        from: const TimeOfDay(hour: 10, minute: 0),
        to: const TimeOfDay(hour: 21, minute: 0),
      ),
    ];
  }

  // Shows the native time picker and returns the selected time (or null if
  // the user cancelled).
  Future<TimeOfDay?> _pickTime(TimeOfDay initial) =>
      showTimePicker(context: context, initialTime: initial);

  // Formats a TimeOfDay as "09:00" for display.
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() => _saving = true);
    // TODO: POST /api/business_partners/{id}/hours
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _saving = false);
    AppSnackbar.success(
      BusinessHoursStrings.savedSnack,
      BusinessHoursStrings.savedSnackBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
        title: Text(
          BusinessHoursStrings.appBarTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Info banner explaining what this screen does
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.infoDark,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      BusinessHoursStrings.infoBanner,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.infoDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // One card per day
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _schedule.length,
                itemBuilder: (_, i) => _DayCard(
                  day: _schedule[i],
                  onToggle: (v) => setState(() => _schedule[i].open = v),
                  onFromTap: () async {
                    final t = await _pickTime(_schedule[i].from);
                    if (t != null) setState(() => _schedule[i].from = t);
                  },
                  onToTap: () async {
                    final t = await _pickTime(_schedule[i].to);
                    if (t != null) setState(() => _schedule[i].to = t);
                  },
                  fmt: _fmt,
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed save button at the bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: CustomDynamicButton(
            label: BusinessHoursStrings.saveButton,
            onPressed: _save,
            isLoading: _saving,
            accentColor: AppColors.primary,
            fullWidth: true,
            borderRadius: 14,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model for one day's schedule
// ---------------------------------------------------------------------------
class _DaySchedule {
  _DaySchedule(
    this.name, {
    required this.open,
    required this.from,
    required this.to,
  });

  final String name;
  bool open;
  TimeOfDay from;
  TimeOfDay to;
}

// ---------------------------------------------------------------------------
// Card widget for a single day row
// ---------------------------------------------------------------------------
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.onToggle,
    required this.onFromTap,
    required this.onToTap,
    required this.fmt,
  });

  final _DaySchedule day;
  final ValueChanged<bool> onToggle;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final String Function(TimeOfDay) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day name + open/closed toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  day.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: day.open ? AppColors.ink : AppColors.gray400,
                  ),
                ),
                const Spacer(),
                // Shows "Open" or "Closed" label next to the switch
                Text(
                  day.open
                      ? BusinessHoursStrings.openLabel
                      : BusinessHoursStrings.closedLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: day.open ? AppColors.successDark : AppColors.gray400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: day.open,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ),

          // Time pickers — only shown when the day is marked as open
          if (day.open) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Opening time button
                  _TimeChip(
                    label: BusinessHoursStrings.opensChip,
                    time: fmt(day.from),
                    onTap: onFromTap,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.gray400,
                    ),
                  ),
                  // Closing time button
                  _TimeChip(
                    label: BusinessHoursStrings.closesChip,
                    time: fmt(day.to),
                    onTap: onToTap,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// A tappable pill that shows a time label and opens the time picker when tapped
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.successDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.successDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
