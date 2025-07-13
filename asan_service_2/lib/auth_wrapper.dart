import 'package:asan_service_app/auth_service.dart';
import 'package:asan_service_app/authentication_screen.dart';
import 'package:asan_service_app/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return FutureBuilder(
      future: authService.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        switch (authService.authState) {
          case AuthState.authenticated:
            return const HomePage();
          case AuthState.unauthenticated:
            return const AuthenticationScreen();
          case AuthState.unknown:
          default:
            return const Scaffold(
              body: Center(child: Text('خطا در بررسی وضعیت احراز هویت')),
            );
        }
      },
    );
  }
}