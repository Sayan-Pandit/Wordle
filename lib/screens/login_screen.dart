import 'package:flutter/material.dart';
import 'package:wordle/services/auth_service.dart';
import 'package:wordle/screens/register_screen.dart';
import 'package:wordle/screens/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // No manual navigation needed! AuthWrapper in main.dart handles it.
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        
        // Map technical Firebase errors to friendly messages
        if (msg.contains('invalid-credential') || msg.contains('wrong-password') || msg.contains('user-not-found')) {
          msg = "Invalid email or password. Please try again.";
        } else if (msg.contains('too-many-requests')) {
          msg = "Too many attempts. Please try again later.";
        } else if (msg.contains('network-request-failed')) {
          msg = "Network error. Check your connection.";
        } else if (msg.contains('] ')) {
          msg = msg.split('] ').last;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // No manual navigation needed!
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        
        // Map technical Firebase errors to friendly messages
        if (msg.contains('invalid-credential') || msg.contains('wrong-password') || msg.contains('user-not-found')) {
          msg = "Invalid email or password. Please try again.";
        } else if (msg.contains('too-many-requests')) {
          msg = "Too many attempts. Please try again later.";
        } else if (msg.contains('network-request-failed')) {
          msg = "Network error. Check your connection.";
        } else if (msg.contains('] ')) {
          msg = msg.split('] ').last;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.green),
              const SizedBox(height: 32),
              const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white60,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text('Forgot Password?', style: TextStyle(color: Colors.green)),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.green)
                  : ElevatedButton(onPressed: _login, child: const Text('LOGIN')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                label: const Text('Sign in with Google', style: TextStyle(color: Colors.white)),
                onPressed: _isLoading ? null : _loginWithGoogle,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('Register', style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
