import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_analog_clock/flutter_analog_clock.dart';
import 'package:provider/provider.dart';
import 'widgets/animated_background.dart';
import 'widgets/digital_clock_widget.dart';
import 'providers/savings_provider.dart';

class LoginScreen extends StatefulWidget {
  final bool animationsEnabled;

  const LoginScreen({super.key, this.animationsEnabled = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _logoPulse;
  
  DateTime? _selectedBirthday;
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeIn = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _logoPulse = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _entranceController.forward();
    if (widget.animationsEnabled) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationsEnabled == widget.animationsEnabled) return;

    if (widget.animationsEnabled) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.redAccent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() => _selectedBirthday = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp && _selectedBirthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birthday.'), backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'birthday': _selectedBirthday != null ? Timestamp.fromDate(_selectedBirthday!) : null,
        });
        // Load the user profile into the provider
        if (mounted) {
          context.read<SavingsProvider>().loadUserProfileFromFirebase(userCredential.user!.uid);
        }
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Load the user profile into the provider
        if (mounted) {
          context.read<SavingsProvider>().loadUserProfileFromFirebase(userCredential.user!.uid);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'An error occurred.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/apexsaver_bg.png', fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[950])),
          ),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.65))),
          if (widget.animationsEnabled)
            const Positioned.fill(child: AnimatedBackgroundOverlay(opacity: 0.9)),

          // Logo in top-left
          Positioned(
            top: 40,
            left: 40,
            child: FadeTransition(
              opacity: _fadeIn,
              child: AnimatedBuilder(
                animation: _logoPulse,
                builder: (context, child) => Transform.scale(
                  scale: _logoPulse.value,
                  child: child,
                ),
                child: Image.asset(
                  'assets/apexsaver_logo2.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Analog Clock in top-right
          Positioned(
            top: 40,
            right: 40,
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.12, -0.12),
                  end: Offset.zero,
                ).animate(_fadeIn),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(width: 2.0, color: Colors.redAccent),
                    shape: BoxShape.circle,
                  ),
                  child: const AnalogClock(
                    isKeepTime: true,
                    dialColor: Colors.transparent,
                    markingColor: Colors.redAccent,
                    hourHandColor: Colors.white,
                    minuteHandColor: Colors.white,
                    secondHandColor: Colors.redAccent,
                  ),
                ),
              ),
            ),
          ),

          // Developed by credit
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Developed by: John Mark M. Bangud", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _cardSlide,
                child: SizedBox(
                  width: 450,
                  child: Card(
                    elevation: 8,
                    color: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const DigitalClockWidget(fontSize: 14, textColor: Colors.redAccent),
                            const SizedBox(height: 12),
                            AnimatedBuilder(
                              animation: _logoPulse,
                              builder: (context, child) => Transform.scale(
                                scale: _logoPulse.value,
                                child: child,
                              ),
                              child: Image.asset(
                                'assets/apexsaver_icon.png',
                                width: 64,
                                height: 64,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(_isSignUp ? 'Create Account' : 'Welcome Back', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            if (_isSignUp) ...[
                              TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                              const SizedBox(height: 16),
                              TextFormField(controller: _middleNameController, decoration: const InputDecoration(labelText: 'Middle Name (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline))),
                              const SizedBox(height: 16),
                              TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
                                icon: const Icon(Icons.cake, color: Colors.redAccent),
                                label: Text(_selectedBirthday == null ? 'Select Birthday' : 'Birthday: ${_selectedBirthday!.month}/${_selectedBirthday!.day}/${_selectedBirthday!.year}'),
                                onPressed: () => _selectBirthday(context),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                            const SizedBox(height: 16),
                            TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), validator: (v) => (v == null || v.length < 6) ? 'Must be 6+ chars' : null),
                            const SizedBox(height: 24),
                            _isLoading ? const CircularProgressIndicator() : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _submit, child: Text(_isSignUp ? 'Sign Up' : 'Sign In')),
                            ),
                            TextButton(onPressed: () => setState(() => _isSignUp = !_isSignUp), child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
