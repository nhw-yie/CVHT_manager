import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../utils/error_handler.dart';
import '../../../providers/activities_provider.dart';
// migrated to use Theme colors
import '../../../widgets/widgets.dart';

class StudentActivitiesScreen extends StatefulWidget {
  const StudentActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<StudentActivitiesScreen> createState() => _StudentActivitiesScreenState();
}

class _StudentActivitiesScreenState extends State<StudentActivitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _regsLoading = true;
  String? _regsError;
  List<dynamic> _registrations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivitiesProvider>().fetchActivities();
      _fetchMyRegistrations();
    });
  }

  Future<void> _fetchMyRegistrations() async {
    setState(() {
      _regsLoading = true;
      _regsError = null;
    });

    try {
      final resp = await ApiService.instance.myRegistrations();
      final data = resp['data'] ?? resp;
      List regs = [];
      if (data is Map && data['registrations'] is List) {
        regs = data['registrations'] as List;
      } else if (data is List) {
        regs = data;
      }
      setState(() {
        _registrations = regs;
      });
    } catch (e) {
      setState(() {
        _regsError = ErrorHandler.mapToMessage(e);
      });
    } finally {
      setState(() {
        _regsLoading = false;
      });
    }
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
        title: const Text('Hoạt động'),
        actions: [
          IconButton(
            tooltip: 'Xem các hoạt động đã đăng ký',
            onPressed: () => context.push('/student/my-registrations'),
            icon: const Icon(Icons.how_to_reg),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Tất cả'),
            const Tab(text: 'Sắp diễn ra'),
            Tab(text: 'Đã đăng ký' + (_registrations.isNotEmpty ? ' (${_registrations.length})' : '')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllActivitiesTab(),
          _buildUpcomingActivitiesTab(),
          _buildMyRegistrationsTab(),
        ],
      ),
    );
  }

  Widget _buildAllActivitiesTab() {
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
          return const EmptyState(
            icon: Icons.event_busy,
            message: 'Chưa có hoạt động nào',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.activities.length,
            itemBuilder: (context, index) {
              final activity = provider.activities[index];
              return _buildActivityCard(activity);
            },
          ),
        );
      },
    );
  }

  Widget _buildUpcomingActivitiesTab() {
    return Consumer<ActivitiesProvider>(
      builder: (context, provider, _) {
        final upcomingActivities = provider.activities.where((a) {
          return a.status == 'upcoming' && 
                 (a.startTime?.isAfter(DateTime.now()) ?? false);
        }).toList();

        if (upcomingActivities.isEmpty) {
          return const EmptyState(
            icon: Icons.event_available,
            message: 'Không có hoạt động sắp diễn ra',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcomingActivities.length,
            itemBuilder: (context, index) {
              final activity = upcomingActivities[index];
              return _buildActivityCard(activity, showRegisterButton: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyRegistrationsTab() {
    if (_regsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_regsError != null) {
      return ErrorDisplay(message: _regsError!, onRetry: _fetchMyRegistrations);
    }

    if (_registrations.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy,
        message: 'Bạn chưa đăng ký hoạt động nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyRegistrations,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _registrations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = _registrations[index];
          final activityIdField = r['activity_id'] ?? (r['activity'] is Map ? r['activity']['activity_id'] : null);
          final activityId = activityIdField is int ? activityIdField : int.tryParse(activityIdField?.toString() ?? '');
          final title = r['activity_title'] ?? (r['activity'] is Map ? r['activity']['title'] : 'Hoạt động');
          final roleName = r['role_name'] ?? '';
          final status = r['registration_status'] ?? '';
          final startTimeStr = r['activity_start_time'] ?? (r['activity'] is Map ? r['activity']['start_time'] : null);
          DateTime? startTime;
          if (startTimeStr is String) startTime = DateTime.tryParse(startTimeStr);

          return CustomCard(
            onTap: activityId != null ? () => context.push('/student/activities/$activityId') : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Theme.of(context).colorScheme.primary.withOpacity(0.08)),
                      child: Text(status.toString(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (roleName != null) Text('Vai trò: ${roleName.toString()}', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 6),
                Row(children: [Icon(Icons.access_time, size: 14, color: Colors.grey[600]), const SizedBox(width: 6), Text(startTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(startTime) : (r['activity_location'] ?? ''))]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity, {bool showRegisterButton = false}) {
    final startTime = activity.startTime;
    final endTime = activity.endTime;
    final status = activity.status ?? 'upcoming';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => context.push('/student/activities/${activity.activityId}'),
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
          if (showRegisterButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showRegisterDialog(context, activity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đăng ký'),
              ),
            ),
          ],
        ],
      ),
    );

  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color = Theme.of(context).colorScheme.primary;
    String label = 'Không xác định';

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

  void _showRegisterDialog(BuildContext context, dynamic activity) {
    context.push('/student/activities/${activity.activityId}');
  }
}