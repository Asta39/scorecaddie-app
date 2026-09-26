import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

/// Intro carousel and sign-in, as in the approved prototype.
///
/// The auth behaviour is unchanged from the previous screen: Google sign-in,
/// email sign-in, and email sign-up with terms consent and the "confirm your
/// email" hand-off. The router moves on once the session changes.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _Slide {
  const _Slide(this.eyebrow, this.title, this.body, {this.image, this.alt});
  final String eyebrow, title, body;
  final String? image, alt;
}

const _slides = [
  _Slide('ScoreCaddie · Kenya', 'Every shot, counted.', 'Score your round hole by hole and let your handicap keep itself up to date.',
      image: 'assets/images/onboarding_page_3.jpeg', alt: 'A golf ball on the lip of the cup'),
  _Slide('Your club’s real card', 'Played on the official scorecard.', 'Stroke index and yardages entered by your club, including nine-hole cards.',
      image: 'assets/images/onboarding_page_1.jpeg', alt: 'An illustrated fairway from above'),
  _Slide('Meet Daniel', 'A caddie in your pocket.', 'Say the shot out loud. Daniel logs it and tells you the one fix that matters.'),
];

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _signIn = false; // false = intro carousel
  int _slide = 0;
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  late final AnimationController _kenBurns = AnimationController(vsync: this, duration: const Duration(seconds: 18))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _kenBurns.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── auth (unchanged behaviour) ──────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(supabaseAuthServiceProvider).signInWithGoogle();
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
    if (_isRegistering && !_agreedToTerms) {
      _showError('Please agree to the Terms and Privacy Policy.');
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(supabaseAuthServiceProvider);
      if (_isRegistering) {
        final user = await authService.registerWithEmail(email, password);
        // Email confirmation is on: no session until they confirm.
        if (user != null && authService.currentUser?.emailConfirmedAt == null) {
          if (mounted) {
            TopNotification.showSuccess(context, 'Account created! Check your email to confirm before signing in.');
            setState(() => _isRegistering = false);
          }
          return;
        }
      } else {
        await authService.signInWithEmail(email, password);
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

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        resizeToAvoidBottomInset: true,
        body: DefaultTextStyle(style: Ob.textBase, child: _signIn ? _buildSignIn(context) : _buildIntro(context)),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final slide = _slides[_slide];
    final pad = MediaQuery.of(context).padding;
    return Stack(
      children: [
        // Background: photo with a slow Ken Burns, or Daniel on the last slide.
        Positioned.fill(
          child: slide.image != null
              ? AnimatedBuilder(
                  animation: _kenBurns,
                  builder: (context, child) {
                    final k = Curves.easeInOut.transform(_kenBurns.value);
                    return FractionalTranslation(
                      translation: Offset(-.03 * k, -.04 * k),
                      child: Transform.scale(scale: 1.06 + .14 * k, child: child),
                    );
                  },
                  child: Image.asset(
                    slide.image!,
                    key: ValueKey(slide.image),
                    fit: BoxFit.cover,
                    semanticLabel: slide.alt,
                  ),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 130),
                    child: BotImage(ObBot.clover.idle, size: 290, semanticLabel: 'Daniel, the clover caddie, looking around'),
                  ),
                ),
        ),
        // Scrim so the copy reads over any photo.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x9906110B), Color(0x0006110B), Color(0x0006110B), Color(0xF006110B), Ob.bg],
                stops: [0, .2, .44, .68, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: pad.top + 12,
          child: Row(
            children: [
              Image.asset('assets/images/logo_mark.png', height: 46, excludeFromSemantics: true),
              const SizedBox(width: 10),
              Text('ScoreCaddie', style: Ob.display(30, height: 1)),
              const Spacer(),
              ObButton(
                tone: ObButtonTone.dark,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: () => setState(() => _signIn = true),
                child: Text('Skip', style: Ob.label(14, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: pad.bottom + 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: ValueKey(_slide),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slide.eyebrow.toUpperCase(), style: Ob.eyebrow()).rise(),
                    const SizedBox(height: 12),
                    Semantics(header: true, child: Text(slide.title, style: Ob.display(48, height: 1.02)).rise(1)),
                    const SizedBox(height: 12),
                    Text(slide.body, style: Ob.body(16, height: 1.5, color: Ob.creamA(.78))).rise(2),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ObWormDots(index: _slide, count: _slides.length),
                  ObButton(
                    onPressed: () {
                      if (_slide < _slides.length - 1) {
                        setState(() => _slide++);
                      } else {
                        setState(() => _signIn = true);
                      }
                    },
                    child: Text(_slide == _slides.length - 1 ? 'Get started' : 'Next', style: Ob.label(16, weight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignIn(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(builder: (context, box) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight - 36),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => setState(() => _signIn = false)),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BotImage(ObBot.clover.idle, size: 96, semanticLabel: ObBot.clover.label),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: ObBubble(
                            key: ValueKey(_isRegistering),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Text(
                              _isRegistering ? 'Karibu! Let’s get you set up.' : 'Karibu! Let’s get you on the tee.',
                              style: Ob.body(15, weight: FontWeight.w600, color: Ob.ink, height: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Semantics(
                    header: true,
                    child: Text(_isRegistering ? 'Create your account' : 'Sign in to ScoreCaddie', style: Ob.display(42, height: 1.05)),
                  ).rise(),
                  const SizedBox(height: 22),
                  ObButton(
                    tone: ObButtonTone.light,
                    radius: 16,
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/google_g.png', width: 20, height: 20, excludeFromSemantics: true),
                        const SizedBox(width: 12),
                        Text('Continue with Google', style: Ob.body(16, weight: FontWeight.w700, color: Ob.ink)),
                      ],
                    ),
                  ).rise(1),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: .12))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR', style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.5), letterSpacing: 1.44)),
                      ),
                      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: .12))),
                    ],
                  ).rise(2),
                  const SizedBox(height: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Email'),
                      const SizedBox(height: 12),
                      _field(
                        controller: _emailController,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 12),
                      _label('Password'),
                      const SizedBox(height: 12),
                      _field(
                        controller: _passwordController,
                        hint: 'At least 6 characters',
                        obscure: _obscurePassword,
                        autofill: [_isRegistering ? AutofillHints.newPassword : AutofillHints.password],
                        suffix: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: Ob.creamA(.55)),
                        ),
                      ),
                      if (_isRegistering) ...[
                        const SizedBox(height: 16),
                        _termsConsent(),
                      ],
                    ],
                  ).rise(3),
                  const Spacer(),
                  const SizedBox(height: 22),
                  ObButton(
                    onPressed: _isLoading ? null : _handleEmailAuth,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Ob.ink))
                        : Text(_isRegistering ? 'Create account' : 'Continue with email', style: Ob.label(16, weight: FontWeight.w800)),
                  ).rise(4),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _isRegistering = !_isRegistering),
                      child: Text.rich(
                        TextSpan(
                          style: Ob.body(14, weight: FontWeight.w600, color: Ob.creamA(.7)),
                          children: [
                            TextSpan(text: _isRegistering ? 'Have an account? ' : 'New to ScoreCaddie? '),
                            TextSpan(text: _isRegistering ? 'Sign in' : 'Create an account', style: const TextStyle(color: Ob.lime)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      style: Ob.body(12, height: 1.5, color: Ob.creamA(.55)),
                      children: [
                        const TextSpan(text: 'By continuing you agree to our '),
                        _link('Terms', const TermsScreen()),
                        const TextSpan(text: ' and '),
                        _link('Privacy Policy', const PrivacyScreen()),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  InlineSpan _link(String text, Widget page) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
          child: Text(text, style: Ob.body(12, height: 1.5, color: Ob.lime)),
        ),
      );

  Widget _termsConsent() => GestureDetector(
        onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          checked: _agreedToTerms,
          label: 'I agree to the Terms and Privacy Policy',
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _agreedToTerms ? Ob.lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _agreedToTerms ? Ob.lime : Ob.fieldBorder, width: 2),
                ),
                child: _agreedToTerms ? const Icon(LucideIcons.check, size: 14, color: Ob.ink) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('I agree to the Terms and Privacy Policy', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.72))),
              ),
            ],
          ),
        ),
      );

  Widget _label(String text) => Text(text, style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.72)));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    Iterable<String>? autofill,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: 2));
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        autocorrect: false,
        autofillHints: autofill,
        cursorColor: Ob.lime,
        style: Ob.body(16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Ob.body(16, color: Ob.creamA(.35)),
          filled: true,
          fillColor: Ob.field,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          enabledBorder: border(Ob.fieldBorder),
          focusedBorder: border(Ob.lime),
          border: border(Ob.fieldBorder),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
