import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerified = false;
  bool _isCheckingStatus = true;
  Timer? _timer;
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color errorColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    // Start periodic check for email verification
    _checkEmailVerified();
  }

  void _startVerificationCheck() {
    // Check immediately
    _checkEmailVerified();

    // Then check every 3 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final auth = FirebaseAuth.instance;
    final authService = Provider.of<AuthService>(context, listen: false);

    // Set up timer to check verification status periodically
    _timer = Timer.periodic(Duration(seconds: 3), (_) async {
      await auth.currentUser?.reload();

      final user = auth.currentUser;
      if (user != null && user.emailVerified) {
        setState(() {
          _isVerified = true;
          _isCheckingStatus = false;
        });

        _timer?.cancel();

        // Process any pending invitations now that email is verified
        await authService.processInvitationsForCurrentUser();

        // Get user role to determine the appropriate home route
        final String userRole = await authService.getUserRole();

        // Navigate to appropriate home screen based on role
        Future.delayed(Duration(seconds: 1), () {
          String homeRoute;

          // Determine route based on user role
          switch (userRole.toLowerCase()) {
            case 'product_owner':
              homeRoute = '/productOwnerHome';
              break;
            case 'scrum master':
              homeRoute = '/scrumMasterHome';
              break;
            case 'team member':
              homeRoute = '/teamMemberHome';
              break;
            case 'client':
              homeRoute = '/clientHome';
              break;
            default:
            // Default to product owner if role is unknown
              homeRoute = '/productOwnerHome';
          }

          Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute,
                (route) => false,
          );
        });
      } else {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Registration?'),
        content: Text(
          'This will delete your unverified account. You\'ll need to register again if you change your mind.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _isLoading = true;
              });

              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.deleteUnverifiedAccount();
                await authService.signOut();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account deleted'),
                      backgroundColor: Colors.orange,
                    ),
                  );

                  Navigator.pushReplacementNamed(context, '/signup');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
            ),
            child: Text('Yes, Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Verify Your Email',
          style: TextStyle(
            color: Color(0xFF313131),
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isVerified ? Icons.verified_user : Icons.mark_email_unread,
              size: 80,
              color: _isVerified ? Colors.green : primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              _isVerified
                  ? 'Email Verified!'
                  : 'Waiting for Verification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isVerified ? Colors.green : Color(0xFF313131),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isVerified
                  ? 'Your email has been verified successfully. Redirecting to login...'
                  : 'We\'ve sent a verification link to ${widget.email}\n\nPlease check your inbox and click the link to verify your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),
            if (!_isVerified) ...[
              ElevatedButton.icon(
                onPressed: _resendVerificationEmail,
                icon: Icon(Icons.email),
                label: Text('Resend Verification Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // Go back to login
                      final authService = Provider.of<AuthService>(context, listen: false);
                      authService.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                    child: const Text('Back to Login'),
                  ),
                  TextButton(
                    onPressed: _deleteAccount,
                    style: TextButton.styleFrom(
                      foregroundColor: errorColor,
                    ),
                    child: const Text('Cancel Registration'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}