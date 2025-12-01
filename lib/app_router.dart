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
import 'screens/advisor_screens/activity_screens/AdvisorActivitiesListScreen.dart';
import 'screens/advisor_screens/activity_screens/AdvisorActivityDetailScreen.dart' as advisor_activity_detail;
import 'screens/advisor_screens/activity_screens/CreateEditActivityScreen.dart' as advisor_activity_form;
import 'screens/student_screens/activity_screens/activities_list_screen.dart';
import 'screens/student_screens/activity_screens/StudentActivityDetailScreen.dart';
import 'screens/my_registrations_screen.dart';
import 'screens/student_screens/points_screens/enhanced_points_screen.dart';
import 'screens/main_scaffold.dart';
// removed unused imports
import 'screens/student_screens/student_profile_screen.dart';
import 'screens/advisor_screens/advisor_home_screen.dart';
import 'screens/advisor_screens/meetting_screens/advisor_meeting_list_screen.dart';
import 'screens/advisor_screens/meetting_screens/advisor_meeting_detail_screen.dart';
import 'screens/advisor_screens/meetting_screens/create_meeting_screen.dart';
import 'screens/advisor_screens/meetting_screens/edit_meeting_screen.dart';
import 'screens/advisor_screens/meetting_screens/meeting_attendance_screen.dart';
import 'screens/student_screens/meeting_screens/student_meeting_list_screen.dart';
import 'screens/student_screens/meeting_screens/student_meeting_detail_screen.dart';
import 'screens/advisor_screens/chat_screens/advisor_conversations_screen.dart';
import 'screens/advisor_screens/chat_screens/advisor_chat_screen.dart';
import 'screens/student_screens/chat_screens/student_chat_screen.dart';
import 'screens/student_screens/chat_screens/student_conversations_screen.dart';
// advisor notification screens are imported with prefixes above
import 'screens/advisor_screens/students_manager_screens/student_management_screen_v2.dart';
import 'screens/advisor_screens/students_manager_screens/students_class_screen.dart';
import 'screens/student_screens/student_detail_screen.dart';
import 'screens/advisor_screens/students_manager_screens/student_detail_screen.dart' as advisor_student_detail;
import 'screens/create_activity_screen.dart';
import 'screens/assign_students_screen.dart';
import 'screens/advisor_screens/profile_screens/profile_screen.dart';
import 'providers/advisor_provider.dart';
import 'providers/monitoring_notes_provider.dart';
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
            GoRoute(path: '/student/activities', builder: (ctx, s) => const StudentActivitiesScreen()),
            GoRoute(
              path: '/student/activities/:id',
              builder: (ctx, s) {
                final idStr = s.pathParameters['id']!;
                final id = int.tryParse(idStr) ?? int.parse(idStr);
                return StudentActivityDetailScreen(activityId: id);
              },
            ),
            GoRoute(path: '/student/my-registrations', builder: (ctx, s) => const MyRegistrationsScreen()),
            GoRoute(path: '/student/points', builder: (ctx, s) => const EnhancedPointsScreen()),
            GoRoute(path: '/student/meetings', builder: (ctx, s) => const StudentMeetingListScreen()),
            GoRoute(path: '/student/meetings/:id', builder: (ctx, s) => StudentMeetingDetailScreen(meetingId: s.pathParameters['id']!)),
            GoRoute(
              path: '/student/chat/:advisorId',
              builder: (ctx, s) {
                final advisorId = int.tryParse(s.pathParameters['advisorId'] ?? '') ?? 0;
                final extra = s.extra;
                final advisorName = (extra is Map && extra['name'] != null) ? extra['name'] as String : '';
                return StudentChatScreen(advisorId: advisorId, advisorName: advisorName);
              },
            ),
            // student conversations list (bottom nav expects '/student/chat')
            GoRoute(path: '/student/chat', builder: (ctx, s) => const StudentConversationsScreen()),
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
    return advisor_notification_detail.NotificationDetailScreen(
      notificationId: int.parse(state.pathParameters['id']!), // Convert String to int
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
    // Pass notification object through extra
    final notification = state.extra as NotificationModel?;
    return advisor_create.CreateNotificationScreen(
      notification: notification, // Pass object, not just ID
    );
  },
),
            GoRoute(path: '/advisor/students', builder: (ctx, s) => const StudentsClassScreen()),
            GoRoute(path: '/advisor/students/manage', builder: (ctx, s) => const StudentManagementScreenV2()),
            GoRoute(
              path: '/advisor/students/:id',
              builder: (ctx, s) {
                final raw = s.pathParameters['id'];
                final id = int.tryParse(raw ?? '');
                if (id == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Sinh viên')),
                    body: const Center(child: Text('ID sinh viên không hợp lệ')),
                  );
                }
                return ChangeNotifierProvider<MonitoringNotesProvider>(
                  create: (_) {
                    final p = MonitoringNotesProvider();
                    // kick off loading the student's monitoring timeline
                    p.fetchStudentTimeline(id);
                    return p;
                  },
                  child: advisor_student_detail.StudentDetailScreen(studentId: id),
                );
              },
            ),
            GoRoute(path: '/advisor/activities', builder: (ctx, s) => const AdvisorActivitiesListScreen()),
            GoRoute(path: '/advisor/activities/manage', builder: (ctx, s) => const AdvisorActivitiesListScreen()),
            GoRoute(path: '/advisor/activities/manage/create', builder: (ctx, s) => const advisor_activity_form.CreateActivityScreen()),
            GoRoute(
              path: '/advisor/activities/manage/edit/:id',
              builder: (ctx, s) {
                final id = int.tryParse(s.pathParameters['id'] ?? '');
                return advisor_activity_form.CreateActivityScreen(activityId: id);
              },
            ),
            GoRoute(
              path: '/advisor/activities/manage/:id',
              builder: (ctx, s) {
                final id = int.parse(s.pathParameters['id']!);
                return advisor_activity_detail.AdvisorActivityDetailScreen(activityId: id);
              },
            ),
            GoRoute(path: '/advisor/activities/create', builder: (ctx, s) => const CreateActivityScreen()),
            GoRoute(path: '/advisor/activities/:id/assign', builder: (ctx, s) {
              final id = int.tryParse(s.pathParameters['id'] ?? '');
              return AssignStudentsScreen(activityId: id);
            }),
            GoRoute(path: '/advisor/conversations', builder: (ctx, s) => const AdvisorConversationsScreen()),
              // advisor messages bottom-nav target (alias)
              GoRoute(path: '/advisor/messages', builder: (ctx, s) => const AdvisorConversationsScreen()),
            GoRoute(
              path: '/advisor/chat/:studentId',
              builder: (ctx, s) {
                final studentId = int.tryParse(s.pathParameters['studentId'] ?? '') ?? 0;
                final extra = s.extra;
                String studentName = '';
                String studentCode = '';
                String className = '';
                if (extra is Map) {
                  studentName = extra['studentName']?.toString() ?? '';
                  studentCode = extra['studentCode']?.toString() ?? '';
                  className = extra['className']?.toString() ?? '';
                }
                return AdvisorChatScreen(
                  studentId: studentId,
                  studentName: studentName,
                  studentCode: studentCode,
                  className: className,
                );
              },
            ),
            GoRoute(path: '/advisor/meetings', builder: (ctx, s) => const AdvisorMeetingListScreen()),
            GoRoute(path: '/advisor/meetings/create', builder: (ctx, s) => const CreateMeetingScreen()),
            GoRoute(path: '/advisor/meetings/edit/:id', builder: (ctx, s) => EditMeetingScreen(meetingId: s.pathParameters['id']!)),
            GoRoute(path: '/advisor/meetings/:id', builder: (ctx, s) => AdvisorMeetingDetailScreen(meetingId: s.pathParameters['id']!)),
            GoRoute(path: '/advisor/meetings/:id/attendance', builder: (ctx, s) => MeetingAttendanceScreen(meetingId: s.pathParameters['id']!)),
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
