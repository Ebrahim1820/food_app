// ProfileScreen — thin shim kept for backwards compatibility with
// MainNavigationScreen's pages list. All real content lives in
// CustomerProfileScreen under lib/screens/customer/profile/.
import 'package:food_app/profile_and_orders/profile/views/customer_profile_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => CustomerProfileScreen();
}
