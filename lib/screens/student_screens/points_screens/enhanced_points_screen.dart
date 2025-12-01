// lib/screens/student_screens/points/enhanced_points_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/enhanced_points_provider.dart';
import '../../../models/points.dart';
import '../../../models/student_grades_summary.dart';

class EnhancedPointsScreen extends StatefulWidget {
  const EnhancedPointsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedPointsScreen> createState() => _EnhancedPointsScreenState();
}

class _EnhancedPointsScreenState extends State<EnhancedPointsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EnhancedPointsProvider>();
      _loadInitialData(provider);
    });
  }

  Future<void> _loadInitialData(EnhancedPointsProvider provider) async {
    await provider.fetchCurrentSemester();
    await provider.fetchSemesters();
    
    if (provider.selectedSemesterId != null) {
      await provider.fetchAllDataForSemester(provider.selectedSemesterId!);
      await provider.fetchPointFeedbacks(semesterId: provider.selectedSemesterId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý điểm'),
        backgroundColor: primary,
        foregroundColor: onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: onPrimary,
          labelColor: onPrimary,
          unselectedLabelColor: onPrimary.withOpacity(0.8),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Học tập'),
            Tab(text: 'Rèn luyện'),
            Tab(text: 'Khiếu nại'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSemesterFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(),
                _GradesTab(),
                _TrainingPointsTab(),
                _FeedbacksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterFilter() {
    return Consumer<EnhancedPointsProvider>(
      builder: (context, provider, _) {
        if (provider.semesters.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 4, offset: const Offset(0,2))]),
          child: Row(children: [
            Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<int>(
              value: provider.selectedSemesterId,
              decoration: const InputDecoration(labelText: 'Học kỳ', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: [const DropdownMenuItem<int>(value: null, child: Text('Tất cả học kỳ'))] + provider.semesters.map((s) => DropdownMenuItem<int>(value: s.semesterId, child: Text('${s.semesterName} - ${s.academicYear}'))).toList(),
              onChanged: (value) {
                provider.setSelectedSemester(value);
                if (value != null) provider.fetchPointFeedbacks(semesterId: value);
              },
            )),
          ]),
        );
      },
    );
  }
}

// ============================================
// TAB 1: TỔNG QUAN
// ============================================

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPointsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingReport || provider.isLoadingPoints) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (provider.selectedSemesterId != null) {
                      provider.fetchAllDataForSemester(provider.selectedSemesterId!);
                    }
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final report = provider.semesterReport?.report;
        final points = provider.pointsSummary;

        return RefreshIndicator(
          onRefresh: () async {
            if (provider.selectedSemesterId != null) {
              await provider.fetchAllDataForSemester(provider.selectedSemesterId!);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAcademicSummaryCard(context, report),
                const SizedBox(height: 16),
                _buildPointsSummaryCard(context, points),
                const SizedBox(height: 16),
                _buildOutcomeCard(report, points),
                const SizedBox(height: 16),
                _buildQuickStats(report, points),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicSummaryCard(BuildContext context, SemesterReportData? report) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Kết quả học tập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('GPA học kỳ (10)', report?.gpa?.toStringAsFixed(2) ?? '-'),
            _buildInfoRow('GPA học kỳ (4)', report?.gpa4Scale?.toStringAsFixed(2) ?? '-'),
            _buildInfoRow('CPA tích lũy (10)', report?.cpa10Scale?.toStringAsFixed(2) ?? '-'),
            _buildInfoRow('CPA tích lũy (4)', report?.cpa4Scale?.toStringAsFixed(2) ?? '-'),
            const Divider(height: 16),
            _buildInfoRow('Tín chỉ đăng ký', report?.creditsRegistered.toString() ?? '-'),
            _buildInfoRow('Tín chỉ đạt', report?.creditsPassed.toString() ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSummaryCard(BuildContext context, StudentPointsSummary? points) {
    final trainingPoints = points?.totalTrainingPoints ?? 0;
    final progress = (trainingPoints / 100).clamp(0.0, 1.0);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Điểm rèn luyện',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Điểm rèn luyện',
              '${trainingPoints.toStringAsFixed(0)}/100',
            ),
            _buildInfoRow(
              'Điểm CTXH',
              points?.totalSocialPoints.toStringAsFixed(1) ?? '0',
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: _getProgressColor(trainingPoints),
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double points) {
    if (points >= 90) return Colors.green;
    if (points >= 80) return Colors.blue;
    if (points >= 65) return Colors.orange;
    if (points >= 50) return Colors.amber;
    return Colors.red;
  }

  Widget _buildOutcomeCard(SemesterReportData? report, StudentPointsSummary? points) {
    final outcome = report?.outcome ?? 'Chưa xác định';
    final trainingPoints = points?.totalTrainingPoints ?? 0;
    
    String classification = 'Chưa đánh giá';
    Color color = Colors.grey;
    IconData icon = Icons.help_outline;
    
    if (trainingPoints >= 90) {
      classification = 'Xuất sắc';
      color = Colors.green;
      icon = Icons.workspace_premium;
    } else if (trainingPoints >= 80) {
      classification = 'Giỏi';
      color = Colors.blue;
      icon = Icons.star;
    } else if (trainingPoints >= 65) {
      classification = 'Khá';
      color = Colors.orange;
      icon = Icons.thumb_up;
    } else if (trainingPoints >= 50) {
      classification = 'Trung bình';
      color = Colors.amber;
      icon = Icons.sentiment_satisfied;
    } else {
      classification = 'Yếu';
      color = Colors.red;
      icon = Icons.sentiment_dissatisfied;
    }

    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(
              classification,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kết quả: $outcome',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(SemesterReportData? report, StudentPointsSummary? points) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tín chỉ đạt',
            report?.creditsPassed.toString() ?? '0',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Hoạt động',
            ((points?.trainingActivities.length ?? 0) + 
             (points?.socialActivities.length ?? 0)).toString(),
            Icons.event,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// TAB 2: ĐIỂM HỌC TẬP
// ============================================

class _GradesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPointsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingGrades) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = provider.gradesSummary;
        if (summary == null || summary.grades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có điểm học tập',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (provider.selectedSemesterId != null) {
              await provider.fetchGradesForSemester(provider.selectedSemesterId!);
            }
          },
          child: Column(
            children: [
              _buildGradesSummary(context, summary.summary),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: summary.grades.length,
                  itemBuilder: (ctx, i) {
                    final grade = summary.grades[i];
                    return _buildGradeCard(grade);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradesSummary(BuildContext context, GradeSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Tổng', summary.totalCourses, Colors.blue),
          _buildSummaryItem('Đạt', summary.passedCourses, Colors.green),
          _buildSummaryItem('Không đạt', summary.failedCourses, Colors.red),
          _buildSummaryItem('Đang học', summary.studyingCourses, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildGradeCard(CourseGradeDetail grade) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pending;
    
    switch (grade.status) {
      case 'passed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'studying':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          radius: 24,
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Text(
          grade.courseName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${grade.courseCode} • ${grade.semester} • ${grade.credits} TC',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              grade.grade10?.toStringAsFixed(1) ?? '-',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            Text(
              grade.gradeLetter ?? '-',
              style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TAB 3: ĐIỂM RÈN LUYỆN
// ============================================

class _TrainingPointsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPointsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingPoints) {
          return const Center(child: CircularProgressIndicator());
        }

        final points = provider.pointsSummary;
        if (points == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (provider.selectedSemesterId != null) {
              await provider.fetchPointsForSemester(provider.selectedSemesterId!);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPointsBreakdown(context, points),
              const SizedBox(height: 16),
              _buildActivitiesList(
                'Hoạt động rèn luyện',
                points.trainingActivities,
                Colors.blue,
                Icons.school,
              ),
              const SizedBox(height: 16),
              _buildActivitiesList(
                'Hoạt động CTXH',
                points.socialActivities,
                Colors.green,
                Icons.volunteer_activism,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsBreakdown(BuildContext context, StudentPointsSummary points) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Chi tiết điểm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildPointCircle(
                    'Rèn luyện',
                    points.totalTrainingPoints,
                    100,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPointCircle(
                    'CTXH',
                    points.totalSocialPoints,
                    null,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointCircle(String label, double points, double? max, Color color) {
    final displayValue = max != null 
        ? '${points.toStringAsFixed(0)}/$max'
        : points.toStringAsFixed(1);

    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (max != null)
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: (points / max).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    color: color,
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesList(
    String title,
    List<ActivityPointItem> activities,
    Color color,
    IconData icon,
  ) {
    if (activities.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Chưa có hoạt động nào',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activities.length} hoạt động',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (ctx, i) {
              final activity = activities[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(
                    '+${activity.pointsAwarded.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  activity.activityTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    activity.roleName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                trailing: activity.activityDate != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yy').format(activity.activityDate!),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================
// TAB 4: KHIẾU NẠI
// ============================================

class _FeedbacksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPointsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingFeedbacks) {
          return const Center(child: CircularProgressIndicator());
        }

        final feedbacks = provider.feedbacks;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateFeedbackDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo khiếu nại mới'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: feedbacks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có khiếu nại nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (provider.selectedSemesterId != null) {
                          await provider.fetchPointFeedbacks(
                            semesterId: provider.selectedSemesterId,
                          );
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: feedbacks.length,
                        itemBuilder: (ctx, i) {
                          return _buildFeedbackCard(context, feedbacks[i]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackCard(BuildContext context, PointFeedbackDetail feedback) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (feedback.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Đang chờ';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Từ chối';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Không rõ';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor, size: 28),
        title: Text(
          feedback.semester?.semesterName ?? 'Học kỳ không xác định',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              feedback.feedbackContent.length > 50
                  ? '${feedback.feedbackContent.substring(0, 50)}...'
                  : feedback.feedbackContent,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(feedback.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nội dung khiếu nại:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.feedbackContent,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                
                if (feedback.advisorResponse != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue,
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feedback.advisor?.fullName ?? 'Cố vấn',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (feedback.responseAt != null)
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm')
                                          .format(feedback.responseAt!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feedback.advisorResponse!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (feedback.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showEditFeedbackDialog(context, feedback);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Sửa'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: const Text(
                                  'Bạn có chắc muốn xóa khiếu nại này?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              final provider = context.read<EnhancedPointsProvider>();
                              final success = await provider.deletePointFeedback(
                                feedback.feedbackId,
                              );

                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã xóa khiếu nại'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.error ?? 'Không thể xóa khiếu nại',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Xóa'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateFeedbackDialog(BuildContext context) {
    final contentController = TextEditingController();
    final provider = context.read<EnhancedPointsProvider>();
    int? selectedSemesterId = provider.selectedSemesterId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo khiếu nại điểm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: selectedSemesterId,
                decoration: const InputDecoration(
                  labelText: 'Học kỳ *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                items: provider.semesters
                    .map((s) => DropdownMenuItem(
                          value: s.semesterId,
                          child: Text('${s.semesterName} - ${s.academicYear}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedSemesterId = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 6,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Nội dung khiếu nại *',
                  border: OutlineInputBorder(),
                  hintText: 'Mô tả chi tiết khiếu nại của bạn...',
                  prefixIcon: Icon(Icons.note_alt),
                  helperText: 'Tối đa 500 ký tự',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (selectedSemesterId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng chọn học kỳ'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final content = contentController.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập nội dung khiếu nại'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final success = await provider.createPointFeedback(
                semesterId: selectedSemesterId!,
                content: content,
              );

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã tạo khiếu nại thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.error ?? 'Không thể tạo khiếu nại',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Tạo khiếu nại'),
          ),
        ],
      ),
    );
  }

  void _showEditFeedbackDialog(BuildContext context, PointFeedbackDetail feedback) {
    final contentController = TextEditingController(text: feedback.feedbackContent);
    final provider = context.read<EnhancedPointsProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa khiếu nại'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text(feedback.semester?.semesterName ?? 'N/A'),
                subtitle: Text(feedback.semester?.academicYear ?? ''),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                maxLines: 6,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Nội dung khiếu nại *',
                  border: OutlineInputBorder(),
                  hintText: 'Mô tả chi tiết khiếu nại của bạn...',
                  prefixIcon: Icon(Icons.note_alt),
                  helperText: 'Tối đa 500 ký tự',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập nội dung khiếu nại'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final success = await provider.updatePointFeedback(
                feedbackId: feedback.feedbackId,
                content: content,
              );

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật khiếu nại'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.error ?? 'Không thể cập nhật khiếu nại',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }
}