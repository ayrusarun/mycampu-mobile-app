import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // App Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  // Temporarily test with a simple debug approach
                  child: FutureBuilder(
                    future: Future.delayed(Duration(
                        milliseconds: 100)), // Small delay to see loading
                    builder: (context, snapshot) {
                      print(
                          '🔍 Attempting to load logo from: assets/images/logo.png');
                      return Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Log the error for debugging
                          print('❌ Error loading logo: $error');
                          print('❌ Stack trace: $stackTrace');
                          // Fallback to icon if image fails to load
                          return Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.red
                                  .shade100, // Changed to red to make it obvious this is fallback
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.red.shade300,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error,
                                  size: 60,
                                  color: Colors.red.shade700,
                                ),
                                Text(
                                  'Logo Error',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Title
              Text(
                'MyCampus',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Your College Community Hub',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Connect, collaborate, and stay updated with your college community',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 3),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary Action
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                child: Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
