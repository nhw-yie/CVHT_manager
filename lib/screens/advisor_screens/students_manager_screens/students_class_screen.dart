import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/class_provider.dart';
import '../../../providers/student_management_provider.dart';
import '../../../constants/app_colors.dart';

class StudentsClassScreen extends StatefulWidget {
  const StudentsClassScreen({Key? key}) : super(key: key);

  @override
  State<StudentsClassScreen> createState() => _StudentsClassScreenState();
}

class _StudentsClassScreenState extends State<StudentsClassScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classProv = context.read<ClassProvider>();
      if (classProv.classes.isEmpty) classProv.fetchClasses(reset: true);
    });
  }

  Future<void> _openForClass(int? classId) async {
    final studentMgmt = context.read<StudentManagementProvider>();
    final classProv = context.read<ClassProvider>();

    // Set provider filter so management screen loads correctly
    studentMgmt.setClassFilter(classId);

    if (classId != null) {
      // Preload class students for class-scoped view
      await classProv.fetchStudentsByClass(classId);
      // Optionally preload students list for management provider
      await studentMgmt.fetchStudents(classId: classId, reset: true);
    } else {
      // Load all students
      await studentMgmt.fetchStudents(reset: true);
    }

    // Navigate to management screen (new manage route)
    if (mounted) context.push('/advisor/students/manage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn lớp'), backgroundColor: AppColors.primary),
      body: Consumer<ClassProvider>(builder: (context, classProv, _) {
        if (classProv.isLoading) return const Center(child: CircularProgressIndicator());
        if (classProv.classes.isEmpty) return const Center(child: Text('Không có lớp để hiển thị'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: classProv.classes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = classProv.classes[index];
            return ListTile(
              leading: const Icon(Icons.class_),
              title: Text(c.className),
              subtitle: Text('Mã lớp: ${c.classId}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openForClass(c.classId),
            );
          },
        );
      }),
    );
  }
}
