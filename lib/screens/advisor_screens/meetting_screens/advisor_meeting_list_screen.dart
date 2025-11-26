// lib/screens/advisor_screens/meeting_screens/advisor_meeting_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/meeting_provider.dart';
import '../../../models/meeting.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/error_handler.dart';

class AdvisorMeetingListScreen extends StatefulWidget {
  const AdvisorMeetingListScreen({super.key});

  @override
  State<AdvisorMeetingListScreen> createState() => _AdvisorMeetingListScreenState();
}

class _AdvisorMeetingListScreenState extends State<AdvisorMeetingListScreen> {
  String _statusFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetings();
    });
  }

  Future<void> _loadMeetings() async {
    final provider = context.read<MeetingProvider>();
    final query = <String, dynamic>{};
    
    if (_statusFilter != 'all') {
      query['status'] = _statusFilter;
    }
    if (_fromDate != null) {
      query['from_date'] = DateFormat('yyyy-MM-dd').format(_fromDate!);
    }
    if (_toDate != null) {
      query['to_date'] = DateFormat('yyyy-MM-dd').format(_toDate!);
    }
    
    await provider.fetchMeetings(query: query.isEmpty ? null : query);
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Lọc cuộc họp'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Từ ngày'),
                  subtitle: Text(_fromDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                    : 'Chưa chọn'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _fromDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('Đến ngày'),
                  subtitle: Text(_toDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_toDate!)
                    : 'Chưa chọn'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _toDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
              },
              child: const Text('Xóa bộ lọc'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {});
                _loadMeetings();
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Meeting meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa cuộc họp "${meeting.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<MeetingProvider>();
      final success = await provider.deleteMeeting(meeting.meetingId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa cuộc họp thành công')),
          );
        } else {
          ErrorHandler.showSnack(context, provider.error ?? 'Có lỗi xảy ra');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quản lý cuộc họp',
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
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

            if (provider.meetings.isEmpty) {
              return EmptyState(
                icon: Icons.event_busy,
                message: 'Chưa có cuộc họp nào',
                actionLabel: 'Tạo cuộc họp',
                onAction: () => context.push('/advisor/meetings/create'),
              );
            }

            return Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: provider.meetings.length,
                    itemBuilder: (context, index) {
                      return _buildMeetingCard(provider.meetings[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/advisor/meetings/create'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo cuộc họp'),
        backgroundColor: AppColors.primary,
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
        _loadMeetings();
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
          context.push('/advisor/meetings/${meeting.meetingId}');
        },
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meeting.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: AppColors.primary),
                onPressed: () {
                  context.push('/advisor/meetings/edit/${meeting.meetingId}');
                },
                tooltip: 'Chỉnh sửa',
              ),
              IconButton(
                icon: Icon(Icons.people, size: 20, color: AppColors.primary),
                onPressed: () {
                  context.push('/advisor/meetings/${meeting.meetingId}/attendance');
                },
                tooltip: 'Điểm danh',
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20, color: AppColors.error),
                onPressed: () => _confirmDelete(meeting),
                tooltip: 'Xóa',
              ),
            ],
          ),
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