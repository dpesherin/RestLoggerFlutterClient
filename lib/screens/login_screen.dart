import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/toast_widget.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      Map<String, dynamic>? result;

      if (_isLoginMode) {
        result = await ApiService.auth(
          _loginController.text,
          _passwordController.text,
        );
      } else {
        result = await ApiService.register(
          _loginController.text,
          _passwordController.text,
        );
      }

      if (!mounted) return;

      if (result != null) {
        ToastWidget.show(
          context,
          message: _isLoginMode ? 'Вход выполнен' : 'Регистрация успешна',
          type: ToastType.success,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ToastWidget.show(
          context,
          message:
              _isLoginMode ? 'Неверный логин или пароль' : 'Ошибка регистрации',
          type: ToastType.error,
        );
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1E24) : const Color(0xFFE0E5EC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C313A)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(10, 10),
                ),
                BoxShadow(
                  color: isDark ? const Color(0xFF3A404B) : Colors.white,
                  blurRadius: 20,
                  offset: const Offset(-10, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '{..Logger..}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A8FEC),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1E24)
                        : const Color(0xFFE0E5EC),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black54
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(3, 3),
                      ),
                      BoxShadow(
                        color: isDark ? const Color(0xFF3A404B) : Colors.white,
                        blurRadius: 5,
                        offset: const Offset(-3, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isLoginMode
                                  ? const Color(0xFF5A8FEC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'Вход',
                                style: TextStyle(
                                  color: _isLoginMode
                                      ? Colors.white
                                      : const Color(0xFF5A8FEC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isLoginMode
                                  ? const Color(0xFF5A8FEC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'Регистрация',
                                style: TextStyle(
                                  color: !_isLoginMode
                                      ? Colors.white
                                      : const Color(0xFF5A8FEC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black54
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(3, 3),
                      ),
                      BoxShadow(
                        color: isDark ? const Color(0xFF3A404B) : Colors.white,
                        blurRadius: 5,
                        offset: const Offset(-3, -3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _loginController,
                    enabled: !_isLoading,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2D4059),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Логин',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF4A5C6E).withOpacity(0.7),
                      ),
                      prefixIcon:
                          const Icon(Icons.person, color: Color(0xFF5A8FEC)),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1E24)
                          : const Color(0xFFE0E5EC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black54
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(3, 3),
                      ),
                      BoxShadow(
                        color: isDark ? const Color(0xFF3A404B) : Colors.white,
                        blurRadius: 5,
                        offset: const Offset(-3, -3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2D4059),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Пароль',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF4A5C6E).withOpacity(0.7),
                      ),
                      prefixIcon:
                          const Icon(Icons.lock, color: Color(0xFF5A8FEC)),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1E24)
                          : const Color(0xFFE0E5EC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A8FEC).withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A8FEC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLoginMode ? 'Войти' : 'Зарегистрироваться',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
