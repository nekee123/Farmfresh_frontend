import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? password;

  const OtpVerificationScreen({
    super.key, 
    required this.phoneNumber,
    this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isVerified = false;
  
  // Timer related
  int _secondsRemaining = 300; // 5 minutes
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 300;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canResend = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  String _getTimerText() {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔐 Verifying OTP for ${widget.phoneNumber}...');
      final response = await ApiService.verifyOtp({
        'phone_number': widget.phoneNumber,
        'otp': _otpController.text.trim(),
      });

      if (response.success) {
        print('✅ OTP Verified successfully!');
        if (mounted) {
          setState(() {
            _isVerified = true;
          });
        }
      } else {
        print('❌ Verification failed: ${response.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Verification failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('🚨 Exception during verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.resendOtp({
        'phone_number': widget.phoneNumber,
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP has been resent!'),
            backgroundColor: Colors.green,
          ),
        );
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If they click back without verifying, ensure they are logged out
        Provider.of<AuthService>(context, listen: false).logout();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify Account'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: Container(
          padding: const EdgeInsets.all(24.0),
          child: _isVerified ? _buildSuccessView() : _buildVerificationForm(),
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 24),
            const Text(
              'Verification Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Please enter the code sent to\n${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length < 4) return 'Invalid code';
                return null;
              },
              onFieldSubmitted: (_) => _verifyOtp(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify Account', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _canResend ? "Didn't receive the code? " : "Resend code in ",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                _canResend
                    ? TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: const Text('Resend', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      )
                    : Text(
                        _getTimerText(),
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (widget.password != null && widget.password!.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final success = await authService.login(widget.phoneNumber, widget.password!);
        
        if (mounted) {
          if (success) {
            final role = authService.getUserRole()?.toLowerCase();
            if (role == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin_dashboard');
            } else if (role == 'seller' || role == 'farmer') {
              Navigator.pushReplacementNamed(context, '/farmer_dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/consumer_dashboard');
            }
          } else {
            // If auto-login fails, fallback to manual login
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // No password available, go to login screen
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildSuccessView() {
    final bool hasAutoLogin = widget.password != null && widget.password!.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Verified!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          hasAutoLogin 
              ? 'Your account is verified successfully! Click continue to start.' 
              : 'Your account is verified successfully, you can now login your account',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    hasAutoLogin ? 'Continue' : 'Go to Login', 
                    style: const TextStyle(color: Colors.white, fontSize: 16)
                  ),
          ),
        ),
      ],
    );
  }
}
