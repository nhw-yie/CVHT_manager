// lib/screens/advisor_screens/meeting_screens/meeting_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/meeting_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/error_handler.dart';

class MeetingAttendanceScreen extends StatefulWidget {
  final String meetingId;

  const MeetingAttendanceScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<MeetingAttendanceScreen> createState() => _MeetingAttendanceScreenState();
}

class _MeetingAttendanceScreenState extends State<MeetingAttendanceScreen> {
  final Map<int, bool> _attendanceMap = {};
  bool _isSubmitting = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    final provider = context.read<MeetingProvider>();
    final id = int.tryParse(widget.meetingId);
    if (id != null) {
      await provider.fetchStudents(id);
      
      // Initialize attendance map
      for (final student in provider.students) {
        _attendanceMap[student.studentId] = student.attended;
      }
      setState(() {});
    }
  }

  Future<void> _submitAttendance() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final attendances = _attendanceMap.entries.map((e) => {
        'student_id': e.key,
        'attended': e.value,
      }).toList();

      final api = ApiService.instance;
      final id = int.tryParse(widget.meetingId);
      if (id != null) {
        await api.post('/meetings/$id/attendance', {
          'attendances': attendances,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Điểm danh thành công')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (final key in _attendanceMap.keys) {
        _attendanceMap[key] = _selectAll;
      }
    });
  }

  int get _attendedCount => _attendanceMap.values.where((v) => v).length;
  int get _totalCount => _attendanceMap.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Điểm danh sinh viên',
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        actions: [
          IconButton(
            icon: Icon(_selectAll ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: _toggleSelectAll,
            tooltip: _selectAll ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
          ),
        ],
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return const LoadingIndicator();
          }

          if (provider.error != null) {
            return ErrorDisplay(
              message: provider.error!,
              onRetry: _loadStudents,
            );
          }

          if (provider.students.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'Chưa có sinh viên nào',
            );
          }

          return Column(
            children: [
              _buildSummaryCard(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: provider.students.length,
                  itemBuilder: (context, index) {
                    final student = provider.students[index];
                    final isAttended = _attendanceMap[student.studentId] ?? false;
                    
                    return _buildStudentCard(student, isAttended);
                  },
                ),
              ),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: AppRadius.base,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Tổng số', _totalCount.toString(), Icons.people),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('Có mặt', _attendedCount.toString(), Icons.check_circle),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('Vắng', (_totalCount - _attendedCount).toString(), Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(student, bool isAttended) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        child: CheckboxListTile(
        value: isAttended,
        onChanged: (value) {
          setState(() {
            _attendanceMap[student.studentId] = value ?? false;
          });
        },
        title: Text(
          student.student?['full_name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          student.student?['user_code'] ?? '',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        secondary: CircleAvatar(
          backgroundColor: isAttended 
            ? AppColors.success.withOpacity(0.1) 
            : Colors.grey.shade200,
          child: Icon(
            isAttended ? Icons.check : Icons.person,
            color: isAttended ? AppColors.success : Colors.grey.shade600,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          onPressed: _isSubmitting ? null : _submitAttendance,
          isLoading: _isSubmitting,
          style: CustomButtonStyle.primary,
          child: Text('Lưu điểm danh ($_attendedCount/$_totalCount)'),
        ),
      ),
    );
  }
}