import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _errorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _errorAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE53935);
  static const Color shadowColor = Color(0x1A000000);
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _errorAnimationController.dispose();
    super.dispose();
  }
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        // Get auth service from provider
        final authService = Provider.of<AuthService>(context, listen: false);

        // Sign in with email and password
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Get the user's role
        final userRole = await authService.getUserRole();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Navigate to the appropriate home screen based on role
          if (userRole == 'Scrum Master') {
            Navigator.pushReplacementNamed(context, '/scrumMasterHome');
          } else if (userRole == 'Product_Owner') {
            Navigator.pushReplacementNamed(context, '/productOwnerHome');
          } else if (userRole == 'Team Member') {
            Navigator.pushReplacementNamed(context, '/teamMemberHome');
          } else if (userRole == 'Client') {
            Navigator.pushReplacementNamed(context, '/clientHome');
          }
        }
      } catch (e) {
        // Handle login errors
        setState(() {
          _isLoading = false;
          _errorMessage = _getFirebaseErrorMessage(e.toString());
        });
        _errorAnimationController.forward(from: 0);
      }
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    if (errorCode.contains('user-not-found')) {
      return 'No account found with this email';
    } else if (errorCode.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorCode.contains('invalid-email')) {
      return 'Please provide a valid email';
    } else if (errorCode.contains('user-disabled')) {
      return 'This account has been disabled';
    } else if (errorCode.contains('email-not-verified')) {
      return 'Please verify your email before logging in';
    } else if (errorCode.contains('network-request-failed')) {
      return 'Network error. Check your connection';
    } else {
      return 'Login failed. Please try again';
    }
  }
  InputDecoration _getModernInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: primaryColor, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Color(0xFFFDFDFD),
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      constraints: const BoxConstraints(minHeight: 56),
      alignLabelWithHint: true,
      isCollapsed: false,
      prefixIconColor: primaryColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      errorStyle: TextStyle(
        color: errorColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;
    String? successMessage;

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFFEDF1F3),
              title: Text(
                'Reset Password',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: resetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter your email address and we\'ll send you a link to reset your password.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF313131),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: primaryColor,
                        decoration: _getModernInputDecoration(
                          label: 'Email',
                          icon: Icons.email,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      if (errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: errorColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: errorColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (successMessage != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            successMessage!,
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (resetFormKey.currentState!.validate()) {
                      // Set loading state
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                        successMessage = null;
                      });

                      try {
                        // Get auth service
                        final authService = Provider.of<AuthService>(
                            context,
                            listen: false
                        );

                        // Send password reset email
                        await authService.resetPassword(
                            resetEmailController.text.trim()
                        );

                        // Show success message
                        setState(() {
                          isLoading = false;
                          successMessage = 'Password reset link sent to your email';
                        });

                        // Close dialog after short delay
                        Future.delayed(Duration(seconds: 2), () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        });
                      } catch (e) {
                        // Handle errors
                        setState(() {
                          isLoading = false;
                          errorMessage = _getResetPasswordErrorMessage(e.toString());
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withOpacity(0.6),
                  ),
                  child: isLoading
                      ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Get user-friendly error message for password reset errors
  String _getResetPasswordErrorMessage(String errorCode) {
    if (errorCode.contains('user-not-found')) {
      return 'No user found with this email';
    } else if (errorCode.contains('invalid-email')) {
      return 'Invalid email format';
    } else if (errorCode.contains('missing-android-pkg-name')) {
      return 'Reset link sent (mock). Check your email.';
    } else if (errorCode.contains('network-request-failed')) {
      return 'Network error. Check your connection';
    } else {
      return 'Error sending reset link. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F3),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Welcome (1).png'),
              fit: BoxFit.cover, // Ensure the image covers the entire screen
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Divider(
                    height: 10,
                    thickness: 1,
                    color: Colors.transparent,
                  ),
                  const SizedBox(height: 20),
                  Image.asset('assets/images/task-orbit-logo.png', width: 250),
                  const SizedBox(height: 26),

                  const Text(
                    'Log in to your Account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your email and password to log in',
                    style: TextStyle(fontSize: 14, color: Color(0xFF313131)),
                  ),
                  const SizedBox(height: 32),

                  // Display error message if any
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: errorColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Modern Email Input Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          // Set to email type
                          cursorColor: primaryColor,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF313131),
                          ),
                          decoration: _getModernInputDecoration(
                            label: 'Email',
                            icon: Icons.email,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Modern Password Input Field (Shadow Removed)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              keyboardType: TextInputType.visiblePassword,
                              // Set to password type
                              obscureText: _obscurePassword,
                              cursorColor: primaryColor,
                              onChanged: (value) {
                                setState(
                                      () {},
                                ); // Trigger rebuild for password strength
                              },
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF313131),
                              ),
                              decoration: _getModernInputDecoration(
                                label: 'Password',
                                icon: Icons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  _errorAnimationController.forward(from: 0);
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                _showForgotPasswordDialog();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: primaryColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: primaryColor.withOpacity(
                                  0.6),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sign Up Prompt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Don\'t have an account?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF313131),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}