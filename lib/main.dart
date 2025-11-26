import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/notification_provider_student.dart';
import 'providers/notifications_provider.dart';
import 'providers/advisor_activities_provider.dart' as advisor_activities;
import 'providers/activities_provider.dart' as student_activities;
import 'providers/student_provider.dart';
import 'providers/class_provider.dart';
import 'providers/meeting_provider.dart';
import 'providers/activity_attendance_provider.dart';
import 'providers/dialog_provider.dart';
import 'services/api_service.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init(); // initialize ApiService (if not already)
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
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => DialogProvider()),
        ChangeNotifierProvider(create: (_) => ActivityAttendanceProvider()),
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
    return MaterialApp.router(
      title: 'CVHT Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}