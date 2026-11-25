import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'customer_home_screen.dart';
import 'staff_dashboard_screen.dart';
import 'login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserModel? user;
  final bool startAsStaff;

  const MainNavigationScreen({
    super.key,
    this.user,
    this.startAsStaff = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late bool _isStaffMode;

  @override
  void initState() {
    super.initState();
    _isStaffMode = widget.startAsStaff;
  }

  void _toggleRole() {
    setState(() {
      _isStaffMode = !_isStaffMode;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isStaffMode
          ? StaffDashboardScreen(
              key: const ValueKey('staff_mode'),
              onSwitchToCustomer: _toggleRole,
            )
          : CustomerHomeScreen(
              key: const ValueKey('customer_mode'),
              onSwitchToStaff: _toggleRole,
              user: widget.user,
              onLogout: _logout,
            ),
    );
  }
}


