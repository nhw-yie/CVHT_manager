// lib/screens/student_screens/meeting_screens/student_meeting_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/meeting_provider.dart';
import '../../../models/meeting.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';
import '../../../theme/app_theme.dart';

class StudentMeetingListScreen extends StatefulWidget {
  const StudentMeetingListScreen({super.key});

  @override
  State<StudentMeetingListScreen> createState() => _StudentMeetingListScreenState();
}

class _StudentMeetingListScreenState extends State<StudentMeetingListScreen> {
  String _statusFilter = 'all'; // all, scheduled, completed, cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetings();
    });
  }

  Future<void> _loadMeetings() async {
    final provider = context.read<MeetingProvider>();
    await provider.fetchMeetings();
  }

  List<Meeting> _filterMeetings(List<Meeting> meetings) {
    if (_statusFilter == 'all') return meetings;
    return meetings.where((m) => m.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cuộc họp lớp',
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMeetings,
        child: Consumer<MeetingProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.meetings.isEmpty) {
              return const LoadingIndicator();
            }

            if (provider.error != null) {
              return ErrorDisplay(
                message: provider.error!,
                onRetry: _loadMeetings,
              );
            }

            final filteredMeetings = _filterMeetings(provider.meetings);

            if (filteredMeetings.isEmpty) {
              return EmptyState(
                icon: Icons.event_busy,
                message: _statusFilter == 'all' 
                  ? 'Chưa có cuộc họp nào'
                  : 'Không có cuộc họp ${_getStatusLabel(_statusFilter)}',
                actionLabel: 'Tải lại',
                onAction: _loadMeetings,
              );
            }

            return Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredMeetings.length,
                    itemBuilder: (context, index) {
                      return _buildMeetingCard(filteredMeetings[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Tất cả', Icons.list),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('scheduled', 'Sắp diễn ra', Icons.schedule),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('completed', 'Đã hoàn thành', Icons.check_circle),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('cancelled', 'Đã hủy', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CustomCard(
        onTap: () {
          context.push('/student/meetings/${meeting.meetingId}');
        },
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        meeting.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Upcoming indicator: show small red dot if meeting is scheduled and starts within 24 hours
                    Builder(builder: (_) {
                      final now = DateTime.now();
                      final isScheduled = meeting.status == 'scheduled';
                      final startsSoon = meeting.meetingTime.isAfter(now) && meeting.meetingTime.isBefore(now.add(const Duration(hours: 24)));
                      if (isScheduled && startsSoon) {
                        return Container(
                          margin: const EdgeInsets.only(left: 8, right: 8),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 1))],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
              StatusBadge(label: _getStatusLabel(meeting.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            Icons.calendar_today,
            DateFormat('dd/MM/yyyy HH:mm').format(meeting.meetingTime),
          ),
          if (meeting.location != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow(Icons.location_on, meeting.location!),
          ],
          if (meeting.meetingLink != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow(Icons.link, 'Họp online'),
          ],
          if (meeting.minutesFilePath != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.description, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Có biên bản',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
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