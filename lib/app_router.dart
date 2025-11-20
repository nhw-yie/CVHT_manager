import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/student_screens/home_screens/student_home_screen.dart';
import 'screens/student_screens/notification_screens/notifications_list_screen.dart';
import 'screens/student_screens/notification_screens/notification_detail_screen.dart';
import 'screens/advisor_screens/notification_screens/notifications_list_screen.dart' as advisor_notifications;
import 'screens/advisor_screens/notification_screens/notification_detail_screen.dart' as advisor_notification_detail;
import 'screens/advisor_screens/notification_screens/create_notification_screen.dart' as advisor_create;
import 'screens/advisor_screens/activity_screens/activities_management_screen.dart' as advisor_activities_manage;
import 'screens/advisor_screens/activity_screens/activity_detail_screen.dart' as advisor_activity_detail;
import 'screens/advisor_screens/activity_screens/activity_form_screen.dart' as advisor_activity_form;
import 'screens/student_screens/activity_screens/activities_list_screen.dart';
import 'screens/activity_detail_screen.dart';
import 'screens/my_registrations_screen.dart';
import 'screens/points_management_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/chat_screen.dart';
import 'screens/student_screens/student_profile_screen.dart';
import 'screens/advisor_screens/advisor_home_screen.dart';
// advisor notification screens are imported with prefixes above
import 'screens/advisor_screens/students_manager_screens/student_management_screen.dart';
import 'screens/student_screens/student_detail_screen.dart';
import 'screens/create_activity_screen.dart';
import 'screens/assign_students_screen.dart';
import 'screens/advisor_screens/profile_screens/profile_screen.dart';
import 'providers/advisor_provider.dart';
import 'models/notification_model.dart';

/// AppRouter builds a GoRouter instance wired to AuthProvider for redirects.
class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Use the AuthProvider (ChangeNotifier) as the refreshListenable so
    // the router reacts when auth.notifyListeners() is called.
    return GoRouter(
      debugLogDiagnostics: false,
      refreshListenable: auth,
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', redirect: (ctx, state) {
          if (!auth.isAuthenticated) return '/login';
          final role = auth.currentUser?.role?.toLowerCase() ?? 'student';
          if (role.contains('advisor') || role.contains('staff')) return '/advisor/home';
          return '/student/home';
        }),

        GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),

        /// Student routes
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(path: '/student/home', builder: (ctx, s) => const StudentHomeScreen()),
            GoRoute(path: '/student/notifications', builder: (ctx, s) => const NotificationsListScreen()),
            GoRoute(path: '/student/notifications/:id', builder: (ctx, s) => NotificationDetailScreen(notificationId: s.pathParameters['id']!)),
            GoRoute(path: '/student/activities', builder: (ctx, s) => const ActivitiesListScreen()),
            GoRoute(path: '/student/activities/:id', builder: (ctx, s) => ActivityDetailScreen(activityId: s.pathParameters['id']!)),
            GoRoute(path: '/student/my-registrations', builder: (ctx, s) => const MyRegistrationsScreen()),
            GoRoute(path: '/student/points', builder: (ctx, s) => const PointsManagementScreen()),
            GoRoute(path: '/student/meetings', builder: (ctx, s) => const SizedBox()),
            GoRoute(path: '/student/chat/:advisorId', builder: (ctx, s) => ChatScreen(conversationId: s.pathParameters['advisorId']!, advisorName: '')),
            GoRoute(path: '/student/profile', builder: (ctx, s) => const StudentProfileScreen()),
          ],
        ),

        /// Advisor routes (separate shell to reuse scaffold)
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(path: '/advisor/home', builder: (ctx, s) => const AdvisorHomeScreen()),
            GoRoute(path: '/advisor/notifications', builder: (ctx, s) => const advisor_notifications.AdvisorNotificationsListScreen()),
            GoRoute(path: '/advisor/notifications/create', builder: (ctx, s) => const advisor_create.CreateNotificationScreen()),
GoRoute(
  path: '/advisor/notifications/:id',
  builder: (ctx, state) {
    final id = state.pathParameters['id'];
    return advisor_notification_detail.NotificationDetailScreen(
      notificationId: int.parse(id!), // Convert String to int
    );
  },
),

GoRoute(
  path: '/advisor/profile',
  builder: (ctx, state) {
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    final id = auth.currentUser?.id;
    return ChangeNotifierProvider<AdvisorProvider>(
      create: (_) {
        final p = AdvisorProvider();
        if (id != null) p.fetchAdvisorDetail(id);
        return p;
      },
      child: const AdvisorProfileScreen(),
    );
  },
),
           GoRoute(
  path: '/advisor/notifications/edit/:id',
  builder: (ctx, state) {
    final id = state.pathParameters['id'];
    // Pass notification object through extra
    final notification = state.extra as NotificationModel?;
    
    return advisor_create.CreateNotificationScreen(
      notification: notification, // Pass object, not just ID
    );
  },
),
            GoRoute(path: '/advisor/students', builder: (ctx, s) => const StudentManagementScreen()),
            GoRoute(path: '/advisor/students/:id', builder: (ctx, s) => StudentDetailScreen(studentId: s.pathParameters['id']!)),
            GoRoute(path: '/advisor/activities', builder: (ctx, s) => const ActivitiesListScreen()),
            GoRoute(path: '/advisor/activities/manage', builder: (ctx, s) => const advisor_activities_manage.ActivitiesManagementScreen()),
            GoRoute(path: '/advisor/activities/manage/create', builder: (ctx, s) => const advisor_activity_form.AdvisorActivityFormScreen()),
            GoRoute(path: '/advisor/activities/manage/edit/:id', builder: (ctx, s) => advisor_activity_form.AdvisorActivityFormScreen(activityId: int.tryParse(s.pathParameters['id'] ?? '') ),
            ),
            GoRoute(path: '/advisor/activities/manage/:id', builder: (ctx, s) => advisor_activity_detail.AdvisorActivityDetailScreen(activityId: s.pathParameters['id']!)),
            GoRoute(path: '/advisor/activities/create', builder: (ctx, s) => const CreateActivityScreen()),
            GoRoute(path: '/advisor/activities/:id/assign', builder: (ctx, s) {
              final id = int.tryParse(s.pathParameters['id'] ?? '');
              return AssignStudentsScreen(activityId: id);
            }),
            GoRoute(path: '/advisor/messages', builder: (ctx, s) => const ChatScreen(conversationId: '', advisorName: '')),
          ],
        ),
      ],
      redirect: (context, state) {
        // global guard: if trying to access protected routes and not authed -> /login
        final loggingIn = state.location == '/login';
        if (!auth.isAuthenticated && !loggingIn) return '/login';
        return null;
      },
      // Provide a smooth animation for page transitions
      // Use default transition; callers can override per-route using CustomTransitionPage if needed.
    );
  }

  // Note: We rely on AuthProvider (ChangeNotifier) directly as the router's
  // refreshListenable, so we do not need an intermediate stream helper.
}
