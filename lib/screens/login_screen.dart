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
            // ============================
            // CHỌN VAI TRÒ
            // ============================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Sinh viên'),
                  selected: _selectedRole == 'student',
                  selectedColor: Colors.blue.shade100,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? 'student' : null;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Giảng viên'),
                  selected: _selectedRole == 'advisor',
                  selectedColor: Colors.green.shade100,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? 'advisor' : null;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ============================
            // MSSV / MSGV
            // ============================
            TextField(
              controller: _email,
              decoration: InputDecoration(
                labelText: _selectedRole == 'advisor' ? 'MSGV' : 'MSSV',
                hintText: _selectedRole == 'advisor'
                    ? 'Nhập mã giảng viên'
                    : 'Nhập mã số sinh viên',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ============================
            // MẬT KHẨU
            // ============================
            TextField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 24),

            // ============================
            // NÚT ĐĂNG NHẬP
            // ============================
            auth.isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

                        await auth.login(email, password, _selectedRole!);

                        if (!mounted) return;

                        if (auth.isAuthenticated) {
                          final serverRole = auth.currentUser?.role?.toLowerCase();
                          final role = serverRole ?? _selectedRole ?? 'student';
                          if (role.contains('advisor') || role.contains('staff')) {
                            context.go('/advisor/home');
                          } else {
                            context.go('/student/home');
                          }
                        } else if (auth.errorMessage != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(auth.errorMessage!)),
                          );
                        }
                      },
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
