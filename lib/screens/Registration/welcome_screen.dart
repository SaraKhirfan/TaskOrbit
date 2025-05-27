import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE53935);
  static const Color shadowColor = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F3),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Welcome (1).png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(  // Added this
            child: ConstrainedBox(     // Added this
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(   // Added this
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(      // Added this
                        flex: 2,     // Takes 2/3 of available space
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,  // Added this
                          children: [
                            const SizedBox(height: 8),
                            Image.asset(
                              'assets/images/task-orbit-logo.png',
                              width: MediaQuery.of(context).size.width * 0.75,  // Responsive width
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Welcome to TaskOrbit',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                              textAlign: TextAlign.center,  // Added this
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Plan, Track, and Succeed',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All in one place!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Bottom Section with Buttons
                      Expanded(      // Added this
                        flex: 1,     // Takes 1/3 of available space
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,  // Added this
                          children: [
                            // Log In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  foregroundColor: primaryColor,
                                  backgroundColor: Color(0xFF004AAD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFFFDFDFD),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            Text(
                              'Don\'t have an account?',
                              style: TextStyle(
                                color: Color(0xFF313131),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  foregroundColor: primaryColor,
                                  backgroundColor: Color(0xFFFDFDFD),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: Color(0xFF004AAD),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF004AAD),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 48),
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
      ),
    );
  }
}