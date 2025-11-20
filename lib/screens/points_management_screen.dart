import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PointsManagementScreen extends StatefulWidget {
  const PointsManagementScreen({Key? key}) : super(key: key);

  @override
  State<PointsManagementScreen> createState() => _PointsManagementScreenState();
}

class _PointsManagementScreenState extends State<PointsManagementScreen> {
  List<String> semesters = ['Học kỳ 1 - 2024', 'Học kỳ 2 - 2024', 'Học kỳ 1 - 2025'];
  String selectedSemester = 'Học kỳ 1 - 2024';

  // Sample aggregated values (in a real app these come from the API)
  double renLuyen = 82; // /100
  double ctxh = 8.5; // social activity points
  String classification = 'Khá';

  Map<String, double> detailScores = {
    'Ý thức học tập': 30,
    'Ý thức tổ chức kỷ luật': 22,
    'Hoạt động xã hội': 20,
    'Văn hóa thể thao': 10,
  };

  List<Map<String, dynamic>> activities = [
    {'title': 'Ngày hội hiến máu', 'points': 2.0, 'date': DateTime(2024, 11, 15)},
    {'title': 'Tình nguyện hè', 'points': 5.0, 'date': DateTime(2024, 7, 20)},
    {'title': 'Giải chạy sinh viên', 'points': 1.5, 'date': DateTime(2024, 9, 3)},
  ];

  // Complaint form state
  final TextEditingController _complaintCtrl = TextEditingController();
  File? _evidenceImage;
  bool _submitting = false;

  @override
  void dispose() {
    _complaintCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (res != null && res.files.isNotEmpty) {
      final path = res.files.single.path;
      if (path != null) {
        setState(() => _evidenceImage = File(path));
      }
    }
  }

  Future<void> _openComplaintSheet() async {
    _complaintCtrl.clear();
    _evidenceImage = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Wrap(children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Khiếu nại điểm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: _complaintCtrl, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Mô tả khiếu nại...')),
                const SizedBox(height: 12),
                Row(children: [
                  ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Thêm minh chứng')),
                  const SizedBox(width: 12),
                  if (_evidenceImage != null) Expanded(child: Text('1 tệp đã chọn', style: const TextStyle(fontStyle: FontStyle.italic)))
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final content = _complaintCtrl.text.trim();
                            if (content.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung')));
                              return;
                            }
                            setState(() => _submitting = true);
                            // Simulate network submit
                            await Future.delayed(const Duration(seconds: 1));
                            if (!mounted) return;
                            setState(() => _submitting = false);
                            Navigator.of(context).pop();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi khiếu nại thành công')));
                          },
                    child: _submitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Gửi khiếu nại'),
                  ),
                )
              ]),
            )
          ]),
        );
      },
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _buildSummaryCard() {
    final percent = (renLuyen / 100).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tổng hợp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: [
            // Animated circular indicator
            SizedBox(
              width: 110,
              height: 110,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent),
                duration: const Duration(milliseconds: 800),
                builder: (ctx, value, child) => Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(value: value, strokeWidth: 10, color: AppColors.primary.withOpacity(0.9)),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${(value * 100).toStringAsFixed(0)}/100', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Rèn luyện')
                  ])
                ]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Điểm rèn luyện: ${renLuyen.toStringAsFixed(0)}/100', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Điểm CTXH: ${ctxh.toStringAsFixed(1)}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Xếp loại: $classification', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: LineChart(LineChartData(
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(spots: List.generate(6, (i) => FlSpot(i.toDouble(), (50 + i * 5 + (i % 2 == 0 ? 10 : 0)).toDouble())), isCurved: true, barWidth: 3, color: AppColors.primary),
                    ],
                  )),
                )
              ]),
            )
          ])
        ]),
      ),
    );
  }

  Widget _buildDetailTiles() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: detailScores.entries.map((e) {
        return ExpansionTile(
          title: Text(e.key),
          subtitle: Text('Điểm: ${e.value.toStringAsFixed(1)}'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LinearProgressIndicator(value: (e.value / 40).clamp(0.0, 1.0), color: AppColors.primary),
                const SizedBox(height: 8),
                Text('Ghi chú: Điểm được tính theo tiêu chí...'),
              ]),
            )
          ],
        );
      }).toList()),
    );
  }

  Widget _buildActivitiesList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.all(12.0), child: Text('Các hoạt động đã tham gia', style: TextStyle(fontWeight: FontWeight.bold))),
        const Divider(height: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final it = activities[i];
            return ListTile(
              title: Text(it['title'] ?? '-'),
              subtitle: Text('${it['points']} điểm • ${_formatDate(it['date'] as DateTime)}'),
              trailing: Text('+${it['points']}', style: const TextStyle(color: AppColors.accent)),
            );
          },
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý điểm'), backgroundColor: AppColors.primary, leading: BackButton(color: Colors.white)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Semester dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(children: [
                  const Icon(Icons.calendar_month, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedSemester,
                      isExpanded: true,
                      items: semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selectedSemester = v);
                        // TODO: reload data for selected semester from API
                      },
                    ),
                  )
                ]),
              ),
            ),

            const SizedBox(height: 12),
            _buildSummaryCard(),
            const SizedBox(height: 12),
            _buildDetailTiles(),
            const SizedBox(height: 12),
            _buildActivitiesList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: _openComplaintSheet,
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Text('Khiếu nại điểm')),
              ),
            ),
            const SizedBox(height: 20)
          ]),
        ),
      ),
    );
  }
}
