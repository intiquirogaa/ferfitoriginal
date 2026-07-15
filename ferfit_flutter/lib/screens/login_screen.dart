import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/clerk_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ferfit_mascot.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true; // true = login, false = signup
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final clerkToken = await ClerkService.getSessionToken();
    final savedToken = await ApiService.getToken();
    final token =
        (clerkToken != null && clerkToken.isNotEmpty) ? clerkToken : savedToken;
    if (token == null || token.isEmpty) return;

    final authResult = await ApiService.authenticate(token);
    if (authResult != null && authResult['success'] == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      });
    } else if (authResult?['_unauthorized'] == true) {
      await ClerkService.clearSession();
      await ApiService.clearToken();
    }
  }

  void _generateSecurePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+';
    final rnd = math.Random();
    final pwd = String.fromCharCodes(Iterable.generate(
        12, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    setState(() {
      _passwordController.text = pwd;
      _obscurePassword = false; // Mostrarla para que el usuario la anote
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Complet\u00e1 todos los campos');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'La contraseña debe tener mínimo 8 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Map<String, dynamic> result;

    if (_isLogin) {
      result = await ClerkService.signIn(email: email, password: password);
    } else {
      result = await ClerkService.signUp(
        email: email,
        password: password,
        firstName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // Save the token for the backend API too
      final token = result['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await ApiService.saveToken(token);
        final authResult = await ApiService.authenticate(token);
        if (authResult == null || authResult['success'] != true) {
          await ClerkService.clearSession();
          await ApiService.clearToken();
          if (mounted) {
            setState(() => _errorMessage =
                'No se pudo autenticar el token con el backend');
          }
          return;
        }
      }
      final user = result['user'] as Map<String, dynamic>?;
      if (user != null && user['name'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', user['name']);
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      setState(() {
        _errorMessage = result['error'] as String? ?? 'Error desconocido';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.primary;
    final bgColor = AppColors.background;
    final borderColor = AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Feo (mascota) animado Ã¢â€â‚¬Ã¢â€â‚¬
                    const Center(
                      child: FerFitMascot(
                        size: 120,
                        mood: FerFitMascotMood.happy,
                        anim: FeoAnim.wave,
                        showName: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Brand Ã¢â€â‚¬Ã¢â€â‚¬
                    Center(
                      child: Text(
                        'FerFit',
                        style: GoogleFonts.rajdhani(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Con Feo, tu coach rayo',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Ã¢â€â‚¬Ã¢â€â‚¬ Card Container Ã¢â€â‚¬Ã¢â€â‚¬
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ã¢â€â‚¬Ã¢â€â‚¬ Toggle Tabs Ã¢â€â‚¬Ã¢â€â‚¬
                          Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!_isLogin) _toggleMode();
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isLogin
                                            ? accentColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Iniciar sesi\u00f3n',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: _isLogin
                                                ? Colors.white
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_isLogin) _toggleMode();
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isLogin
                                            ? accentColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Crear cuenta',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: !_isLogin
                                                ? Colors.white
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Ã¢â€â‚¬Ã¢â€â‚¬ Name Field (Sign Up only) Ã¢â€â‚¬Ã¢â€â‚¬
                          if (!_isLogin) ...[
                            Text(
                              'Nombre',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Tu nombre',
                                hintStyle: GoogleFonts.inter(
                                    color: Colors.grey[600], fontSize: 14),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: Colors.grey[600], size: 20),
                                fillColor: bgColor,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: accentColor, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Ã¢â€â‚¬Ã¢â€â‚¬ Email Field Ã¢â€â‚¬Ã¢â€â‚¬
                          Text(
                            'Correo electr\u00f3nico',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'tu@email.com',
                              hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[600], fontSize: 14),
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: Colors.grey[600], size: 20),
                              fillColor: bgColor,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: accentColor, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Ã¢â€â‚¬Ã¢â€â‚¬ Password Field Ã¢â€â‚¬Ã¢â€â‚¬
                          Text(
                            'Contrase\u00f1a',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleSubmit(),
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Tu contrase\u00f1a',
                              hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[600], fontSize: 14),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: Colors.grey[600], size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              fillColor: bgColor,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: accentColor, width: 1.5),
                              ),
                            ),
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _generateSecurePassword,
                                icon: Icon(Icons.auto_awesome, size: 16, color: accentColor),
                                label: Text(
                                  'Generar clave segura',
                                  style: GoogleFonts.inter(fontSize: 12, color: accentColor),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),

                          // Ã¢â€â‚¬Ã¢â€â‚¬ Error Message Ã¢â€â‚¬Ã¢â€â‚¬
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red[400], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(
                                          color: Colors.red[400],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Ã¢â€â‚¬Ã¢â€â‚¬ Submit Button Ã¢â€â‚¬Ã¢â€â‚¬
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    accentColor.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isLogin
                                          ? 'Iniciar sesi\u00f3n'
                                          : 'Crear cuenta',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
