import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWith(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_isRegister) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? e.code)),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      await _signInWith(email, password);
    }
  }

  Future<void> _demoSignIn(String email) async {
    _emailController.text = email;
    _passwordController.text = 'Demo@123';
    await _signInWith(email, 'Demo@123');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_isRegister ? 'Create account' : 'Sign in'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter email';
                          if (!value.contains('@')) return 'Enter valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter password';
                          if (value.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Demo accounts:\n'
                        'demo1@ — Farmer (both): ponds + Market\n'
                        'demo2@ — Supervisor: ponds only\n'
                        'demo3@ — Trader: Market only\n'
                        'demo4@ — Farmer (notifications): Market only\n'
                        'Password: Demo@123',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isRegister ? 'Create account' : 'Sign in'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _demoSignIn('demo1@prawnfarm.com'),
                        child: const Text('Demo Farmer — both (A1–A4 + Market)'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _demoSignIn('demo2@prawnfarm.com'),
                        child: const Text('Demo Supervisor (Pond B1–B4)'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _demoSignIn('demo3@prawnfarm.com'),
                        child: const Text('Demo Trader (Market)'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _demoSignIn('demo4@prawnfarm.com'),
                        child: const Text('Demo Farmer — notifications only'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isRegister = !_isRegister),
                        child: Text(
                          _isRegister
                              ? 'Already have an account? Sign in'
                              : 'New user? Create account',
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

