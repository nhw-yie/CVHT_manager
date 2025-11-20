import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/models.dart';
import '../providers/activities_provider.dart';
import '../services/api_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({Key? key, required this.activityId}) : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  String? _selectedRoleId;
  bool _isRegistering = false;
  bool _hasRegistered = false;

  Future<Map<String, dynamic>> _fetchDetail() async {
    final resp = await ApiService.instance.getActivityById(widget.activityId);
    // resp commonly contains { data: { ... } }
    final data = resp['data'] ?? resp;
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  }

  void _autoMarkReadIfNeeded(Map<String, dynamic> detail) async {
    // If detail contains notification-like id and unread flag, call mark as read.
    // For activities we may not need this; left as a placeholder.
  }

  Future<void> _onRegister(Activity activity, ActivityRole role, ActivitiesProvider prov) async {
    if (role.maxSlots != null && role.maxSlots! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không còn slot cho vai trò này')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng ký'),
        content: Text('Bạn có chắc muốn đăng ký vai trò "${role.roleName}" cho hoạt động này?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận'))],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRegistering = true);
    // capture UI helpers before the async gap
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final ok = await prov.register({'activity_id': activity.activityId, 'activity_role_id': role.activityRoleId});
    // update state and UI (use captured messenger/nav to avoid using BuildContext after await)
    setState(() => _isRegistering = false);

    if (ok) {
      setState(() => _hasRegistered = true);
      messenger.showSnackBar(const SnackBar(content: Text('Đăng ký thành công')));
      nav.pop(); // go back to list (or you can navigate to My Registrations)
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Đăng ký thất bại')));
    }
  }

  Widget _buildRoleCard(ActivityRole role) {
    final available = role.maxSlots == null ? true : role.maxSlots! > 0;
    final points = role.pointsAwarded?.toString() ?? '-';

    return Card(
      child: RadioListTile<String>(
        value: role.activityRoleId.toString(),
        groupValue: _selectedRoleId,
        onChanged: available ? (v) => setState(() => _selectedRoleId = v) : null,
        title: Row(children: [Text(role.roleName), const SizedBox(width: 8), if (!available) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)), child: const Text('Hết slot', style: TextStyle(fontSize: 12)))]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(role.pointType ?? 'Điểm: $points'), const SizedBox(height: 4), Text('Số slot còn: ${role.maxSlots ?? '-'}')]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ActivitiesProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hoạt động'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'share') {
                // TODO: implement share
              } else if (v == 'report') {
                // TODO: report
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'share', child: Text('Chia sẻ')), PopupMenuItem(value: 'report', child: Text('Báo lỗi'))],
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDetail(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));

          final data = snap.data!;

          // Map API response to Activity model and roles
          Activity activity;
          if (data['id'] != null || data['activity_id'] != null) {
            // try to create Activity from map
            activity = Activity.fromJson(data);
          } else if (data['activity'] != null) {
            activity = Activity.fromJson(Map<String, dynamic>.from(data['activity']));
          } else {
            activity = Activity.fromJson(data);
          }

          final rolesRaw = data['roles'] ?? data['activity_roles'] ?? data['activity_roles_list'] ?? [];
          final List<ActivityRole> roles = [];
          if (rolesRaw is List) {
            for (final e in rolesRaw) {
              if (e is Map<String, dynamic>) roles.add(ActivityRole.fromJson(e));
              else if (e is ActivityRole) roles.add(e);
            }
          }

          final registeredRaw = data['registrations'] ?? data['my_registration'] ?? null;
          _hasRegistered = (_hasRegistered || (registeredRaw != null));

          // Auto mark as read if notification-like
          _autoMarkReadIfNeeded(data);

          return Column(
            children: [
              // Hero image/icon
              Container(
                height: 180,
                width: double.infinity,
                color: AppColors.primaryVariant,
                child: Center(child: Icon(Icons.event, color: Colors.white, size: 72)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Title
                    Text(activity.title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),

                    // Basic info
                    Row(children: [const Icon(Icons.schedule), const SizedBox(width: 8), Text(activity.startTime != null ? '${activity.startTime}' : 'Thời gian chưa rõ')]),
                    const SizedBox(height: 6),
                    Row(children: [const Icon(Icons.location_on), const SizedBox(width: 8), Text(activity.location ?? 'Địa điểm chưa rõ')]),
                    const SizedBox(height: 6),
                    if (activity.status != null) Row(children: [const Icon(Icons.info), const SizedBox(width: 8), Text('Trạng thái: ${activity.status}')]),
                    const SizedBox(height: 12),
                    const Divider(),

                    // Description
                    Text('Mô tả', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(activity.generalDescription ?? 'Không có mô tả'),
                    const SizedBox(height: 12),
                    const Divider(),

                    // Roles
                    Text('Các vai trò tham gia', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (roles.isEmpty) const Text('Không có vai trò') else Column(children: roles.map(_buildRoleCard).toList()),
                    const SizedBox(height: 12),
                    const Divider(),

                    // Registered (placeholder)
                    if (_hasRegistered) ...[
                      Text('Đã đăng ký', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('Bạn đã đăng ký hoạt động này.'),
                    ],
                    const SizedBox(height: 80), // space for bottom button
                  ]),
                ),
              ),

              // Bottom sticky button
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRegistering
                            ? null
                            : () {
                                if (_hasRegistered) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn đã đăng ký')));
                                  return;
                                }
                                if (_selectedRoleId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn vai trò')));
                                  return;
                                }
                                final sel = roles.firstWhere((r) => r.activityRoleId.toString() == _selectedRoleId);
                                _onRegister(activity, sel, prov);
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: _isRegistering ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_hasRegistered ? 'Đã đăng ký' : 'Đăng ký ngay'),
                      ),
                    )
                  ]),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
