import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

/// صفحه لاگین اصلی (بدون اشاره به دمو)
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  bool _rememberMe = true; // می‌توان بعدا به SharedPreferences وصل کرد

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await context.read<AppState>().login(_userCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    if (ok) {
      widget.onLoggedIn();
    } else {
      setState(() {
        _error = 'Invalid username or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final sizeOffset = appState.getTextSizeOffset();
    final primary = appState.primaryColor;
    final darker = Color.lerp(primary, Colors.black, theme.brightness == Brightness.dark ? 0.15 : 0.35)!;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withOpacity(.9),
                    darker.withOpacity(.95),
                  ],
                ),
              ),
            ),
          ),
          // Decorative blurred circles
          Positioned(
            top: -80,
            left: -40,
            child: _blurBlob(primary.withOpacity(.35), 260),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _blurBlob(primary.withOpacity(.25), 300),
          ),
          // Content
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (ctx, c) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _logoHeader(sizeOffset, primary),
                          const SizedBox(height: 28),
                          _headline(sizeOffset, theme),
                          const SizedBox(height: 24),
                          _modernCard(
                            context: context,
                            primary: primary,
                            sizeOffset: sizeOffset,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _tagRow(primary),
                                const SizedBox(height: 20),
                                _form(theme, sizeOffset, primary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Opacity(
                            opacity: .55,
                            child: Center(
                              child: Text('© 2025 MeProp',
                                  style: TextStyle(fontSize: 12 + sizeOffset, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoHeader(double off, Color primary) {
    return Row(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: primary.withOpacity(.4), blurRadius: 18, offset: const Offset(0, 6)),
              ],
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/logo_community.png'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'MeProp Asset Tracker',
            style: TextStyle(
              fontSize: 24 + off,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _headline(double off, ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign in',
            style: TextStyle(
              fontSize: 34 + off,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your credentials to continue',
            style: TextStyle(
              fontSize: 15 + off,
              color: Colors.white.withOpacity(.78),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );

  Widget _modernCard(
      {required BuildContext context, required Color primary, required double sizeOffset, required Widget child}) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(2.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [primary.withOpacity(.85), primary.withOpacity(.35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(.45), blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(.88),
            ),
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 32),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _tagRow(Color primary) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _miniTag(primary, Icons.pie_chart_rounded, 'Portfolio'),
        _miniTag(primary, Icons.account_balance_wallet_outlined, 'Wallet'),
        _miniTag(primary, Icons.real_estate_agent_outlined, 'Real Estate'),
        _miniTag(primary, Icons.timeline_rounded, 'Analytics'),
      ],
    );
  }

  Widget _miniTag(Color primary, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(.35), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: primary),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: primary)),
      ]),
    );
  }

  Widget _form(ThemeData theme, double off, Color primary) {
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: primary, width: 1.4),
    );
    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: theme.colorScheme.surface.withOpacity(.9),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(.25)),
          ),
          focusedBorder: focusBorder,
        );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _userCtrl,
            textInputAction: TextInputAction.next,
            decoration: deco('Username', Icons.person_outline),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: deco('Password', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: primary),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onFieldSubmitted: (_) async => await _submit(),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: primary.withOpacity(.7), width: 1),
                activeColor: primary,
              ),
              Expanded(child: Text('Remember me', style: TextStyle(fontSize: 13 + off))),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: primary),
                child: Text('Forgot password?', style: TextStyle(fontSize: 13 + off)),
              )
            ],
          ),
          const SizedBox(height: 4),
          _submitButton(primary, off),
          if (_error != null) ...[
            const SizedBox(height: 18),
            _errorBanner(theme, off),
          ],
        ],
      ),
    );
  }

  Widget _submitButton(Color primary, double off) {
    return GestureDetector(
      onTap: _loading ? null : () async => await _submit(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [primary, Color.lerp(primary, Colors.black, .2)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: primary.withOpacity(.55), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 + off,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .3,
                        )),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _errorBanner(ThemeData theme, double off) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.red.withOpacity(.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(.4))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(_error ?? '', style: TextStyle(color: Colors.redAccent, fontSize: 13 + off)))
        ],
      ));

  Widget _blurBlob(Color color, double size) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }
}
