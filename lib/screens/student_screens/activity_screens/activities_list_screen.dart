import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../models/models.dart';
import '../../../providers/activities_provider.dart';

class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivitiesProvider(),
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
          title: const Text('Hoạt động'),
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () => _openSearchDialog(context)),
          ],
          bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Sắp tới'), Tab(text: 'Đã đăng ký'), Tab(text: 'Lịch sử')]),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(context, 'upcoming'),
            _buildTabContent(context, 'registered'),
            _buildTabContent(context, 'history'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, String status) {
    final provider = Provider.of<ActivitiesProvider>(context, listen: false);

    return FutureBuilder<void>(
      future: provider.fetchActivities(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && provider.activities.isEmpty) {
          return _buildLoadingSkeleton();
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: Consumer<ActivitiesProvider>(builder: (context, prov, _) {
            final items = prov.activities;
            if (prov.isLoading && items.isEmpty) return _buildLoadingSkeleton();
            if (items.isEmpty) return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 200), Center(child: Text('Không có hoạt động'))]);

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final a = items[idx];
                return _buildActivityCard(context, a, prov);
              },
            );
          }),
        );
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity a, ActivitiesProvider prov) {
    Widget pointsBadge() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
          child: Text('${a.activityId}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: AppColors.primaryVariant, child: const Icon(Icons.event, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(children: [Icon(Icons.schedule, size: 14, color: Colors.black54), const SizedBox(width: 6), Text(_formatDateRange(a))]),
                const SizedBox(height: 4),
                Row(children: [Icon(Icons.location_on, size: 14, color: Colors.black54), const SizedBox(width: 6), Text(a.location ?? '')]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [Text('Đã đăng ký: 0'), const SizedBox(width: 12), pointsBadge()]),
                  ElevatedButton(
                    onPressed: () async {
                      // Register flow (payload depends on API). We'll use activity_id as example.
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await prov.register({'activity_id': a.activityId});
                      messenger.showSnackBar(SnackBar(content: Text(ok ? 'Đăng ký thành công' : 'Đăng ký thất bại')));
                    },
                    child: const Text('Đăng ký ngay'),
                  )
                ])
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(28))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 14, color: Colors.grey[300]), const SizedBox(height: 8), Container(height: 12, color: Colors.grey[300])]))
            ]),
          ),
        );
      },
    );
  }

  void _openSearchDialog(BuildContext context) async {
    final prov = Provider.of<ActivitiesProvider>(context, listen: false);
    final q = await showDialog<String>(context: context, builder: (ctx) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: const Text('Tìm kiếm'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nhập tên hoạt động...')),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Tìm'))],
      );
    });

    if (q != null && q.isNotEmpty) {
      await prov.fetchActivities(q: q);
    }
  }

  String _formatDateRange(Activity a) {
    if (a.startTime == null) return 'Thời gian chưa xác định';
    final s = a.startTime!;
    final e = a.endTime;
    if (e == null) return '${s.day}/${s.month}/${s.year} ${s.hour}:${s.minute.toString().padLeft(2, '0')}';
    return '${s.day}/${s.month} ${s.hour}:${s.minute.toString().padLeft(2, '0')} - ${e.day}/${e.month} ${e.hour}:${e.minute.toString().padLeft(2, '0')}';
  }
}
