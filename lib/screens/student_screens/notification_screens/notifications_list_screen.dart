import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../models/models.dart';
import '../../../providers/notification_provider_student.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<NotificationsProvider>(context, listen: false);
      prov.fetchAll();
      prov.fetchUnread();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Thông báo'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chưa đọc'),
          ],
        ),
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, prov, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(context, prov.allNotifications, prov),
              _buildList(context, prov.unreadNotifications, prov),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<NotificationModel> items, NotificationsProvider prov) {
    if (prov.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await prov.fetchAll();
          await prov.fetchUnread();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(child: Text('Không có thông báo')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await prov.fetchAll();
        await prov.fetchUnread();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: items.length,
        itemBuilder: (context, idx) {
          final n = items[idx];

          return Dismissible(
            key: ValueKey(n.notificationId),
            direction: DismissDirection.endToStart,
            background: Container(
              color: AppColors.primary,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.mark_email_read, color: Colors.white),
            ),
            onDismissed: (_) async {
              await prov.markAsRead(n);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu là đã đọc')),
              );
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: n.isRead ? Colors.grey[300] : AppColors.accent,
                child: Icon(
                  n.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                  color: Colors.white,
                ),
              ),
              title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.summary != null && n.summary!.isNotEmpty)
                    Text(n.summary!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (n.advisorId != null) Text('Giảng viên #${n.advisorId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
              isThreeLine: true,
              trailing: Text(n.createdAt != null ? _formatDate(n.createdAt!) : ''),
              onTap: () async {
                try {
                  // Prefetch detail into provider, then mark read and navigate
                  await prov.fetchDetail(n.notificationId);
                  await prov.markAsRead(n);
                  if (!mounted) return;
                  if (prov.detailError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không thể tải chi tiết: ${prov.detailError}')),
                    );
                    return;
                  }
                  debugPrint('Navigating to notification detail id=${n.notificationId}');
                  // Use push so the detail screen is stacked above the list
                  context.push('/student/notifications/${n.notificationId}');
                  debugPrint('After push, location=${GoRouter.of(context).location}');
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể tải chi tiết: $e')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
