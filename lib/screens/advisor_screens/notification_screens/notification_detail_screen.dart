// lib/screens/advisor_screens/notification_screens/notification_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/notifications_provider.dart';
import '../../../models/notification_model.dart';

class NotificationDetailScreen extends StatefulWidget {
  final int notificationId;

  const NotificationDetailScreen({
    Key? key,
    required this.notificationId,
  }) : super(key: key);

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdvisorNotificationsProvider>();
      provider.fetchDetail(widget.notificationId);
      provider.fetchResponses(widget.notificationId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thông tin', icon: Icon(Icons.info_outline)),
            Tab(text: 'Phản hồi', icon: Icon(Icons.question_answer)),
          ],
        ),
      ),
      body: Consumer<AdvisorNotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
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
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchDetail(widget.notificationId);
                      provider.fetchResponses(widget.notificationId);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final notification = provider.selectedNotification;
          if (notification == null) {
            return const Center(child: Text('Không tìm thấy thông báo'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(notification),
              _buildResponsesTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTab(NotificationModel notification) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeTag(notification.type),
          const SizedBox(height: 16),
          Text(
            notification.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatisticsCard(notification),
          const SizedBox(height: 24),
          const Text(
            'Nội dung:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notification.summary,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          if (notification.link != null) ...[
            const SizedBox(height: 24),
            _buildLinkCard(notification.link!),
          ],
          if (notification.classes != null && notification.classes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildClassesList(notification.classes!),
          ],
          if (notification.attachments != null && notification.attachments!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAttachmentsList(notification.attachments!),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeTag(String type) {
    String label;
    Color color;
    IconData icon;

    switch (type) {
      case 'urgent':
        label = 'Khẩn cấp';
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
        break;
      case 'academic':
        label = 'Học vụ';
        color = Colors.blue;
        icon = Icons.school;
        break;
      case 'activity':
        label = 'Hoạt động';
        color = Colors.green;
        icon = Icons.event;
        break;
      default:
        label = 'Chung';
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(NotificationModel notification) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.people,
                  'Người nhận',
                  notification.totalRecipients?.toString() ?? '0',
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.visibility,
                  'Đã xem',
                  notification.totalRead?.toString() ?? '0',
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.question_answer,
                  'Phản hồi',
                  notification.totalResponses?.toString() ?? '0',
                  Colors.purple,
                ),
              ],
            ),
            if (notification.totalRecipients != null && notification.totalRecipients! > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tỷ lệ đã xem:'),
                  Text(
                    '${notification.readPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: notification.readPercentage >= 80
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: notification.readPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    notification.readPercentage >= 80
                        ? Colors.green
                        : Colors.orange,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkCard(String link) {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _launchUrl(link),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.link, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liên kết đính kèm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: Colors.blue[700]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassesList(List<ClassInfo> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Các lớp nhận thông báo:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: classes.map((classInfo) {
            return Chip(
              avatar: const Icon(Icons.class_, size: 16),
              label: Text(classInfo.className),
              backgroundColor: Colors.blue[50],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachmentsList(List<AttachmentInfo> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File đính kèm:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...attachments.map((attachment) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                attachment.isImage ? Icons.image : Icons.insert_drive_file,
                color: Colors.orange,
              ),
              title: Text(attachment.fileName),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _launchUrl(attachment.fileUrl),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResponsesTab(AdvisorNotificationsProvider provider) {
    if (provider.isResponsesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final responses = provider.responses;

    if (responses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có phản hồi nào',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: responses.length,
      itemBuilder: (context, index) {
        return _buildResponseCard(responses[index], provider);
      },
    );
  }

  Widget _buildResponseCard(StudentResponseInfo response, AdvisorNotificationsProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    response.student.fullName[0].toUpperCase(),
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.student.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        response.student.userCode,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(response.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(response.content),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(response.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (response.advisorResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Phản hồi của bạn:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(response.advisorResponse!),
                    if (response.responseAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(response.responseAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (response.isPending) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showReplyDialog(response, provider),
                icon: const Icon(Icons.reply),
                label: const Text('Phản hồi'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Chờ xử lý';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Đã xử lý';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showReplyDialog(StudentResponseInfo response, AdvisorNotificationsProvider provider) {
    final controller = TextEditingController();
    String selectedStatus = 'resolved';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phản hồi sinh viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nội dung phản hồi',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            const Text('Trạng thái:'),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Đã xử lý'),
                      value: 'resolved',
                      groupValue: selectedStatus,
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Vẫn chờ xử lý'),
                      value: 'pending',
                      groupValue: selectedStatus,
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi')),
                );
                return;
              }

              Navigator.pop(context);

              final success = await provider.replyToResponse(
                responseId: response.responseId,
                advisorResponse: controller.text.trim(),
                status: selectedStatus,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã gửi phản hồi' : 'Gửi thất bại'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết')),
      );
    }
  }
}