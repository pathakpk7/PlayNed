import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../platform/presentation/widgets/playned_logo.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _signUpEmailController = TextEditingController();
  final _signUpUsernameController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpEmailController.dispose();
    _signUpUsernameController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    final success = await ref.read(authProvider.notifier).login(
          _loginEmailController.text,
          _loginPasswordController.text,
        );
    if (success && mounted) {
      context.go('/');
    }
  }

  void _submitSignUp() async {
    final success = await ref.read(authProvider.notifier).signup(
          _signUpEmailController.text,
          _signUpUsernameController.text,
          _signUpPasswordController.text,
        );
    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("PLAYER ACCOUNT", style: GoogleFonts.dmSerifDisplay()),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD5A84B),
          labelColor: const Color(0xFFF1EBDD),
          unselectedLabelColor: const Color(0xFFA9A396),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0),
          tabs: const [
            Tab(text: "LOGIN"),
            Tab(text: "SIGN UP"),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Login Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: PlayNedLogo(size: 64, showText: true, fontSize: 18),
                      ),
                    ),
                    Text(
                      "Welcome Back.",
                      style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFFF1EBDD)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Sign in to access your persistent vocabulary record & 100-level progression.",
                      style: GoogleFonts.inter(color: const Color(0xFFA9A396), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _loginEmailController,
                      decoration: const InputDecoration(
                        labelText: "Email or Username",
                        prefixIcon: Icon(Icons.person_outline, color: Color(0xFFA9A396)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _loginPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFA9A396)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(authState.errorMessage!, style: GoogleFonts.inter(color: const Color(0xFFB95745), fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF1EBDD),
                          side: const BorderSide(color: Color(0xFFD5A84B)),
                        ),
                        onPressed: authState.isLoading ? null : _submitLogin,
                        child: authState.isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFD5A84B))
                            : Text("LOG IN →", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                ),
              ),

              // Sign Up Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: PlayNedLogo(size: 64, showText: true, fontSize: 18),
                      ),
                    ),
                    Text(
                      "Create Player Profile",
                      style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFFF1EBDD)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Begin your 100-level vocabulary journey with persistent statistics.",
                      style: GoogleFonts.inter(color: const Color(0xFFA9A396), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _signUpEmailController,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFA9A396)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _signUpUsernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.account_circle_outlined, color: Color(0xFFA9A396)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _signUpPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFA9A396)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(authState.errorMessage!, style: GoogleFonts.inter(color: const Color(0xFFB95745), fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF1EBDD),
                          side: const BorderSide(color: Color(0xFFD5A84B)),
                        ),
                        onPressed: authState.isLoading ? null : _submitSignUp,
                        child: authState.isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFD5A84B))
                            : Text("CREATE ACCOUNT →", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
