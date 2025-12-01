import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/advisor_activities_provider.dart';
// import '../../../constants/app_colors.dart'; // migrated to Theme usage
import '../../../widgets/widgets.dart';

class AdvisorActivitiesListScreen extends StatefulWidget {
  const AdvisorActivitiesListScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorActivitiesListScreen> createState() => _AdvisorActivitiesListScreenState();
}

class _AdvisorActivitiesListScreenState extends State<AdvisorActivitiesListScreen> {
  String _selectedFilter = 'all'; // all, upcoming, ongoing, completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivitiesProvider>().fetchActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Hoạt động'),
        actions: [
              IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/advisor/activities/manage/create').then((_) {
              context.read<ActivitiesProvider>().fetchActivities();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildActivitiesList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Sắp diễn ra', 'upcoming'),
            const SizedBox(width: 8),
            _buildFilterChip('Đang diễn ra', 'ongoing'),
            const SizedBox(width: 8),
            _buildFilterChip('Đã hoàn thành', 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        // TODO: Implement filtering logic
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildActivitiesList() {
    return Consumer<ActivitiesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.activities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return ErrorDisplay(
            message: provider.errorMessage!,
            onRetry: () => provider.fetchActivities(),
          );
        }

        if (provider.activities.isEmpty) {
          return EmptyState(
            icon: Icons.event_busy,
            message: 'Chưa có hoạt động nào',
            actionLabel: 'Tạo hoạt động mới',
            onAction: () => context.push('/advisor/activities/manage/create'),
          );
        }

        // Filter activities based on selected filter
        final filteredActivities = provider.activities.where((activity) {
          if (_selectedFilter == 'all') return true;
          return activity.status == _selectedFilter;
        }).toList();

        if (filteredActivities.isEmpty) {
          return EmptyState(
            icon: Icons.filter_list_off,
            message: 'Không có hoạt động nào phù hợp',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchActivities(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredActivities.length,
            itemBuilder: (context, index) {
              final activity = filteredActivities[index];
              return _buildActivityCard(activity);
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final startTime = activity.startTime;
    final endTime = activity.endTime;
    final status = activity.status ?? 'upcoming';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => context.push('/advisor/activities/manage/${activity.activityId}').then((_) {
        context.read<ActivitiesProvider>().fetchActivities();
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.title ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(context, status),
            ],
          ),
          if (activity.generalDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              activity.generalDescription!,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activity.location ?? 'Chưa xác định',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                startTime != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(startTime)
                    : 'Chưa xác định',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              if (endTime != null) ...[
                Text(' - ', style: TextStyle(color: Colors.grey[600])),
                Text(
                  DateFormat('HH:mm').format(endTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/advisor/activities/manage/${activity.activityId}'),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Xem chi tiết'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => context.push('/advisor/activities/manage/edit/${activity.activityId}'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Sửa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'upcoming':
        color = Theme.of(context).colorScheme.primary;
        label = 'Sắp diễn ra';
        break;
      case 'ongoing':
        color = Theme.of(context).colorScheme.secondary;
        label = 'Đang diễn ra';
        break;
      case 'completed':
        color = Theme.of(context).colorScheme.tertiary;
        label = 'Đã hoàn thành';
        break;
      case 'cancelled':
        color = Theme.of(context).colorScheme.error;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        label = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}