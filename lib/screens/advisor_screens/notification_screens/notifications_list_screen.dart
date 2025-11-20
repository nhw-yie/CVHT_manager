// lib/screens/advisor_screens/notification_screens/notifications_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/notifications_provider.dart';
import '../../../models/notification_model.dart';
import 'notification_detail_screen.dart';
import 'create_notification_screen.dart';

class AdvisorNotificationsListScreen extends StatefulWidget {
  const AdvisorNotificationsListScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorNotificationsListScreen> createState() => 
      _AdvisorNotificationsListScreenState();
}

class _AdvisorNotificationsListScreenState 
    extends State<AdvisorNotificationsListScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdvisorNotificationsProvider>().fetchNotifications();
      context.read<AdvisorNotificationsProvider>().fetchStatistics();
    });
  }

  Future<void> _refresh() async {
    await context.read<AdvisorNotificationsProvider>().fetchNotifications();
    await context.read<AdvisorNotificationsProvider>().fetchStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thông báo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => _showStatistics(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo thông báo'),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<AdvisorNotificationsProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả', 'all', provider),
                const SizedBox(width: 8),
                _filterChip('Chung', 'general', provider),
                const SizedBox(width: 8),
                _filterChip('Học vụ', 'academic', provider),
                const SizedBox(width: 8),
                _filterChip('Hoạt động', 'activity', provider),
                const SizedBox(width: 8),
                _filterChip('Khẩn cấp', 'urgent', provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value, AdvisorNotificationsProvider provider) {
    final isSelected = provider.typeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setTypeFilter(value),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildNotificationsList() {
    return Consumer<AdvisorNotificationsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final notifications = provider.filteredNotifications;

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có thông báo nào',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo thông báo đầu tiên'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, notification),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.summary,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (notification.classes != null && notification.classes!.isNotEmpty)
                    _buildInfoChip(
                      Icons.class_,
                      '${notification.classes!.length} lớp',
                      Colors.blue,
                    ),
                  if (notification.attachments != null && notification.attachments!.isNotEmpty)
                    _buildInfoChip(
                      Icons.attach_file,
                      '${notification.attachments!.length} file',
                      Colors.orange,
                    ),
                  if (notification.totalRecipients != null)
                    _buildInfoChip(
                      Icons.people,
                      '${notification.totalRecipients} SV',
                      Colors.green,
                    ),
                ],
              ),
              if (notification.totalRecipients != null && notification.totalRecipients! > 0) ...[
                const SizedBox(height: 12),
                _buildProgressBar(notification),
              ],
              if (notification.responsesCount != null && notification.responsesCount! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.question_answer, size: 16, color: Colors.purple[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${notification.responsesCount} phản hồi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'urgent':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'academic':
        icon = Icons.school;
        color = Colors.blue;
        break;
      case 'activity':
        icon = Icons.event;
        color = Colors.green;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(NotificationModel notification) {
    final percentage = notification.readPercentage;
    final read = notification.totalRead ?? 0;
    final total = notification.totalRecipients ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đã xem: $read/$total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: percentage >= 80 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 80 ? Colors.green : Colors.orange,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateNotificationScreen(),
      ),
    ).then((_) => _refresh());
  }

  void _navigateToDetail(NotificationModel notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notificationId: notification.notificationId,
        ),
      ),
    );
  }

  void _handleMenuAction(String action, NotificationModel notification) {
    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateNotificationScreen(
            notification: notification,
          ),
        ),
      ).then((_) => _refresh());
    } else if (action == 'delete') {
      _confirmDelete(notification);
    }
  }

  void _confirmDelete(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa thông báo "${notification.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<AdvisorNotificationsProvider>();
              final success = await provider.deleteNotification(notification.notificationId);
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã xóa thông báo' : 'Xóa thất bại'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    final provider = context.read<AdvisorNotificationsProvider>();
    final stats = provider.statistics;

    if (stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải thống kê...')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thống kê thông báo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow('Tổng thông báo', stats.totalNotifications.toString()),
              _statRow('Tổng người nhận', stats.totalRecipients.toString()),
              _statRow('Đã đọc', '${stats.totalRead} (${stats.readPercentage.toStringAsFixed(1)}%)'),
              _statRow('Phản hồi', stats.totalResponses.toString()),
              _statRow('Chờ xử lý', stats.pendingResponses.toString()),
              if (stats.byType.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Theo loại:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...stats.byType.map((t) => _statRow(t.type, t.count.toString())),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}