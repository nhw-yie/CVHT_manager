import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../providers/academic_monitoring_provider.dart';
import '../../../providers/semester_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';

/// Students Overview Dashboard for Advisor
/// This screen shows quick stats, breakdowns and charts for academic monitoring.
class StudentsOverviewScreen extends StatefulWidget {
  const StudentsOverviewScreen({Key? key}) : super(key: key);

  @override
  State<StudentsOverviewScreen> createState() => _StudentsOverviewScreenState();
}

class _StudentsOverviewScreenState extends State<StudentsOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Defer provider calls until after first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monitor = context.read<AcademicMonitoringProvider>();
      // Fetch the latest statistics for the currently selected semester (if any)
      monitor.fetchAcademicStatistics(semesterId: monitor.selectedSemesterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<AcademicMonitoringProvider>();
    final semesterProv = context.watch<SemesterProvider>();

    final stats = monitor.academicStatistics ?? {};

    // Responsive layout breakpoint
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Risk level colors
    const criticalColor = Color(0xFF8B0000);
    const highColor = Color(0xFFDC143C);
    const mediumColor = Color(0xFFFF6B6B);
    const lowColor = Color(0xFFFFA500);

    // Helper to safely read numeric stats
    double _num(Object? v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    // helper to compute counts by risk level from provider data (available across build)
    double _riskCount(String level) {
      final list = monitor.atRiskStudents;
      return list.where((e) {
        final rl = (e['risk_level'] ?? e['riskLevel'] ?? '').toString().toLowerCase();
        return rl == level.toLowerCase();
      }).length.toDouble();
    }

    // Build pie chart sections from risk counts
    List<PieChartSectionData> _buildPieSections() {
      final critical = _riskCount('critical');
      final high = _riskCount('high');
      final medium = _riskCount('medium');
      final low = _riskCount('low');

      final sections = <PieChartSectionData>[];
      if (critical > 0) sections.add(PieChartSectionData(value: critical, color: criticalColor, title: 'C'));
      if (high > 0) sections.add(PieChartSectionData(value: high, color: highColor, title: 'H'));
      if (medium > 0) sections.add(PieChartSectionData(value: medium, color: mediumColor, title: 'M'));
      if (low > 0) sections.add(PieChartSectionData(value: low, color: lowColor, title: 'L'));
      if (sections.isEmpty) sections.add(PieChartSectionData(value: 1, color: AppColors.secondary, title: 'N/A'));
      return sections;
    }

    // Build simple bar groups for GPA buckets using statistics map
    List<BarChartGroupData> _buildBarGroups() {
      final stat = stats['statistics'] as Map<String, dynamic>? ?? {};
      final buckets = ['excellent', 'good', 'average', 'weak', 'poor'];
      final groups = <BarChartGroupData>[];
      for (var i = 0; i < buckets.length; i++) {
        final val = _num(stat[buckets[i]]);
        groups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: val, color: AppColors.primary, width: 16)]));
      }
      return groups;
    }

    // Quick error/loading handling
    if (monitor.isLoading) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    if (monitor.errorMessage != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Quản lý Sinh viên'),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(monitor.errorMessage!), const SizedBox(height: 12), ElevatedButton(onPressed: () => monitor.fetchAcademicStatistics(semesterId: monitor.selectedSemesterId), child: const Text('Thử lại'))])),
      );
    }

    // Empty state when no data
    if (monitor.academicStatistics == null || (monitor.academicStatistics?.isEmpty ?? true)) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Quản lý Sinh viên'),
        body: const EmptyState(message: 'Chưa có dữ liệu thống kê học vụ'),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/advisor/students'),
          label: const Text('Xem tất cả SV'),
          icon: const Icon(Icons.people),
        ),
      );
    }

    // Extract numbers from statistics map
    final totalStudents = _num(stats['total_students']).toInt();
    final atRiskCount = _num(stats['at_risk_count']).toInt();
    final warningsCount = _num(stats['academic_warning']).toInt();
    final attendanceRate = _num(stats['attendance_rate']);

    // Recent warnings (last 5)
    final recentWarnings = monitor.academicWarnings.reversed.take(5).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quản lý Sinh viên',
        actions: [
          IconButton(onPressed: () {
            // Filter action: for now open a simple dialog (placeholder)
            showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Bộ lọc'), content: const Text('Chức năng lọc sẽ được bổ sung.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
          }, icon: const Icon(Icons.filter_list)),
          IconButton(onPressed: () => monitor.fetchAcademicStatistics(semesterId: monitor.selectedSemesterId), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Semester selector
          Row(children: [
            const Text('Học kỳ:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: monitor.selectedSemesterId ?? semesterProv.currentSemester?.semesterId,
                items: semesterProv.semesters.map((s) => DropdownMenuItem<int?>(value: s.semesterId, child: Text('${s.academicYear} - ${s.semesterName}'))).toList(),
                onChanged: (val) {
                  // update provider semester and refresh
                  monitor.setSemester(val);
                },
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Quick stats cards
          Row(children: [
            Expanded(child: CustomCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tổng sinh viên', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('$totalStudents', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary))]))),
            const SizedBox(width: 12),
            Expanded(child: CustomCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sinh viên nguy cơ', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('$atRiskCount', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.error)), const SizedBox(height: 6), Text('${(atRiskCount / (totalStudents > 0 ? totalStudents : 1) * 100).toStringAsFixed(1)}%')]))),
            const SizedBox(width: 12),
            Expanded(child: CustomCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Cảnh báo học vụ', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('$warningsCount', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.warning))]))),
            const SizedBox(width: 12),
            Expanded(child: CustomCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tỉ lệ chuyên cần', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('${attendanceRate.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.success))]))),
          ]),

          const SizedBox(height: 16),

          // Risk level breakdown horizontal cards
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _riskCard('Critical', _riskCount('critical').toInt(), criticalColor, Icons.report_problem),
            const SizedBox(width: 12),
            _riskCard('High', _riskCount('high').toInt(), highColor, Icons.warning),
            const SizedBox(width: 12),
            _riskCard('Medium', _riskCount('medium').toInt(), mediumColor, Icons.info),
            const SizedBox(width: 12),
            _riskCard('Low', _riskCount('low').toInt(), lowColor, Icons.check_circle),
          ])),

          const SizedBox(height: 16),

          // Charts section
          isMobile ? Column(children: [
            CustomCard(child: SizedBox(height: 220, child: _pieChart(_buildPieSections()))),
            const SizedBox(height: 12),
            CustomCard(child: SizedBox(height: 220, child: _barChart(_buildBarGroups()))),
          ]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: CustomCard(child: SizedBox(height: 320, child: _pieChart(_buildPieSections())))),
            const SizedBox(width: 12),
            Expanded(child: CustomCard(child: SizedBox(height: 320, child: _barChart(_buildBarGroups())))),
          ]),

          const SizedBox(height: 16),

          // Quick actions
          Row(children: [
            ElevatedButton.icon(onPressed: () => context.push('/advisor/students/at-risk'), icon: const Icon(Icons.warning), label: const Text('Xem SV Nguy cơ')),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: () => context.push('/advisor/students/create-warning'), icon: const Icon(Icons.add_alert), label: const Text('Tạo Cảnh báo')),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: () {
              showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Xuất báo cáo'), content: const Text('Chức năng xuất báo cáo sẽ sớm có.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
            }, icon: const Icon(Icons.file_download), label: const Text('Xuất báo cáo')),
          ]),

          const SizedBox(height: 16),

          // Recent warnings list
          CustomCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cảnh báo gần đây', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (recentWarnings.isEmpty) const Text('Không có cảnh báo gần đây'),
            if (recentWarnings.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentWarnings.length,
                itemBuilder: (ctx, idx) {
                  final w = recentWarnings[idx];
                  final name = w['student_name'] ?? w['full_name'] ?? 'N/A';
                  final level = w['level'] ?? w['warning_level'] ?? 'unknown';
                  final date = w['created_at'] ?? w['date'] ?? '';
                  return ListTile(
                    title: Text(name.toString()),
                    subtitle: Text('$level • $date'),
                    onTap: () {
                      // Navigate to warning detail if route exists
                      if (w['id'] != null) context.push('/advisor/students/warning/${w['id']}');
                    },
                  );
                },
              ),
          ])),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/advisor/students'),
        label: const Text('Xem tất cả SV'),
        icon: const Icon(Icons.people),
      ),
    );
  }

  // Small helper widget for risk card
  Widget _riskCard(String title, int count, Color color, IconData icon) {
    return CustomCard(
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [CircleAvatar(backgroundColor: color, radius: 16, child: Icon(icon, size: 18, color: Colors.white)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // Build simple PieChart widget
  Widget _pieChart(List<PieChartSectionData> sections) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 24, sectionsSpace: 2)),
    );
  }

  // Build simple BarChart widget
  Widget _barChart(List<BarChartGroupData> groups) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: groups,
        titlesData: FlTitlesData(show: true, leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      )),
    );
  }
}
