import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'owner_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Quick login presets
  final List<Map<String, String>> _presets = [
    {'label': '🐾 Pemilik Hewan', 'email': 'budi@gmail.com', 'password': 'password123', 'role': 'customer'},
    {'label': '🩺 Staf Pet Shop', 'email': 'staf@petshop.com', 'password': 'password123', 'role': 'staff'},
    {'label': '🛡️ Admin', 'email': 'admin@petshop.com', 'password': 'password123', 'role': 'admin'},
    {'label': '👑 Owner', 'email': 'owner@petshop.com', 'password': 'password123', 'role': 'owner'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email dan password wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try API login first
      final baseUrl = kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final user = UserModel.fromJson(data['data']);
          _navigateByRole(user);
          return;
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Email atau password salah';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('ℹ️ API offline, using local fallback login: $e');
    }

    // Fallback: local mock login
    final mockUser = _mockLogin(email, password);
    if (mockUser != null) {
      _navigateByRole(mockUser);
    } else {
      setState(() {
        _errorMessage = 'Email atau password salah';
        _isLoading = false;
      });
    }
  }

  UserModel? _mockLogin(String email, String password) {
    final mockUsers = {
      'budi@gmail.com': UserModel(id: 1, name: 'Budi Santoso', email: 'budi@gmail.com', phone: '081234567890', role: 'customer'),
      'siti@gmail.com': UserModel(id: 2, name: 'Siti Rahma', email: 'siti@gmail.com', phone: '081298765432', role: 'customer'),
      'staf@petshop.com': UserModel(id: 3, name: 'Dr. Vet Dian (Staf)', email: 'staf@petshop.com', phone: '081122334455', role: 'staff'),
      'admin@petshop.com': UserModel(id: 4, name: 'Admin HappyPaws', email: 'admin@petshop.com', phone: '081100001111', role: 'admin'),
      'owner@petshop.com': UserModel(id: 5, name: 'Pak Joko (Owner)', email: 'owner@petshop.com', phone: '081200002222', role: 'owner'),
    };

    if (password == 'password123' && mockUsers.containsKey(email)) {
      return mockUsers[email];
    }
    return null;
  }

  void _navigateByRole(UserModel user) {
    setState(() => _isLoading = false);

    Widget destination;
    switch (user.role) {
      case 'owner':
        destination = OwnerDashboardScreen(user: user);
        break;
      case 'admin':
        destination = MainNavigationScreen(user: user, startAsStaff: false);
        break;
      case 'staff':
        destination = MainNavigationScreen(user: user, startAsStaff: true);
        break;
      case 'customer':
      default:
        destination = MainNavigationScreen(user: user, startAsStaff: false);
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => destination,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _fillPreset(Map<String, String> preset) {
    _emailController.text = preset['email']!;
    _passwordController.text = preset['password']!;
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F766E),  // Dark Teal
              Color(0xFF0D9488),  // Primary Teal
              Color(0xFF14B8A6),  // Light Teal
              Color(0xFF5EEAD4),  // Cyan accent
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Title
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Login Card
                      _buildLoginCard(),
                      const SizedBox(height: 20),

                      // Quick Login Buttons
                      _buildQuickLoginSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated logo container
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.pets, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'HappyPaws',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pet Care & Pickup Tracker',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masuk ke Akun',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Silakan login dengan akun Anda',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),

          // Email Field
          _buildInputLabel('Email'),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'contoh: budi@gmail.com',
              icon: Icons.email_outlined,
            ),
            onChanged: (_) => setState(() => _errorMessage = null),
          ),
          const SizedBox(height: 18),

          // Password Field
          _buildInputLabel('Password'),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'Masukkan password',
              icon: Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textLight,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onChanged: (_) => setState(() => _errorMessage = null),
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 8),

          // Error Message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.delayedRedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.delayedRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.delayedRed, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 20),
                        SizedBox(width: 8),
                        Text('Masuk'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLoginSection() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        children: [
          Text(
            'Quick Login Demo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _presets.map((preset) {
              final isSelected = _emailController.text == preset['email'];
              return InkWell(
                onTap: () => _fillPreset(preset),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    preset['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryDark : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }
}
