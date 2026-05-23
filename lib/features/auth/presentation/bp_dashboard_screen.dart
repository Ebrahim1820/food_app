import 'package:flutter/material.dart';

class BpDashboardScreen extends StatelessWidget {
  const BpDashboardScreen({super.key});
  static const routePath = '/bp/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Partner Dashboard')),
      body: const Center(child: Text('BP Dashboard (placeholder)')),
    );
  }
}