import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';

/// Redesigned Auth screen with iOS-inspired onboarding and auth.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _useEmail = false;
  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(supabaseAuthServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (_isRegistering && password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (_isLoading) return; // Prevent double-tap

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(supabaseAuthServiceProvider);
      if (_isRegistering) {
        final user = await authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Supabase requires email confirmation by default.
        // If signup succeeded but there's no active session, tell the user.
        if (user != null && authService.currentUser?.emailConfirmedAt == null) {
          if (mounted) {
            TopNotification.showSuccess(context, 'Account created! Check your email to confirm before signing in.');
            // Switch to sign-in view so user can sign in after confirming email
            setState(() => _isRegistering = false);
          }
          return;
        }
        // If no email confirmation required, the authStateProvider change
        // will trigger the router redirect automatically
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // The authStateProvider change will trigger the redirect automatically
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    TopNotification.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final bool showingAuth = (_currentPage == 3) || (_currentPage == 2 && _useEmail);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            // Background Decorative Element
            if (!showingAuth)
              Positioned(
                top: -150,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emerald50.withValues(alpha: 0.5),
                  ),
                ),
              ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0 || _useEmail)
                          IconButton(
                            onPressed: () {
                              if (_useEmail) {
                                setState(() => _useEmail = false);
                              } else if (_currentPage > 0) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900, size: 28),
                          )
                        else
                          const SizedBox(width: 48),
                        
                        if (!showingAuth)
                          TextButton(
                            onPressed: () => setState(() => _currentPage = 3),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.grey600,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: !showingAuth 
                        ? _buildOnboardingFlow()
                        : _buildAuthView(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingFlow() {
    return Column(
      key: const ValueKey('onboarding'),
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildOnboardingSlide(
                imagePath: 'assets/images/onboarding_page_1.jpeg',
                title: 'Professional Grade\nScoring',
                description: 'Log every stroke, putt, and penalty with effortless hole-by-hole tracking tailored for your game.',
                color: AppColors.emerald700,
              ),
              _buildOnboardingSlide(
                imagePath: 'assets/images/onboarding_page_2.jpeg',
                title: 'Your Digital\nCaddie',
                description: 'Track your clubs, manage your equipment, and get the insights you need to improve your handicap.',
                color: AppColors.blue700,
              ),
              _buildOnboardingSlide(
                imagePath: 'assets/images/onboarding_page_3.jpeg',
                title: 'Data-Driven\nPerformance',
                description: 'Visualize your progress with advanced analytics and securely sync your data to the cloud.',
                color: AppColors.purple700,
              ),
            ],
          ),
        ),
        _buildOnboardingFooter(),
      ],
    );
  }

  Widget _buildOnboardingSlide({
    required String imagePath,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/final-logo-01.png', height: 80, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.grey900,
              letterSpacing: -1.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey500,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildOnboardingFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Indicators
          Row(
            children: List.generate(3, (index) => _buildIndicator(index == _currentPage)),
          ),
          
          // Next Button
          GestureDetector(
            onTap: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                setState(() => _currentPage = 3);
              }
            },
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey100, width: 2),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.grey900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowRight, color: AppColors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.grey900 : AppColors.grey200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildAuthView() {
    return SingleChildScrollView(
      key: const ValueKey('auth'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/final-logo-01.png',
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isRegistering ? 'Create Account' : 'Welcome Back',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.grey900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRegistering 
              ? 'Join our community of elite golfers today.' 
              : 'Sign in to access your stats and rounds.',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),
          
          if (_useEmail) ...[
            _buildInputField(
              controller: _emailController,
              label: 'EMAIL ADDRESS',
              hint: 'tiger@scorecaddie.com',
              icon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _passwordController,
              label: 'PASSWORD',
              hint: '••••••••',
              icon: LucideIcons.lock,
              obscureText: _obscurePassword,
              isPassword: true,
            ),
            
            if (_isRegistering) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _agreedToTerms ? AppColors.emerald700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _agreedToTerms ? AppColors.emerald700 : AppColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: _agreedToTerms 
                        ? const Icon(LucideIcons.check, color: Colors.white, size: 14)
                        : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w600),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const TermsScreen()),
                              ),
                              child: const Text(
                                'Terms',
                                style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                              ),
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 40),
            _buildPrimaryButton(
              onPressed: (_isLoading || (_isRegistering && !_agreedToTerms)) ? null : _handleEmailAuth,
              label: _isRegistering ? 'Create Account' : 'Sign In',
            ),
          ] else ...[
            _buildPrimaryButton(
              onPressed: () => setState(() => _useEmail = true),
              label: 'Sign in with Email',
              icon: LucideIcons.mail,
            ),
          ],
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: AppColors.grey100)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: AppColors.grey300, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
              Expanded(child: Container(height: 1, color: AppColors.grey100)),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildSocialButton(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            label: _isRegistering ? 'Sign up with Google' : 'Sign in with Google',
            icon: LucideIcons.user,
          ),
          
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _isRegistering = !_isRegistering),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.grey500, fontSize: 15, fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(text: _isRegistering ? 'Already have an account? ' : 'Don\'t have an account? '),
                    TextSpan(
                      text: _isRegistering ? 'Sign In' : 'Sign Up',
                      style: const TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey400,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey100),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.grey300, fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
              suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, 
                      color: AppColors.grey400, 
                      size: 20
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(
        onPressed: onPressed,
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.white),
                  const SizedBox(width: 12),
                ],
                Text(label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grey900,
          side: const BorderSide(color: AppColors.grey200, width: 1.5),
          backgroundColor: AppColors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
