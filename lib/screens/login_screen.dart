import 'package:flutter/material.dart';
import '../components/login_screen/login_auth_card.dart';
import '../repositories/auth_repository.dart';
import '../utils/theme.dart';
import '../widgets/toast_widget.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = const AuthRepository();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      ToastWidget.show(
        context,
        message: 'Заполните все поля',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await _authRepository.login(
          _loginController.text,
          _passwordController.text,
        );
      } else {
        await _authRepository.register(
          _loginController.text,
          _passwordController.text,
        );
      }

      if (!mounted) return;

      ToastWidget.show(
        context,
        message: _isLoginMode ? 'Вход выполнен' : 'Регистрация успешна',
        type: ToastType.success,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Ошибка: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LoginAuthCard(
            isLoginMode: _isLoginMode,
            isLoading: _isLoading,
            loginController: _loginController,
            passwordController: _passwordController,
            onModeChanged: (value) => setState(() => _isLoginMode = value),
            onSubmit: _handleAuth,
          ),
        ),
      ),
    );
  }
}
