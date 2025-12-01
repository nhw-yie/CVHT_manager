// lib/screens/advisor_screens/students_manager_screens/student_management_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../models/student.dart';
import '../../../providers/student_management_provider.dart';
import '../../../providers/class_provider.dart';
import '../../../providers/semester_provider.dart';

class StudentManagementScreenV2 extends StatefulWidget {
  const StudentManagementScreenV2({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreenV2> createState() => _StudentManagementScreenV2State();
}

class _StudentManagementScreenV2State extends State<StudentManagementScreenV2> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final studentMgmt = context.read<StudentManagementProvider>();
      final classProv = context.read<ClassProvider>();
      final semesterProv = context.read<SemesterProvider>();

      // Load initial data - respect any selected class filter already set in provider
      await Future.wait([
        studentMgmt.fetchStudents(classId: studentMgmt.selectedClassId, reset: true),
        classProv.fetchClasses(reset: true),
        semesterProv.fetchSemesters(),
        semesterProv.fetchCurrentSemester(),
      ]);
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      final prov = context.read<StudentManagementProvider>();
      if (!prov.loading && prov.hasMore && prov.selectedClassId == null) {
        prov.fetchStudents();
      }
    }
  }

  Future<void> _onRefresh() async {
    final prov = context.read<StudentManagementProvider>();
    await prov.fetchStudents(
      classId: prov.selectedClassId,
      search: prov.searchQuery,
      reset: true,
    );

    if (prov.selectedClassId != null) {
      await prov.loadClassPoints(
        prov.selectedClassId!,
        semesterId: prov.selectedSemesterId,
      );
    }
  }

  Future<void> _onClassSelected(int? classId) async {
    final prov = context.read<StudentManagementProvider>();
    prov.setClassFilter(classId);

    if (classId != null) {
      // Load students by class
      final classProv = context.read<ClassProvider>();
      await classProv.fetchStudentsByClass(classId);
      
      // Load class points
      await prov.loadClassPoints(classId, semesterId: prov.selectedSemesterId);
    } else {
      // Load all students
      await prov.fetchStudents(reset: true);
      prov.clearCache();
    }
  }

  Future<void> _onSemesterSelected(int? semesterId) async {
    final prov = context.read<StudentManagementProvider>();
    prov.setSemesterFilter(semesterId);

    // Reload points with semester filter
    if (prov.selectedClassId != null) {
      await prov.loadClassPoints(
        prov.selectedClassId!,
        semesterId: semesterId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sinh viên'),
        leading: BackButton(onPressed: () => context.go('/advisor/students')),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSemesterChips(),
          _buildSortButtons(),
          _buildStatistics(),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<StudentManagementProvider>().setSearchQuery('');
                  },
                )
              : null,
          hintText: 'Tìm theo tên hoặc MSSV',
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          context.read<StudentManagementProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildSemesterChips() {
    return Consumer<SemesterProvider>(
      builder: (context, semesterProv, _) {
        if (semesterProv.semesters.isEmpty) return const SizedBox.shrink();

        // Use a dropdown to select semester (including 'All')
        final prov = context.watch<StudentManagementProvider>();
        final items = <DropdownMenuItem<int?>>[];
        items.add(const DropdownMenuItem<int?>(value: null, child: Text('Tất cả học kỳ')));
        items.addAll(semesterProv.semesters.map((semester) => DropdownMenuItem<int?>(
              value: semester.semesterId,
              child: Text('${semester.semesterName} ${semester.academicYear}'),
            )));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DropdownButtonFormField<int?>(
            value: prov.selectedSemesterId,
            items: items,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            onChanged: (v) => _onSemesterSelected(v),
          ),
        );
      },
    );
  }

  // Class chips removed — selection happens on the class selection screen.

  Widget _buildSortButtons() {
    return Consumer<StudentManagementProvider>(
      builder: (context, prov, _) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _sortButton('GPA', SortType.gpa, Icons.school),
              const SizedBox(width: 8),
              _sortButton('Rèn luyện', SortType.trainingPoints, Icons.fitness_center),
              const SizedBox(width: 8),
              _sortButton('CTXH', SortType.socialPoints, Icons.volunteer_activism),
              const SizedBox(width: 8),
              _sortButton('Trạng thái', SortType.status, Icons.info_outline),
              const SizedBox(width: 8),
              _sortButton('Tên', SortType.name, Icons.sort_by_alpha),
            ],
          ),
        );
      },
    );
  }

  Widget _sortButton(String label, SortType type, IconData icon) {
    return Consumer<StudentManagementProvider>(
      builder: (context, prov, _) {
        final isSelected = prov.sortType == type;
        final ascending = prov.sortAscending;

        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? AppColors.primary.withOpacity(0.12) : null,
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          onPressed: () => prov.setSortType(type),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatistics() {
    return Consumer<StudentManagementProvider>(
      builder: (context, prov, _) {
        if (prov.selectedClassId == null) return const SizedBox.shrink();

        final stats = prov.getStatistics();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Tổng SV', '${stats['total']}', Icons.people),
              _statItem('TB GPA', stats['avgGpa'].toStringAsFixed(2), Icons.school),
              _statItem('TB RL', stats['avgTraining'].toStringAsFixed(0), Icons.fitness_center),
              _statItem('TB CTXH', stats['avgSocial'].toStringAsFixed(0), Icons.volunteer_activism),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    return Consumer2<ClassProvider, StudentManagementProvider>(
      builder: (context, classProv, prov, _) {
        // choose students from class provider when a class filter is active
        final bool isClassView = prov.selectedClassId != null;
        final students = isClassView ? classProv.students : prov.students;

        final loading = prov.loading && prov.students.isEmpty;
        if (loading) return const Center(child: CircularProgressIndicator());

        if (prov.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: ${prov.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _onRefresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (students.isEmpty) {
          return const Center(child: Text('Không có sinh viên'));
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: students.length + (prov.loading && !isClassView ? 1 : 0),
            itemBuilder: (context, index) {
              if (!isClassView && index >= prov.students.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final student = students[index];
              return _buildStudentCard(student, prov);
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentCard(Student student, StudentManagementProvider prov) {
    final summary = prov.academicSummaryCache[student.studentId];
    final points = prov.pointsCache[student.studentId];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('MSSV: ${student.userCode}'),
            if (summary != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip('GPA: ${summary.cpa10?.toStringAsFixed(2) ?? '-'}', Colors.blue),
                  const SizedBox(width: 8),
                  _infoChip('${summary.totalCreditsPassed} TC', Colors.green),
                ],
              ),
            ],
            if (points != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip('RL: ${points.totalTrainingPoints.toStringAsFixed(0)}', Colors.orange),
                  const SizedBox(width: 8),
                  _infoChip('CTXH: ${points.totalSocialPoints.toStringAsFixed(0)}', Colors.purple),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Show position and status
            Row(children: [
              Chip(
                label: Text(
                  _positionLabel(student.position),
                  style: TextStyle(color: _positionColor(student.position)),
                ),
                backgroundColor: _positionColor(student.position).withOpacity(0.12),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  _statusLabel(student.status),
                  style: TextStyle(color: _statusColor(student.status)),
                ),
                backgroundColor: _statusColor(student.status).withOpacity(0.12),
              ),
            ]),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () => context.push('/advisor/students/${student.studentId}'),
      ),
    );
  }

  Widget _infoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc nâng cao'),
        content: const Text('Chức năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _positionColor(String? pos) {
    final p = pos?.toLowerCase() ?? '';
    if (p == 'leader') return Colors.blue.shade700;
    if (p == 'vice_leader' || p == 'vice-leader' || p == 'viceleader') return Colors.indigo.shade700;
    return Colors.grey.shade700;
  }

  Color _statusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    switch (s) {
      case 'studying':
        return Colors.green.shade700;
      case 'reserved':
      case 'paused':
        return Colors.orange.shade700;
      case 'quit':
      case 'withdrawn':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _positionLabel(String? pos) {
    final p = pos?.toLowerCase();
    if (p == 'leader') return 'Lớp trưởng';
    if (p == 'vice_leader' || p == 'vice-leader' || p == 'viceleader') return 'Lớp phó';
    return 'Sinh viên';
  }

  String _statusLabel(String? status) {
    final s = status?.toLowerCase() ?? '';
    switch (s) {
      case 'studying':
        return 'Đang học';
      case 'reserved':
      case 'paused':
        return 'Bảo lưu';
      case 'quit':
      case 'withdrawn':
        return 'Ngừng học';
      default:
        if (s.isEmpty) return '—';
        return s[0].toUpperCase() + s.substring(1);
    }
  }
}