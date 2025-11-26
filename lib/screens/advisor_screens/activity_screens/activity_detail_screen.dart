import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/app_colors.dart';
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
      final prov = Provider.of<ActivitiesProvider>(context, listen: false);
      prov.fetchDetail(int.parse(widget.activityId));
      if (kDebugMode) print('Calling fetchRegistrations for activity ${widget.activityId}');
      prov.fetchRegistrations(int.parse(widget.activityId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hoạt động'), backgroundColor: AppColors.primary),
      body: Consumer<ActivitiesProvider>(builder: (ctx, prov, _) {
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
                    onTap: () => context.push('/advisor/students/${s.studentId}'),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            // Debug: show raw registrations and a reload button
            const SizedBox(height: 8),
            Text('Registrations count: ${prov.registrations.length}'),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(prov.registrations.toString()),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (kDebugMode) print('Manual reload registrations for ${widget.activityId}');
                prov.fetchRegistrations(int.parse(widget.activityId));
              },
              child: const Text('Reload registrations'),
            ),
            Row(children: [
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Quay lại')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () => context.push('/advisor/activities/manage/edit/${a.activityId}'), child: const Text('Chỉnh sửa')),
            ])
          ]),
        );
      }),
    );
  }
}
