import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/notification_provider_student.dart';
import 'providers/notifications_provider.dart';
import 'providers/advisor_activities_provider.dart' as advisor_activities;
import 'providers/activities_provider.dart' as student_activities;
import 'providers/student_provider.dart';
import 'providers/class_provider.dart';
import 'providers/student_management_provider.dart';
import 'providers/semester_provider.dart';
import 'providers/meeting_provider.dart';
import 'providers/activity_attendance_provider.dart';
import 'providers/dialog_provider.dart';
import 'providers/points_provider.dart';
import 'providers/academic_monitoring_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/enhanced_points_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init(); // initialize ApiService (if not already)
  // Initialize local notification service
  try {
    await NotificationService.instance.init();
  } catch (_) {}
  runApp(const AppEntry());
}

class AppEntry extends StatelessWidget {
  const AppEntry({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => AdvisorNotificationsProvider()),
        ChangeNotifierProvider<student_activities.ActivitiesProvider>(create: (_) => student_activities.ActivitiesProvider()),
        ChangeNotifierProvider<advisor_activities.ActivitiesProvider>(create: (_) => advisor_activities.ActivitiesProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => StudentManagementProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => SemesterProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => AcademicMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => DialogProvider()),
        ChangeNotifierProvider(create: (_) => ActivityAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => PointsProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedPointsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter(context);
    final themeMode = Provider.of<ThemeProvider>(context).mode;
    return MaterialApp.router(
      title: 'CVHT Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}