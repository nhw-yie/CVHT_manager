import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/advisor_activities_provider.dart';
// removed unused class_provider import
import '../../../constants/app_colors.dart';
import '../../../widgets/widgets.dart';
import '../../../utils/error_handler.dart';
import 'AssignStudentsScreen.dart';
class AdvisorActivityDetailScreen extends StatefulWidget {
  final int activityId;

  const AdvisorActivityDetailScreen({
    Key? key,
    required this.activityId,
  }) : super(key: key);

  @override
  State<AdvisorActivityDetailScreen> createState() => _AdvisorActivityDetailScreenState();
}

class _AdvisorActivityDetailScreenState extends State<AdvisorActivityDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivitiesProvider>();
      provider.fetchDetail(widget.activityId);
      provider.fetchRegistrations(widget.activityId);
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
        title: const Text('Chi tiết Hoạt động'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/advisor/activities/manage/edit/${widget.activityId}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Sinh viên'),
            Tab(text: 'Điểm danh'),
          ],
        ),
      ),
      body: Consumer<ActivitiesProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return ErrorDisplay(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchDetail(widget.activityId),
            );
          }

          if (provider.selected == null) {
            return const EmptyState(
              icon: Icons.event_busy,
              message: 'Không tìm thấy hoạt động',
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(provider),
              _buildStudentsTab(provider),
              _buildAttendanceTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignStudentsDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Phân bổ SV'),
      ),
    );
  }

  Widget _buildInfoTab(ActivitiesProvider provider) {
    final activity = provider.selected!;
    final startTime = activity.startTime;
    final endTime = activity.endTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(activity.status ?? 'upcoming'),
                const SizedBox(height: 16),
                if (activity.generalDescription != null) ...[
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(activity.generalDescription!),
                  const SizedBox(height: 16),
                ],
                _buildInfoRow(
                  Icons.location_on,
                  'Địa điểm',
                  activity.location ?? 'Chưa xác định',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Thời gian',
                  startTime != null
                      ? '${DateFormat('dd/MM/yyyy HH:mm').format(startTime)}${endTime != null ? ' - ${DateFormat('HH:mm').format(endTime)}' : ''}'
                      : 'Chưa xác định',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vai trò trong hoạt động',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildRolesList(provider),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
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

  List<Widget> _buildRolesList(ActivitiesProvider provider) {
    // You'll need to expose roles in the provider
    // For now, returning empty list
    return [
      const CustomCard(
        child: Center(
          child: Text('Chưa có vai trò nào'),
        ),
      ),
    ];
  }

  Widget _buildStudentsTab(ActivitiesProvider provider) {
    final regs = provider.registrations;
    final summary = provider.registrationsSummary;

    if (provider.isLoading && regs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (regs.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        message: 'Chưa có sinh viên nào đăng ký',
        actionLabel: 'Phân bổ sinh viên',
        onAction: () => _showAssignStudentsDialog(context),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary != null) ...[
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng đăng ký: ${summary['total_registrations'] ?? regs.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (summary['by_status'] is Map)
                    Wrap(
                      spacing: 8,
                      children: (summary['by_status'] as Map).entries.map<Widget>((e) {
                        return Chip(label: Text('${e.key}: ${e.value}'));
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: regs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reg = regs[index];
              final studentMap = Map<String, dynamic>.from((reg['student'] ?? reg) as Map);
              final fullName = studentMap['full_name'] ?? studentMap['name'] ?? 'Không tên';
              final userCode = studentMap['user_code'] ?? '';
              final roleName = reg['role_name'] ?? reg['activity_role_name'] ?? '';
              final points = reg['points_awarded']?.toString() ?? '';
              final status = reg['status'] ?? '';
              final regTime = reg['registration_time'] ?? reg['created_at'] ?? '';

              return CustomCard(
                child: ListTile(
                  leading: AvatarWidget(
                    imageUrl: studentMap['avatar_url'] as String?,
                    initials: (fullName is String && fullName.isNotEmpty) ? fullName.substring(0, 1) : '?',
                  ),
                  title: Text(fullName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userCode != null && userCode.isNotEmpty) Text(userCode),
                      if (roleName != null && roleName.toString().isNotEmpty) Text('Vai trò: $roleName'),
                      if (points.isNotEmpty) Text('Điểm: $points'),
                      if (regTime != null && regTime.toString().isNotEmpty) Text('Đăng ký: $regTime'),
                    ],
                  ),
                  trailing: Text(_getRegStatusLabel(status.toString())),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getRegStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Bị từ chối';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status.isNotEmpty ? status : 'Không xác định';
    }
  }

  Widget _buildAttendanceTab(ActivitiesProvider provider) {
    return const Center(
      child: Text('Chức năng điểm danh sẽ được cập nhật sau'),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'upcoming':
        color = AppColors.primary;
        label = 'Sắp diễn ra';
        break;
      case 'ongoing':
        color = AppColors.warning;
        label = 'Đang diễn ra';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Đã hoàn thành';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        label = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAssignStudentsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignStudentsScreen(
          activityId: widget.activityId,
        ),
      ),
    ).then((assigned) {
      if (assigned == true) {
        context.read<ActivitiesProvider>().fetchDetail(widget.activityId);
      }
    });
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hoạt động này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ActivitiesProvider>();
      final success = await provider.deleteActivity(widget.activityId);
      
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa hoạt động thành công')),
        );
      } else if (mounted) {
        ErrorHandler.showSnack(context, provider.errorMessage ?? 'Có lỗi xảy ra');
      }
    }
  }

  // _confirmRemoveStudent removed (unused)
}

// AssignStudentsScreen is implemented in a separate file.