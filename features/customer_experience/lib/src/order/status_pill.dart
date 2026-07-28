import 'package:flutter/material.dart';

/// A small "dot + label" status indicator — colour is the caller's own
/// (typically from [StatusHelper.getStatusColor], see
/// `lib/src/profile_and_orders/profile/utils/status_helper.dart`), this
/// widget just standardises the dot+text layout so every status label
/// across the app (order rows, business rows, ...) renders identically
/// instead of each card hand-rolling its own `Container` + `Text` pair.
///
/// Not a fit for every "status" concept in the app — e.g. a business order
/// row's needs-decision/bucket-based accent, or a multi-step progress
/// tracker, are different shapes entirely and shouldn't be forced through
/// this widget. Use it wherever a single label+colour pill is genuinely
/// what's being shown.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11.5,
  });

  final String label;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
