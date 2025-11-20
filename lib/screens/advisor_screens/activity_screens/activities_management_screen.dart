import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../providers/advisor_activities_provider.dart';

class ActivitiesManagementScreen extends StatefulWidget {
  const ActivitiesManagementScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesManagementScreen> createState() => _ActivitiesManagementScreenState();
}

class _ActivitiesManagementScreenState extends State<ActivitiesManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<AdvisorActivitiesProvider>(context, listen: false);
      prov.fetchActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hoạt động'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<AdvisorActivitiesProvider>(context, listen: false).fetchActivities(),
          ),
        ],
      ),
      body: Consumer<AdvisorActivitiesProvider>(builder: (ctx, prov, _) {
        if (prov.isLoading && prov.activities.isEmpty) return const Center(child: CircularProgressIndicator());
        final items = prov.activities;
        if (items.isEmpty) return RefreshIndicator(onRefresh: prov.fetchActivities, child: ListView(children: const [SizedBox(height: 200), Center(child: Text('Không có hoạt động'))]));

        return RefreshIndicator(
          onRefresh: prov.fetchActivities,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final a = items[idx];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.primaryVariant, child: const Icon(Icons.event, color: Colors.white)),
                  title: Text(a.title),
                  subtitle: Text(a.location ?? ''),
                  trailing: PopupMenuButton<String>(onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/advisor/activities/manage/edit/${a.activityId}');
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Xác nhận'), content: const Text('Bạn có chắc muốn xóa hoạt động này?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa'))]));
                      if (ok == true) {
                        await prov.deleteActivity(a.activityId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa hoạt động')));
                      }
                    } else if (v == 'view') {
                      context.push('/advisor/activities/manage/${a.activityId}');
                    }
                  }, itemBuilder: (_) => const [PopupMenuItem(value: 'view', child: Text('Xem')), PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')), PopupMenuItem(value: 'delete', child: Text('Xóa'))]),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/advisor/activities/manage/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
