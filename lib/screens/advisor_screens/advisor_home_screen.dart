import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AdvisorHomeScreen extends StatefulWidget {
  const AdvisorHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorHomeScreen> createState() => _AdvisorHomeScreenState();
}

class _AdvisorHomeScreenState extends State<AdvisorHomeScreen> {
  bool _loading = false;
  int _totalStudents = 120;
  double _avgGpa = 3.12;
  int _academicWarnings = 4;
  int _pendingReports = 7;

  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Phê duyệt đơn nghỉ', 'count': 5},
    {'title': 'Xác nhận điểm CTXH', 'count': 2},
    {'title': 'Phản hồi sinh viên', 'count': 3},
  ];

  Future<void> _refresh() async {
    setState(() => _loading = true);
    // TODO: call provider/api to refresh real data
    await Future.delayed(const Duration(milliseconds: 700));
    // simulate some change
    setState(() {
      _totalStudents = 120;
      _avgGpa = 3.15;
      _academicWarnings = 3;
      _pendingReports = 6;
      _loading = false;
    });
  }

  Widget _buildOverviewCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Tổng số sinh viên', style: TextStyle(color: Colors.grey[700])), const SizedBox(height: 6), Text('$_totalStudents', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('GPA trung bình', style: TextStyle(color: Colors.grey[700])), const SizedBox(height: 6), Text(_avgGpa.toStringAsFixed(2), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Cảnh cáo học vụ', style: TextStyle(color: Colors.grey[700])), const SizedBox(height: 6), Text('$_academicWarnings', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange))]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Phản hồi chờ', style: TextStyle(color: Colors.grey[700])), const SizedBox(height: 6), Text('$_pendingReports', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red))]),
          ])
        ]),
      ),
    );
  }

  Widget _buildQuickGrid() {
    final items = [
          {'label': 'Thông báo', 'icon': Icons.campaign, 'route': '/advisor/notifications'},
          {'label': 'Sinh viên', 'icon': Icons.group, 'route': '/advisor/students'},
          {'label': 'Hoạt động', 'icon': Icons.event, 'route': '/advisor/activities/manage'},
          {'label': 'Điểm số', 'icon': Icons.score, 'route': '/advisor/points'},
          {'label': 'Họp lớp', 'icon': Icons.meeting_room, 'route': '/advisor/meetings'},
          {'label': 'Tin nhắn', 'icon': Icons.message, 'route': '/advisor/messages'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1),
        itemBuilder: (ctx, idx) {
          final it = items[idx];
          return GestureDetector(
            onTap: () {
              final route = it['route'] as String?;
              if (route == null) return;
              try {
                // Use GoRouter to navigate in Router 2.0 app
                context.go(route);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chưa có màn hình cho ${it['label']}')));
              }
            },
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(it['icon'] as IconData, size: 28, color: AppColors.primary), const SizedBox(height: 8), Text(it['label'] as String, textAlign: TextAlign.center)]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cần xử lý', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tasks.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (ctx, idx) {
            final t = _tasks[idx];
            return ListTile(
              title: Text(t['title'] as String),
              trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)), child: Text('${t['count']}', style: const TextStyle(color: Colors.white))),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mở ${t['title']}'))),
            );
          },
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final name = auth.currentUser?.fullName ?? 'Giảng viên';
    final classInCharge = 'Lớp 19CNTT';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard CVHT'),
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => context.go('/advisor/notifications')),
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.go('/advisor/profile')),
        ],
      ),
      drawer: Drawer(child: ListView(padding: EdgeInsets.zero, children: [DrawerHeader(decoration: BoxDecoration(color: AppColors.primary), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(classInCharge, style: const TextStyle(color: Colors.white70))])), ListTile(leading: const Icon(Icons.home), title: const Text('Trang chủ'), onTap: () => Navigator.pop(context)), ListTile(leading: const Icon(Icons.logout), title: const Text('Đăng xuất'), onTap: () { Navigator.pop(context); auth.logout(); })])),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Chào, $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text('Lớp phụ trách: $classInCharge', style: const TextStyle(color: Colors.black54))])),
            _buildOverviewCard(),
            const SizedBox(height: 6),
            _buildQuickGrid(),
            const SizedBox(height: 8),
            _buildPendingSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
    );
  }
}
