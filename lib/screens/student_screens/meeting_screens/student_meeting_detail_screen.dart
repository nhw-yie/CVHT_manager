// lib/screens/student_screens/meeting_screens/student_meeting_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/meeting_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/error_handler.dart';

class StudentMeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const StudentMeetingDetailScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<StudentMeetingDetailScreen> createState() => _StudentMeetingDetailScreenState();
}

class _StudentMeetingDetailScreenState extends State<StudentMeetingDetailScreen> {
  final _feedbackController = TextEditingController();
  bool _isSubmittingFeedback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetingDetail();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
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
      // Construct download URL - adjust based on your API structure
      final url = 'https://your-api-domain.com/api/meetings/${meeting!.meetingId}/download-minutes';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    }
  }

  Future<void> _joinOnlineMeeting() async {
    final provider = context.read<MeetingProvider>();
    final link = provider.selected?.meetingLink;
    if (link == null) return;

    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung feedback')),
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      final provider = context.read<MeetingProvider>();
      final id = int.tryParse(widget.meetingId);
      if (id != null) {
        final success = await provider.submitFeedback(id, {
          'feedback_content': _feedbackController.text.trim(),
        });

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gửi feedback thành công')),
            );
            _feedbackController.clear();
            FocusScope.of(context).unfocus();
          } else {
            ErrorHandler.showSnack(context, provider.error ?? 'Có lỗi xảy ra');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chi tiết cuộc họp',
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: AppSpacing.md),
                  _buildFeedbackForm(),
                ],
              ),
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
          Text(
            'Thông tin cuộc họp',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
            _buildInfoRow(Icons.link, 'Link họp', 'Họp online', onTap: _joinOnlineMeeting),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onTap != null ? AppColors.primary : Colors.black87,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(meeting) {
    if (meeting.summary == null) return const SizedBox.shrink();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nội dung cuộc họp',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            meeting.summary!,
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
          if (meeting.meetingLink != null)
            CustomButton(
              onPressed: _joinOnlineMeeting,
              style: CustomButtonStyle.primary,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_call, size: 20),
                  SizedBox(width: 8),
                  Text('Tham gia họp online'),
                ],
              ),
            ),
          if (meeting.minutesFilePath != null) ...[
            if (meeting.meetingLink != null) const SizedBox(height: AppSpacing.sm),
            CustomButton(
              onPressed: _downloadMinutes,
              style: CustomButtonStyle.outlined,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Tải biên bản họp'),
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
    if (feedbacks.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback từ lớp (${feedbacks.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...feedbacks.map((feedback) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          feedback.studentName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedback.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM HH:mm').format(feedback.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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

  Widget _buildFeedbackForm() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gửi feedback của bạn',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Nhập nội dung feedback...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomButton(
            onPressed: _isSubmittingFeedback ? null : _submitFeedback,
            isLoading: _isSubmittingFeedback,
            style: CustomButtonStyle.primary,
            child: const Text('Gửi feedback'),
          ),
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