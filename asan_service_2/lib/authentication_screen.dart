import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'api_service.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _showLoginPage = true;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _selectedRole = 'customer';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _showLoginPage = !_showLoginPage;
      _errorMessage = null;
    });
  }

  Future<String> _performLogin(String phoneNumber, String password) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/auth/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      return responseBody['access'];
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['detail'] ?? 'ورود ناموفق بود');
    }
  }

  Future<void> _performRegister(
    String phoneNumber,
    String password,
    String firstName,
    String lastName,
    String role,
  ) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/auth/register/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody.toString());
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _performLogin(
        _phoneController.text,
        _passwordController.text,
      );
      
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.login(token);
      
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _performRegister(
        _phoneController.text,
        _passwordController.text,
        _firstNameController.text,
        _lastNameController.text,
        _selectedRole,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ثبت‌نام موفقیت‌آمیز بود. لطفاً وارد شوید.')),
      );
      _toggleAuthMode();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _showLoginPage 
              ? _buildLoginForm()
              : _buildRegisterForm(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text('ورود به حساب کاربری', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'شماره موبایل'),
              keyboardType: TextInputType.phone,
              validator: (value) => value!.isEmpty ? 'لطفاً شماره موبایل را وارد کنید' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'رمز عبور'),
              obscureText: true,
              validator: (value) => value!.length < 6 ? 'رمز عبور باید حداقل ۶ کاراکتر باشد' : null,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ورود'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _isLoading ? null : _toggleAuthMode,
              child: const Text('حساب کاربری ندارید؟ ثبت‌نام کنید', 
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text('ثبت‌نام کاربر جدید', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'شماره موبایل'),
              keyboardType: TextInputType.phone,
              validator: (value) => value!.isEmpty ? 'لطفاً شماره موبایل را وارد کنید' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'رمز عبور'),
              obscureText: true,
              validator: (value) => value!.length < 6 ? 'رمز عبور باید حداقل ۶ کاراکتر باشد' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'نام'),
              validator: (value) => value!.isEmpty ? 'لطفاً نام را وارد کنید' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'نام خانوادگی'),
              validator: (value) => value!.isEmpty ? 'لطفاً نام خانوادگی را وارد کنید' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'نقش'),
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('مشتری')),
                DropdownMenuItem(value: 'technician', child: Text('تکنسین')),
              ],
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ثبت‌نام'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _isLoading ? null : _toggleAuthMode,
              child: const Text('حساب کاربری دارید؟ وارد شوید', 
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}