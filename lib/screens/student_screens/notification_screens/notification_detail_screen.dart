import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../providers/notification_provider_student.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({Key? key, required this.notificationId})
      : super(key: key);

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  PlatformFile? _attachedFile;
  bool _sending = false;
  // Detail state is provided by NotificationsProvider

  @override
  void initState() {
    super.initState();
    // If detail wasn't prefetched by the list, fetch it now via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<NotificationsProvider>(context, listen: false);
      final id = int.tryParse(widget.notificationId);
      if (id != null) {
        final existing = prov.selectedNotification;
        if (existing == null || existing.notificationId != id) {
          prov.fetchDetail(id);
        }
        // mark as read as a best-effort (list may already have done it)
        if (existing != null && !existing.isRead) prov.markAsRead(existing);
      }
    });
  }


  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Không thể mở link')));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachedFile = result.files.first;
      });
    }
  }

  Future<void> _submitFeedback(NotificationModel n) async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung phản hồi')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final payload = {'content': text};
      if (_attachedFile != null) payload['attachment_name'] = _attachedFile!.name;

      await ApiService.instance.respondToNotification(n.notificationId.toString(), payload);

      _feedbackController.clear();
      setState(() => _attachedFile = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gửi ý kiến thành công')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gửi thất bại: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();
    final isLoading = prov.isDetailLoading;
    final error = prov.detailError;
    final n = prov.selectedNotification;
    debugPrint('NotificationDetailScreen.build id=${widget.notificationId} selected=${n?.notificationId} loading=$isLoading error=$error');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
        backgroundColor: AppColors.primary,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Lỗi tải thông báo: $error'))
              : n == null
                  ? const Center(child: Text('Không tìm thấy thông báo'))
                  : _buildContent(context, n),
    );
  }

  Widget _buildContent(BuildContext context, NotificationModel n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.announcement, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Giảng viên: ${n.advisorId ?? 'N/A'}',
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (n.createdAt != null) Text(_formatDate(n.createdAt!)),
          if (n.link != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () => _openLink(n.link!),
                child: Text('Mở liên kết', style: TextStyle(color: AppColors.primary)),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Text(n.summary ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(n.summary ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          if (n.link != null)
            ElevatedButton.icon(
              onPressed: () => _openLink(n.link!),
              icon: const Icon(Icons.link),
              label: const Text('Mở liên kết'),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Gửi ý kiến',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Nhập ý kiến...',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Đính kèm'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _attachedFile?.name ?? 'Chưa có tệp đính kèm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _sending ? null : () => _submitFeedback(n),
                  child: _sending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gửi ý kiến'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                onPressed: () async {
                  final prov =
                      Provider.of<NotificationsProvider>(context, listen: false);
                  await prov.markAsRead(n);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xác nhận đã đọc')),
                  );
                },
                child: const Text('Xác nhận đã đọc'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0)
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
