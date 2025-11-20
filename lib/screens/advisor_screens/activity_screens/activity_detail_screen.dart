import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../providers/advisor_activities_provider.dart';

class AdvisorActivityDetailScreen extends StatefulWidget {
  final String activityId;
  const AdvisorActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  @override
  State<AdvisorActivityDetailScreen> createState() => _AdvisorActivityDetailScreenState();
}

class _AdvisorActivityDetailScreenState extends State<AdvisorActivityDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdvisorActivitiesProvider>(context, listen: false).fetchDetail(int.parse(widget.activityId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hoạt động'), backgroundColor: AppColors.primary),
      body: Consumer<AdvisorActivitiesProvider>(builder: (ctx, prov, _) {
        if (prov.isDetailLoading) return const Center(child: CircularProgressIndicator());
        final a = prov.selected;
        if (a == null) return Center(child: Text('Không tìm thấy hoạt động'));

        final assigned = prov.assignedStudents;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Địa điểm: ${a.location ?? '-'}'),
            const SizedBox(height: 8),
            Text('Thời gian: ${a.startTime ?? '-'} - ${a.endTime ?? '-'}'),
            const SizedBox(height: 12),
            Text(a.generalDescription ?? ''),
            const SizedBox(height: 20),
            if (assigned.isNotEmpty) ...[
              const Text('Danh sách sinh viên được phân bổ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assigned.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = assigned[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S')),
                    title: Text(s.fullName),
                    subtitle: Text('MSSV: ${s.userCode} • Lớp: ${s.classId ?? '-'}'),
                    onTap: () => Navigator.of(context).pushNamed('/advisor/students/${s.studentId}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            Row(children: [
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Quay lại')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => Navigator.of(context).pushNamed('/advisor/activities/manage/edit/${a.activityId}'), child: const Text('Chỉnh sửa')),
            ])
          ]),
        );
      }),
    );
  }
}
