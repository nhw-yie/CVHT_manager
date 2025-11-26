// lib/screens/advisor_screens/meeting_screens/advisor_meeting_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/meeting_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/error_handler.dart';

class AdvisorMeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const AdvisorMeetingDetailScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<AdvisorMeetingDetailScreen> createState() => _AdvisorMeetingDetailScreenState();
}

class _AdvisorMeetingDetailScreenState extends State<AdvisorMeetingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetingDetail();
    });
  }

  Future<void> _loadMeetingDetail() async {
    final provider = context.read<MeetingProvider>();
    final id = int.tryParse(widget.meetingId);
    if (id != null) {
      await provider.fetchDetail(id);
      await provider.fetchFeedbacks(id);
    }
  }

  Future<void> _downloadMinutes() async {
    final provider = context.read<MeetingProvider>();
    final meeting = provider.selected;
    if (meeting?.minutesFilePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biên bản chưa được tạo')),
        );
      }
      return;
    }

    try {
      final url = '${ApiService.baseUrl}/meetings/${meeting!.meetingId}/download-minutes';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    }
  }

  Future<void> _exportMinutes() async {
    final provider = context.read<MeetingProvider>();
    final meeting = provider.selected;
    if (meeting == null) return;

    try {
      final url = '${ApiService.baseUrl}/meetings/${meeting.meetingId}/export-minutes';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang xuất biên bản...')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final provider = context.read<MeetingProvider>();
    final id = int.tryParse(widget.meetingId);
    if (id == null) return;

    final success = await provider.updateMeeting(id, {'status': newStatus});
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái: ${_getStatusLabel(newStatus)}')),
        );
      } else {
        ErrorHandler.showSnack(context, provider.error ?? 'Có lỗi xảy ra');
      }
    }
  }

  Future<void> _showUpdateSummaryDialog() async {
    final provider = context.read<MeetingProvider>();
    final meeting = provider.selected;
    if (meeting == null) return;

    final summaryController = TextEditingController(text: meeting.summary);
    final feedbackController = TextEditingController(text: meeting.classFeedback);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật nội dung họp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: summaryController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Nội dung cuộc họp',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ý kiến đóng góp của lớp',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final id = int.tryParse(widget.meetingId);
              if (id != null) {
                final success = await provider.updateMeeting(id, {
                  'summary': summaryController.text.trim(),
                  'class_feedback': feedbackController.text.trim(),
                });
                
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cập nhật thành công')),
                    );
                  } else {
                    ErrorHandler.showSnack(context, provider.error ?? 'Có lỗi xảy ra');
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    summaryController.dispose();
    feedbackController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chi tiết cuộc họp',
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  context.push('/advisor/meetings/edit/${widget.meetingId}');
                  break;
                case 'attendance':
                  context.push('/advisor/meetings/${widget.meetingId}/attendance');
                  break;
                case 'export':
                  _exportMinutes();
                  break;
                case 'complete':
                  _updateStatus('completed');
                  break;
                case 'cancel':
                  _updateStatus('cancelled');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'attendance',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Điểm danh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 20),
                    SizedBox(width: 8),
                    Text('Xuất biên bản'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Đánh dấu hoàn thành'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hủy cuộc họp'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return const LoadingIndicator();
          }

          if (provider.error != null) {
            return ErrorDisplay(
              message: provider.error!,
              onRetry: _loadMeetingDetail,
            );
          }

          final meeting = provider.selected;
          if (meeting == null) {
            return const EmptyState(
              icon: Icons.event_busy,
              message: 'Không tìm thấy cuộc họp',
            );
          }

          return RefreshIndicator(
            onRefresh: _loadMeetingDetail,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _buildHeader(meeting),
                const SizedBox(height: AppSpacing.md),
                _buildInfoSection(meeting),
                const SizedBox(height: AppSpacing.md),
                _buildContentSection(meeting),
                if (meeting.classFeedback != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildClassFeedbackSection(meeting.classFeedback!),
                ],
                const SizedBox(height: AppSpacing.md),
                _buildActionsSection(meeting),
                const SizedBox(height: AppSpacing.md),
                _buildFeedbackSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(meeting) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meeting.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadge(label: _getStatusLabel(meeting.status)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(meeting) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông tin cuộc họp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  context.push('/advisor/meetings/edit/${widget.meetingId}');
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            Icons.calendar_today,
            'Thời gian bắt đầu',
            DateFormat('dd/MM/yyyy HH:mm').format(meeting.meetingTime),
          ),
          if (meeting.endTime != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              Icons.schedule,
              'Thời gian kết thúc',
              DateFormat('dd/MM/yyyy HH:mm').format(meeting.endTime!),
            ),
          ],
          if (meeting.location != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(Icons.location_on, 'Địa điểm', meeting.location!),
          ],
          if (meeting.meetingLink != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(Icons.link, 'Link họp', 'Họp online'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(meeting) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nội dung cuộc họp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: _showUpdateSummaryDialog,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            meeting.summary ?? 'Chưa có nội dung',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildClassFeedbackSection(String feedback) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ý kiến đóng góp của lớp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            feedback,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(meeting) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            onPressed: () {
              context.push('/advisor/meetings/${widget.meetingId}/attendance');
            },
            style: CustomButtonStyle.primary,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 20),
                SizedBox(width: 8),
                Text('Điểm danh sinh viên'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomButton(
            onPressed: _exportMinutes,
            style: CustomButtonStyle.outlined,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_download, size: 20),
                SizedBox(width: 8),
                Text('Xuất biên bản tự động'),
              ],
            ),
          ),
          if (meeting.minutesFilePath != null) ...[
            const SizedBox(height: AppSpacing.sm),
            CustomButton(
              onPressed: _downloadMinutes,
              style: CustomButtonStyle.outlined,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Tải biên bản đã lưu'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(provider) {
    final feedbacks = provider.feedbacks;
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback từ sinh viên (${feedbacks.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (feedbacks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('Chưa có feedback nào'),
              ),
            )
          else
            ...feedbacks.map((feedback) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: AppRadius.base,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            feedback.studentName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feedback.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(feedback.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feedback.feedbackContent,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Sắp diễn ra';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}