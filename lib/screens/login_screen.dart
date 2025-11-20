import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _selectedRole; // 'student' hoặc 'advisor'

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (auth.isAuthenticated) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final serverRole = auth.currentUser?.role?.toLowerCase();
        final role = serverRole ?? _selectedRole ?? 'student';
        if (role.contains('advisor') || role.contains('staff')) {
          context.go('/advisor/home');
        } else {
          context.go('/student/home');
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Chọn vai trò
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Sinh viên'),
                  selected: _selectedRole == 'student',
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? 'student' : null;
                    });
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Giảng viên'),
                  selected: _selectedRole == 'advisor',
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? 'advisor' : null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'MSSV'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            auth.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final email = _email.text.trim();
                      final password = _password.text;

                      if (_selectedRole == null) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn vai trò')),
                        );
                        return;
                      }

                      if (email.isEmpty || password.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
                        );
                        return;
                      }

                      // Login bình thường, không truyền role
                      await auth.login(email, password, _selectedRole!);

                      if (auth.isAuthenticated) {
                        // Prefer server role; if not available, fall back to selected role
                        final serverRole = auth.currentUser?.role?.toLowerCase();
                        final role = serverRole ?? _selectedRole ?? 'student';
                        if (role.contains('advisor') || role.contains('staff')) {
                          context.go('/advisor/home');
                        } else {
                          context.go('/student/home');
                        }
                      } else if (auth.errorMessage != null) {
                        messenger.showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
                      }
                    },
                    child: const Text('Đăng nhập'),
                  ),
          ],
        ),
      ),
    );
  }
}
