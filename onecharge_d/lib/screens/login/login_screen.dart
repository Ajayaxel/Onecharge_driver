import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_bloc.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_event.dart';
import 'package:onecharge_d/logic/blocs/auth/auth_state.dart';
import 'package:onecharge_d/widgets/onebtn.dart';
import 'package:onecharge_d/widgets/custom_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isChecked = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isChecked) {
      CustomToast.show(
        context,
        "Please accept privacy policy and terms",
        isError: true,
      );
      return;
    }

    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background/Top Section
          Column(
            children: [
              SizedBox(height: topPadding + size.height * 0.05),
              if (!isKeyboardVisible) ...[
                Center(
                  child: Image.asset(
                    'images/logo/onechargelogo.png',
                    fit: BoxFit.contain,
                    color: Colors.white,
                    height: size.height * 0.045,
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Electric vehicle charging\nstation for everyone.\nDiscover. Charge. Pay.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.height * 0.024,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lufga',
                      height: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
              ] else ...[
                // Small top section when keyboard is visible
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Image.asset(
                      'images/logo/onechargelogo.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                      height: 30,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ],
          ),

          // Login Form Section (Bottom Sheet style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (!isKeyboardVisible)
                  Positioned(
                    top:
                        -size.height *
                        0.16, // Adjusts image to sit on top of the sheet
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'images/logo/carimage.png',
                        fit: BoxFit.contain,
                        width: size.width * 0.95,
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: size.width,
                  padding: EdgeInsets.only(
                    bottom: isKeyboardVisible ? keyboardHeight : bottomPadding,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: size.height * (isKeyboardVisible ? 0.9 : 0.65),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Lufga',
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Enter your email and password to proceed",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black54,
                                fontFamily: 'Lufga',
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontFamily: 'Lufga'),
                              decoration: _buildInputDecoration(
                                'Enter your email',
                                Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Please enter your email';
                                if (!value.contains('@'))
                                  return 'Please enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontFamily: 'Lufga'),
                              decoration: _buildInputDecoration(
                                'Enter your password',
                                Icons.lock_outline,
                                isPassword: true,
                                obscureText: _obscurePassword,
                                onToggleVisibility: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Please enter your password';
                                if (value.length < 6)
                                  return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    activeColor: Colors.black,
                                    value: _isChecked,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (value) => setState(
                                      () => _isChecked = value ?? false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    "I accept the Privacy Policy and Terms of Service",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontFamily: 'Lufga',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            BlocConsumer<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state is AuthAuthenticated) {
                                  CustomToast.show(context, state.message);
                                } else if (state is AuthError) {
                                  CustomToast.show(
                                    context,
                                    state.message,
                                    isError: true,
                                  );
                                }
                              },
                              builder: (context, state) {
                                return OneBtn(
                                  text: "Login",
                                  onPressed: _handleLogin,
                                  isLoading: state is AuthLoading,
                                );
                              },
                            ),
                            SizedBox(height: isKeyboardVisible ? 20 : 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black54, size: 20),
      hintStyle: const TextStyle(
        color: Color(0xffB8B9BD),
        fontFamily: 'Lufga',
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.black54,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            )
          : null,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffE4E4E4)),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xffE4E4E4)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
