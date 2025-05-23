import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String error = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isValidEmail(String email) {
    return RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  void register() async {
    setState(() => error = '');

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => error = 'Please fill in all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => error = 'Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      setState(() => error = 'Password must be at least 6 characters long');
      return;
    }

    if (password != confirm) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (mounted) {
        if (response.user != null) {
          // If email confirmation is required, user is created but session might be null.
          // Check if your Supabase project requires email confirmation.
          if (Supabase.instance.client.auth.currentUser?.emailConfirmedAt == null && response.session == null) {
            setState(() => error = 'Registration successful! Please check your email to verify your account.');
            // Optionally, navigate to a page that tells them to check email, or stay here.
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // This case should ideally not happen if signUp is successful without error.
          // If response.user is null and no AuthException, it's an unusual state.
          setState(() => error = 'Registration failed. No user returned. Please check Supabase logs.');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => error = 'Registration failed: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = 'An unexpected error occurred: $e');
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color brown = Color(0xFF5C2E00);
    final Color cream = Color(0xFFF9F5E3);
    const double fieldHeight = 58.0; // Define a consistent height for text fields
    const double fieldBorderRadius = 30.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120), // Adjusted vertical padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/otter_tao.png', // Make sure this path is correct
              height: 120,
            ),
            SizedBox(height: 20),
            Text('REGISTER', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: brown)),
            SizedBox(height: 30),

            // Email Field
            SizedBox(
              height: fieldHeight,
              child: TextField(
                controller: emailController,
                textAlignVertical: TextAlignVertical.center, // Center text vertically
                style: TextStyle(color: Colors.black87),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: brown),
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.black54),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: (fieldHeight - 20) / 2), // Adjust padding for centering
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Password field
            SizedBox(
              height: fieldHeight,
              child: TextField(
                controller: passwordController,
                textAlignVertical: TextAlignVertical.center, // Center text vertically
                obscureText: _obscurePassword,
                style: TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: brown),
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.black54),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: (fieldHeight - 20) / 2), // Adjust padding for centering
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: brown,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Confirm Password field
            SizedBox(
              height: fieldHeight,
              child: TextField(
                controller: confirmController,
                textAlignVertical: TextAlignVertical.center, // Center text vertically
                obscureText: _obscureConfirmPassword,
                style: TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: brown),
                  hintText: 'Confirm Password',
                  hintStyle: TextStyle(color: Colors.black54),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: (fieldHeight - 20) / 2), // Adjust padding for centering
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: brown, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: brown,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  error,
                  style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: register,
              style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: cream,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fieldBorderRadius)
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              child: Text('Register'),
            ),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account? ", style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: brown,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}