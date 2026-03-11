import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

class App extends StatelessWidget {
  final bool isAuthenticated;

  const App({
    super.key,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return isAuthenticated ? const MainScreen() : const LoginScreen();
  }
}
