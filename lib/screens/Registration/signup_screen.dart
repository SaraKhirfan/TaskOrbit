import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';
import 'EmailVerificationScreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}
class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _errorAnimationController;
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  DateTime? _birthDate;
  String? _selectedRole;
  final List<String> _roles = [
    'Product Owner',
    'Scrum Master',
    'Team Member',
    'Client',
  ];
  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation
      if (_selectedRole == null) {
        setState(() {
          _errorMessage = 'Please select a role';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Get auth service from provider
        final authService = Provider.of<AuthService>(context, listen: false);

        // Create user with email and password
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _fullNameController.text.trim(),
          _selectedRole!,
        );

        // Add additional user data
        if (_birthDate != null) {
          await authService.updateUserProfile({
            'birthDate': _birthDate!.toIso8601String(),
          });
        }

        // Send email verification
        await authService.sendEmailVerification();

        // Navigate to verification screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } catch (e) {
        // Handle signup errors
        setState(() {
          _isLoading = false;
          _errorMessage = _getFirebaseErrorMessage(e.toString());
        });
      }
    }
  }
  void _showVerificationDialog() {
    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          // Prevent dismissing by back button
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: primaryColor,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    color: Color(0xFF313131),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'ve sent a verification email to:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _emailController.text.trim(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'You must verify your email before you can sign in. Please check your inbox and click the verification link.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF313131),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final authService = Provider.of<AuthService>(context, listen: false);

                  try {
                    await authService.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Verification email resent'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to resend email. Try again later.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Resend Email'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Get user-friendly error message
  String _getFirebaseErrorMessage(String errorCode) {
    if (errorCode.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    } else if (errorCode.contains('invalid-email')) {
      return 'Please provide a valid email';
    } else if (errorCode.contains('weak-password')) {
      return 'Password is too weak. Try a stronger password';
    } else if (errorCode.contains('network-request-failed')) {
      return 'Network error. Check your connection';
    } else {
      return 'Signup failed. Please try again';
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(
                0xFF004AAD,
              ), // Primary color for header and selected day
              onPrimary: Color(
                0xFFFDFDFD,
              ), // Text color for header and selected day
              surface: Color(0xFFFDFDFD), // Background color of the calendar
              onSurface: Color(0xFF313131), // Text color for days
            ),
            dialogTheme: DialogTheme(
              backgroundColor: Color(0xFFFDFDFD),
            ), // Background color of the dialog
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }
  static const Color primaryColor = Color(0xFF004AAD);
  static const Color errorColor = Color(0xFFE53935);
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _errorAnimationController.dispose();
    super.dispose();
  }
  String _getPasswordStrength() {
    String password = _passwordController.text;
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 8) return 'Medium';
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );
    if (hasUppercase && hasDigits && hasSpecialCharacters) return 'Strong';
    return 'Medium';
  }


  Color _getPasswordStrengthColor() {
    switch (_getPasswordStrength()) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.transparent;
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
      fillColor: const Color(0xFFFDFDFD),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F3),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Sign Up.png'),
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
                  Image.asset('assets/images/task-orbit-logo.png', width: 130),
                  const SizedBox(height: 10),
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Create an account to continue!',
                      style: TextStyle(fontSize: 14, color: Color(0xFF313131)),
                    ),
                  ),
                  const SizedBox(height: 30),

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
                        // Full Name Input Field
                        TextFormField(
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          // Set to name type
                          cursorColor: primaryColor,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF313131),
                          ),
                          decoration: _getModernInputDecoration(
                            label: 'Full Name',
                            icon: Icons.person,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Email Input Field
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

                        // Password Input Field
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
                                if (value.length < 6) {
                                  _errorAnimationController.forward(from: 0);
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            if (_passwordController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: _getPasswordStrengthColor(),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getPasswordStrength(),
                                      style: TextStyle(
                                        color: _getPasswordStrengthColor(),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Date of Birth Field
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              keyboardType: TextInputType.datetime,
                              // Set to date type
                              cursorColor: primaryColor,
                              decoration: _getModernInputDecoration(
                                label: 'Date of Birth',
                                icon: Icons.calendar_today,
                              ),
                              controller: TextEditingController(
                                text: _birthDate == null
                                    ? ''
                                    : DateFormat('yyyy-MM-dd').format(
                                    _birthDate!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Role Selection
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFDFD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedRole == null
                                  ? const Color(0xFFE0E0E0)
                                  : primaryColor,
                              width: _selectedRole == null ? 1 : 2,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF666666),
                              ),
                              isExpanded: true,
                              dropdownColor: const Color(0xFFFDFDFD),
                              borderRadius: BorderRadius.circular(12),
                              hint: Row(
                                children: [
                                  Icon(
                                    Icons.work,
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Select Role',
                                    style: TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue;
                                });
                              },
                              items: _roles.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.work,
                                          color: primaryColor,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          value.replaceAll('_', ' '),
                                          style: const TextStyle(
                                            color: Color(0xFF313131),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login Prompt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF313131),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              child: const Text(
                                'Log in',
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