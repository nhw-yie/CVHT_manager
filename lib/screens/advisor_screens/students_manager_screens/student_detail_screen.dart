import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../../services/api_service.dart';
import '../../../utils/error_handler.dart';
import '../../../models/student.dart';
import '../../../models/semester.dart';
import '../../../models/semester_report.dart';
import '../../../providers/monitoring_notes_provider.dart';
import './widgets/gpa_trend_chart.dart';

/// Student Detail Screen for Advisors
class StudentDetailScreen extends StatefulWidget {
  final int studentId;

  const StudentDetailScreen({Key? key, required this.studentId})
    : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService.instance;

  bool _isLoading = true;
  String? _errorMessage;

  // Data from API response
  Student? _student;
  Map<String, dynamic>? _classInfo;
  Map<String, dynamic>? _advisorInfo;
  Map<String, dynamic>? _facultyInfo;
  List<SemesterReport> _semesterReports = [];
  List<Map<String, dynamic>> _academicWarnings = [];
  List<Map<String, dynamic>> _courseGrades = [];

  @override
  void initState() {
    super.initState();
    debugPrint('StudentDetailScreen.initState studentId=${widget.studentId}');
    _tabController = TabController(length: 5, vsync: this);
    // Call load immediately to ensure the API request is fired. Notes fetching
    // still uses context so keep it in a post-frame callback.
    developer.log('StudentDetail: invoking _loadStudentDetail from initState', name: 'StudentDetail');
    _loadStudentDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final notes = Provider.of<MonitoringNotesProvider>(
          context,
          listen: false,
        );
        notes.fetchNotes(studentId: widget.studentId);
      } catch (e, s) {
        developer.log('Failed to fetch monitoring notes',
            error: e, stackTrace: s, name: 'StudentDetail');
      }
    });
  }

  Future<void> _loadStudentDetail() async {
 
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
 
    try {
      
      final resp = await _api.getStudentById(widget.studentId);
      print(widget.studentId);
      final data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) {
        // Parse student info
        _student = Student.fromJson(data);
        developer.log('StudentDetail: parsed student', name: 'StudentDetail');
        developer.log(_student.toString(), name: 'StudentDetail');

        // Parse class info
        _classInfo = data['class'] as Map<String, dynamic>?;
        _advisorInfo = _classInfo?['advisor'] as Map<String, dynamic>?;
        _facultyInfo = _classInfo?['faculty'] as Map<String, dynamic>?;

        // Parse semester reports
        final reportsData = data['semester_reports'] as List?;
        if (reportsData != null) {
          _semesterReports =
              reportsData
                  .map(
                    (r) => SemesterReport.fromJson(r as Map<String, dynamic>),
                  )
                  .toList();
        }

        // Parse academic warnings
        final warningsData = data['academic_warnings'] as List?;
        if (warningsData != null) {
          _academicWarnings =
              warningsData.map((w) => w as Map<String, dynamic>).toList();
        }

        // Parse course grades
        final gradesData = data['course_grades'] as List?;
        if (gradesData != null) {
          _courseGrades =
              gradesData.map((g) => g as Map<String, dynamic>).toList();
        }
      }
    } catch (e, s) {
      developer.log('StudentDetail: error loading detail',
          error: e, stackTrace: s, name: 'StudentDetail');
      _errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesProv = Provider.of<MonitoringNotesProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sinh viên')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sinh viên')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!),
              TextButton(
                onPressed: _loadStudentDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder:
              (context, inner) => [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 220,
                  title: Text(_student?.fullName ?? 'Sinh viên'),
                  actions: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed:
                          _student == null
                              ? null
                              : () {
                                final sid = _student!.studentId;
                                context.push(
                                  '/advisor/chat/$sid',
                                  extra: {
                                    'studentName': _student!.fullName,
                                    'studentCode': _student!.userCode,
                                    'className':
                                        _classInfo?['class_name'] ?? '',
                                  },
                                );
                              },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (_) {},
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'email',
                              child: Text('Gửi email'),
                            ),
                            PopupMenuItem(
                              value: 'call',
                              child: Text('Gọi điện thoại'),
                            ),
                          ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background:
                        _student?.avatarUrl != null
                            ? Image.network(
                              ApiService.baseUrl.replaceAll('/api', '') +
                                  (_student!.avatarUrl!),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      Container(color: Colors.grey.shade300),
                            )
                            : Container(color: Colors.grey.shade300),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _StudentInfoCard(
                      student: _student,
                      classInfo: _classInfo,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Tổng quan'),
                        Tab(text: 'Học vụ'),
                        Tab(text: 'Chuyên cần'),
                        Tab(text: 'Điểm'),
                        Tab(text: 'Ghi chú'),
                      ],
                    ),
                  ),
                ),
              ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Tổng quan
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverviewSection(
                      student: _student,
                      latestReport:
                          _semesterReports.isNotEmpty
                              ? _semesterReports.last
                              : null,
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Học tập - HK hiện tại',
                      child: _CurrentSemesterDetail(
                        latestReport:
                            _semesterReports.isNotEmpty
                                ? _semesterReports.last
                                : null,
                        allReports: _semesterReports,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Hoạt động đã tham gia',
                      child: _RecentActivityList(studentId: widget.studentId),
                    ),
                  ],
                ),
              ),

              // Tab 2: Học vụ
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SectionCard(
                      title: 'Báo cáo học kỳ',
                      child: _SemesterReportsList(reports: _semesterReports),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Xu hướng GPA',
                      child: GPATrendChart(
                        data: _semesterReports.map((r) => r.gpa ?? 0).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Cảnh báo học vụ',
                      child: _AcademicWarningsList(warnings: _academicWarnings),
                    ),
                  ],
                ),
              ),

              // Tab 3: Chuyên cần
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SectionCard(
                      title: 'Thống kê chuyên cần',
                      child: _AttendanceStatsCard(
                        semesterReports: _semesterReports,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab 4: Điểm
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SectionCard(
                      title: 'Điểm các môn học',
                      child: _CourseGradesList(grades: _courseGrades),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Điểm rèn luyện',
                      child: _PointsSummary(semesterReports: _semesterReports),
                    ),
                  ],
                ),
              ),

              // Tab 5: Ghi chú
              Padding(
                padding: const EdgeInsets.all(16),
                child:
                    notesProv.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : notesProv.notes.isEmpty
                        ? const Center(child: Text('Chưa có ghi chú'))
                        : ListView.builder(
                          itemCount: notesProv.notes.length,
                          itemBuilder: (context, index) {
                            final note = notesProv.notes[index];
                            return Card(
                              child: ExpansionTile(
                                title: Text(note['title'] ?? ''),
                                subtitle: Text(_formatDate(note['created_at'])),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(note['content'] ?? ''),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFabForTab(_tabController.index),
      ),
    );
  }

  Widget? _buildFabForTab(int index) {
    switch (index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () {},
          label: const Text('Tạo cảnh báo'),
          icon: const Icon(Icons.add_alert),
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () {},
          label: const Text('Thêm ghi chú mới'),
          icon: const Icon(Icons.note_add),
        );
      default:
        return null;
    }
  }
}

// ---------- Helper Widgets ----------

String _formatDate(dynamic d) {
  if (d == null) return '';
  if (d is DateTime) return '${d.day}/${d.month}/${d.year}';
  try {
    final dt = DateTime.parse(d.toString());
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return d.toString();
  }
}

class _StudentInfoCard extends StatelessWidget {
  final Student? student;
  final Map<String, dynamic>? classInfo;
  final bool isLoading;

  const _StudentInfoCard({
    Key? key,
    required this.student,
    required this.classInfo,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final className = classInfo?['class_name'] ?? '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage:
                  student?.avatarUrl != null
                      ? NetworkImage(
                        ApiService.baseUrl.replaceAll('/api', '') +
                            student!.avatarUrl!,
                      )
                      : null,
              child:
                  student?.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student?.fullName ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('MSSV: ${student?.userCode ?? '-'}'),
                  const SizedBox(height: 6),
                  Text('$className • ${student?.email ?? '-'}'),
                  Text('SĐT: ${student?.phoneNumber ?? '-'}'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                _statusLabel(student?.status),
                style: TextStyle(color: _statusColor(context, student?.status)),
              ),
              backgroundColor: _statusColor(context, student?.status).withOpacity(0.14),
            ),
          ],
        ),
      ),
    );
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
        return s.isEmpty ? '—' : s[0].toUpperCase() + s.substring(1);
    }
  }

  Color _statusColor(BuildContext context, String? status) {
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
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.8);
    }
  }
}

class _OverviewSection extends StatelessWidget {
  final Student? student;
  final SemesterReport? latestReport;

  const _OverviewSection({Key? key, this.student, this.latestReport})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sử dụng CPA từ báo cáo học kỳ gần nhất (đây là điểm tích lũy)
    final cpa10 = latestReport?.cpa10Scale ?? 0.0;
    final cpa4 = latestReport?.cpa4Scale ?? 0.0;
    final totalCredits = latestReport?.creditsPassed ?? 0;

    // Xác định xếp loại
    String classification = _getClassification(cpa10);
    Color classColor = _getClassificationColor(cpa10);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin liên hệ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _InfoItem('Email', student?.email ?? '-'),
            const SizedBox(height: 8),
            _InfoItem('Số điện thoại', student?.phoneNumber ?? '-'),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPA: ${cpa10.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tín chỉ: $totalCredits/${latestReport?.creditsRegistered ?? 0}',
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: classColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: classColor),
                  ),
                  child: Text(
                    'Xếp loại: $classification',
                    style: TextStyle(
                      color: classColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: cpa10 / 10.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(classColor),
            ),
          ],
        ),
      ),
    );
  }

  String _getClassification(double gpa) {
    if (gpa >= 9.0) return 'Xuất sắc';
    if (gpa >= 8.0) return 'Giỏi';
    if (gpa >= 7.0) return 'Khá';
    if (gpa >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  Color _getClassificationColor(double gpa) {
    if (gpa >= 9.0) return Colors.purple;
    if (gpa >= 8.0) return Colors.green;
    if (gpa >= 7.0) return Colors.blue;
    if (gpa >= 5.0) return Colors.orange;
    return Colors.red;
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ClassInfoSection extends StatelessWidget {
  final Map<String, dynamic>? classInfo;
  final Map<String, dynamic>? advisorInfo;
  final Map<String, dynamic>? facultyInfo;

  const _ClassInfoSection({
    Key? key,
    this.classInfo,
    this.advisorInfo,
    this.facultyInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow('Lớp:', classInfo?['class_name'] ?? '-'),
        _InfoRow('Mô tả:', classInfo?['description'] ?? '-'),
        const Divider(),
        _InfoRow('GVCN:', advisorInfo?['full_name'] ?? '-'),
        _InfoRow('Email GVCN:', advisorInfo?['email'] ?? '-'),
        _InfoRow('SĐT GVCN:', advisorInfo?['phone_number'] ?? '-'),
        const Divider(),
        _InfoRow('Khoa:', facultyInfo?['unit_name'] ?? '-'),
        _InfoRow('Mô tả khoa:', facultyInfo?['description'] ?? '-'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({Key? key, required this.title, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SemesterReportsList extends StatelessWidget {
  final List<SemesterReport> reports;

  const _SemesterReportsList({Key? key, required this.reports})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Text('Chưa có báo cáo học kỳ');
    }

    return Column(
      children:
          reports.map((report) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Học kỳ ${report.semesterId}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPA: ${report.gpa?.toStringAsFixed(2) ?? '-'}',
                              ),
                              Text(
                                'CPA (10): ${report.cpa10Scale?.toStringAsFixed(2) ?? '-'}',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TC đăng ký: ${report.creditsRegistered}'),
                              Text('TC đạt: ${report.creditsPassed}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Điểm RL: ${report.trainingPointSummary}',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Điểm CTXH: ${report.socialPointSummary}',
                          ),
                        ),
                      ],
                    ),
                    if (report.outcome != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Kết quả: ${report.outcome}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _CurrentSemesterDetail extends StatelessWidget {
  final SemesterReport? latestReport;
  final List<SemesterReport> allReports;

  const _CurrentSemesterDetail({
    Key? key,
    this.latestReport,
    this.allReports = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (latestReport == null)
      return const Text('Không có dữ liệu học kỳ hiện tại');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GPA học kỳ: ${latestReport!.gpa?.toStringAsFixed(2) ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'CPA tích lũy (10): ${latestReport!.cpa10Scale?.toStringAsFixed(2) ?? '-'}',
        ),
        Text(
          'Tín chỉ đăng ký: ${latestReport!.creditsRegistered} • Tín chỉ đạt: ${latestReport!.creditsPassed}',
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Xem chi tiết học kỳ'),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final int studentId;

  const _RecentActivityList({Key? key, required this.studentId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder: replace with real provider integration when available
    final items = List.generate(
      5,
      (i) => {
        'title': 'Hoạt động ${i + 1}',
        'date': DateTime.now().subtract(Duration(days: i * 7)),
      },
    );

    return Column(
      children:
          items
              .map(
                (it) => ListTile(
                  title: Text(it['title']?.toString() ?? ''),
                  subtitle: Text(_formatDate(it['date'])),
                ),
              )
              .toList(),
    );
  }
}

class _AcademicWarningsList extends StatelessWidget {
  final List<Map<String, dynamic>> warnings;

  const _AcademicWarningsList({Key? key, required this.warnings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return const Text('Không có cảnh báo học vụ');
    }

    return Column(
      children:
          warnings.map((w) {
            return ListTile(
              title: Text(w['title'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nội dung: ${w['content'] ?? ''}'),
                  if (w['advice'] != null) Text('Lời khuyên: ${w['advice']}'),
                  Text('Ngày tạo: ${_formatDate(w['created_at'])}'),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _AttendanceStatsCard extends StatelessWidget {
  final List<SemesterReport> semesterReports;

  const _AttendanceStatsCard({Key? key, required this.semesterReports})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (semesterReports.isEmpty) {
      return const Text('Chưa có dữ liệu chuyên cần');
    }

    final latestReport = semesterReports.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Điểm rèn luyện: ${latestReport.trainingPointSummary}'),
        const SizedBox(height: 8),
        Text('Điểm công tác xã hội: ${latestReport.socialPointSummary}'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: latestReport.trainingPointSummary / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            latestReport.trainingPointSummary >= 70
                ? Colors.green
                : Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _CourseGradesList extends StatelessWidget {
  final List<Map<String, dynamic>> grades;

  const _CourseGradesList({Key? key, required this.grades}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return const Text('Chưa có điểm');
    }

    return Column(
      children:
          grades.map((grade) {
            final course = grade['course'] as Map<String, dynamic>?;
            final semester = grade['semester'] as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(course?['course_name'] ?? '-'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã môn: ${course?['course_code'] ?? '-'}'),
                    Text(
                      'Học kỳ: ${semester?['semester_name'] ?? '-'} ${semester?['academic_year'] ?? ''}',
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${grade['grade_value'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${grade['grade_letter'] ?? '-'}',
                      style: TextStyle(
                        color: _getGradeColor(grade['status']?.toString()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Color _getGradeColor(String? status) {
    if (status == 'passed') return Colors.green;
    if (status == 'failed') return Colors.red;
    return Colors.grey;
  }
}

class _PointsSummary extends StatelessWidget {
  final List<SemesterReport> semesterReports;

  const _PointsSummary({Key? key, required this.semesterReports})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (semesterReports.isEmpty) {
      return const Text('Chưa có dữ liệu điểm');
    }

    final totalTraining = semesterReports.fold<int>(
      0,
      (sum, r) => sum + r.trainingPointSummary,
    );

    final totalSocial = semesterReports.fold<int>(
      0,
      (sum, r) => sum + r.socialPointSummary,
    );

    final avgTraining = totalTraining / semesterReports.length;
    final avgSocial = totalSocial / semesterReports.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tổng điểm rèn luyện: $totalTraining'),
        Text('Trung bình điểm rèn luyện: ${avgTraining.toStringAsFixed(1)}'),
        const SizedBox(height: 8),
        Text('Tổng điểm công tác xã hội: $totalSocial'),
        Text('Trung bình điểm CTXH: ${avgSocial.toStringAsFixed(1)}'),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) => false;
}
