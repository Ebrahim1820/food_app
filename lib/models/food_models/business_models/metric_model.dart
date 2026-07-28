import 'package:flutter/material.dart';

class MetricModel {
  final String label;
  final String value;
  final String delta; // e.g. "+12% vs last week"
  final IconData icon;
  final Color color;
  const MetricModel(this.label, this.value, this.delta, this.icon, this.color);
}
