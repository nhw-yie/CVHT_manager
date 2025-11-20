import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/notification_provider_student.dart';
import 'student_screens/home_screens/student_home_screen.dart';
import 'student_screens/notification_screens/notifications_list_screen.dart';
import 'student_screens/activity_screens/activities_list_screen.dart';
import 'chat_screen.dart';
import 'student_screens/student_profile_screen.dart';
import 'advisor_screens/advisor_home_screen.dart';
import 'advisor_screens/students_manager_screens/student_management_screen.dart';
import '../constants/app_colors.dart';

/// MainScaffold provides a BottomNavigationBar with IndexedStack to preserve
/// state for each tab (keeps scroll position and UI state per tab).
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({Key? key, required this.child}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationsProvider>();

    // Determine role; default to 'student' if unknown
    final role = auth.currentUser?.role?.toLowerCase() ?? 'student';
    final isAdvisor = role.contains('advisor') || role.contains('admin') || role.contains('staff');

    // badge counts
    final notifCount = notifications.unreadCount;
    final messagesCount = 0;

    // Define routes for bottom navigation for student and advisor
    final studentRoutes = ['/student/home', '/student/notifications', '/student/activities', '/student/chat', '/student/profile'];
    final advisorRoutes = ['/advisor/home', '/advisor/notifications', '/advisor/students', '/advisor/messages', '/advisor/profile'];

    final routes = isAdvisor ? advisorRoutes : studentRoutes;

    final items = isAdvisor
        ? <BottomNavigationBarItem>[
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: _buildBadge(Icons.notifications, notifCount), label: 'Thông báo'),
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sinh viên'),
            BottomNavigationBarItem(icon: _buildBadge(Icons.chat, messagesCount), label: 'Tin nhắn'),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
          ]
        : <BottomNavigationBarItem>[
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: _buildBadge(Icons.notifications, notifCount), label: 'Thông báo'),
            const BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: 'Hoạt động'),
            BottomNavigationBarItem(icon: _buildBadge(Icons.chat, messagesCount), label: 'Chat'),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
          ];

    // Determine current index from current location
    final location = GoRouter.of(context).location;
    debugPrint('MainScaffold build: location=$location, childType=${widget.child.runtimeType}');
    int currentIndex = 0;
    for (var i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: PageStorage(bucket: _bucket, child: widget.child),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          final target = routes[i];
          if (GoRouter.of(context).location != target) {
            GoRouter.of(context).go(target);
          }
        },
        items: items,
      ),
    );
  }
}

Widget _buildBadge(IconData icon, int count) {
  if (count <= 0) return Icon(icon);
  final label = count > 99 ? '99+' : count.toString();
  return Stack(children: [Icon(icon), Positioned(right: -6, top: -6, child: CircleAvatar(radius: 9, backgroundColor: Colors.red, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white))))]);
}
