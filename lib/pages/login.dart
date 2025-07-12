import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color brownColor = const Color(0xFF5C2E00);
  final Color creamColor = const Color(0xFFF9F5E3);
  final Color scaffoldBgColor = Colors.white;

  final double fieldHeight = 58.0;
  final double fieldBorderRadius = 30.0;
  // Define a clear vertical padding for content within the TextField.
  // For a fieldHeight of 58, vertical padding of 18 leaves 58 - 18*2 = 22 for text, which is good.
  final double textFieldVerticalContentPadding = 18.0;


  Future<void> login() async {
    setState(() {
      error = '';
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        setState(() {
          error = 'Please fill in all fields.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      if (mounted) {
        if (response.user != null) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() {
            error = 'Login failed. Please check your credentials.';
            _isLoading = false;
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/otter_tao.png',
              height: 120,
            ),
            const SizedBox(height: 20),
            Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: brownColor,
              ),
            ),
            const SizedBox(height: 30),

            // Email field
            SizedBox(
              height: fieldHeight,
              child: TextField(
                controller: emailController,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.black87),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: brownColor),
                  hintText: 'Email',
                  hintStyle: const TextStyle(color: Colors.black54),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: textFieldVerticalContentPadding, // Applied consistent padding
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: brownColor),
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: brownColor, width: 2),
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password field
            SizedBox(
              height: fieldHeight,
              child: TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: brownColor),
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.black54),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: textFieldVerticalContentPadding, // Applied consistent padding
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: brownColor),
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: brownColor, width: 2),
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: brownColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    // You can also try adding padding: EdgeInsets.zero here if needed,
                    // but suffixIconConstraints is often more direct.
                  ),
                  // Key Change: Add suffixIconConstraints
                  suffixIconConstraints: const BoxConstraints(
                    maxHeight: 36, // Limit the height the suffix icon can influence
                    // minHeight: 36, // Optionally set minHeight if needed
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 10.0),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            _isLoading
                ? CircularProgressIndicator(color: brownColor)
                : ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                foregroundColor: creamColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('Login'),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ", style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: () {
                    if(mounted){
                      setState(() { error = ''; });
                    }
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: brownColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}