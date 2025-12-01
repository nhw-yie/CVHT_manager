import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
// import '../../../constants/app_colors.dart'; // migrated to Theme usage
import '../../../widgets/widgets.dart';
import '../../../utils/error_handler.dart';

class StudentActivityDetailScreen extends StatefulWidget {
  final int activityId;

  const StudentActivityDetailScreen({
    Key? key,
    required this.activityId,
  }) : super(key: key);

  @override
  State<StudentActivityDetailScreen> createState() => _StudentActivityDetailScreenState();
}

class _StudentActivityDetailScreenState extends State<StudentActivityDetailScreen> {
  final ApiService _api = ApiService.instance;
  
  bool _isLoading = true;
  String? _errorMessage;
  
  Activity? _activity;
  List<dynamic> _roles = [];
  
  // Student registration status
  int? _studentRegistrationId;
  String? _studentRegistrationStatus;
  String? _registeredRoleName;

  @override
  void initState() {
    super.initState();
    _loadActivityDetail();
  }

  Future<void> _loadActivityDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resp = await _api.getActivityById(widget.activityId.toString());
      final data = resp['data'] ?? resp;
      
      if (data is Map<String, dynamic>) {
        _activity = Activity.fromJson(data);
        
        // Parse roles with student registration status
        if (data['roles'] is List) {
          _roles = data['roles'];
          
          // Check if student has registered
          for (var role in _roles) {
            if (role['student_registration_id'] != null) {
              _studentRegistrationId = role['student_registration_id'];
              _studentRegistrationStatus = role['student_registration_status'];
              _registeredRoleName = role['role_name']?.toString();
              break;
            }
          }
        }
      }
      // If not found in activity.roles, call the student's registrations endpoint
      if (_studentRegistrationId == null) {
        try {
          final myRegsResp = await _api.myRegistrations();
          final myData = myRegsResp['data'] ?? myRegsResp;
          List regs = [];
          if (myData is Map && myData['registrations'] is List) {
            regs = myData['registrations'] as List;
          } else if (myData is List) {
            regs = myData;
          }
          for (final r in regs) {
            if (r is Map) {
              final activityIdField = r['activity_id'] ?? (r['activity'] is Map ? r['activity']['activity_id'] : null);
              final parsedActivityId = activityIdField is int ? activityIdField : int.tryParse(activityIdField?.toString() ?? '');
              if (parsedActivityId == widget.activityId) {
                _studentRegistrationId = r['registration_id'] is int ? r['registration_id'] : int.tryParse(r['registration_id']?.toString() ?? '');
                _studentRegistrationStatus = r['registration_status']?.toString();
                _registeredRoleName = r['role_name']?.toString();
                break;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('myRegistrations error: $e');
        }
      }
    } catch (e) {
      _errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết Hoạt động')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết Hoạt động')),
        body: ErrorDisplay(
          message: _errorMessage!,
          onRetry: _loadActivityDetail,
        ),
      );
    }

    if (_activity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết Hoạt động')),
        body: const EmptyState(
          icon: Icons.event_busy,
          message: 'Không tìm thấy hoạt động',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Hoạt động'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityHeader(),
            _buildActivityInfo(),
            _buildRolesList(),
            _buildRegistrationStatus(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildActivityHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.7)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activity!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(_activity!.status ?? 'upcoming'),
        ],
      ),
    );
  }

  Widget _buildActivityInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activity!.generalDescription != null) ...[
              const Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_activity!.generalDescription!),
              const Divider(height: 24),
            ],
            _buildInfoRow(
              Icons.location_on,
              'Địa điểm',
              _activity!.location ?? 'Chưa xác định',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Thời gian bắt đầu',
              _activity!.startTime != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(_activity!.startTime!)
                  : 'Chưa xác định',
            ),
            if (_activity!.endTime != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time,
                'Thời gian kết thúc',
                DateFormat('dd/MM/yyyy HH:mm').format(_activity!.endTime!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRolesList() {
    if (_roles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CustomCard(
          child: Center(
            child: Text('Chưa có vai trò nào'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vai trò trong hoạt động',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._roles.map((role) => _buildRoleCard(role)).toList(),
        ],
      ),
    );
  }

  Widget _buildRoleCard(dynamic role) {
    final roleName = role['role_name'] ?? '';
    final pointsAwarded = role['points_awarded'] ?? 0;
    final pointType = role['point_type'] ?? 'ctxh';
    final maxSlots = role['max_slots'];
    final registrationsCount = role['registrations_count'] ?? 0;
    final availableSlots = role['available_slots'];

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  roleName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pointType == 'ctxh'
                      ? Theme.of(context).colorScheme.tertiary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$pointsAwarded điểm ${pointType == 'ctxh' ? 'CTXH' : 'Rèn luyện'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pointType == 'ctxh' ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (role['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              role['description'],
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          if (role['requirements'] != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Yêu cầu: ${role['requirements']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                maxSlots != null
                    ? 'Đã đăng ký: $registrationsCount/$maxSlots (còn ${availableSlots ?? 0} chỗ)'
                    : 'Đã đăng ký: $registrationsCount',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationStatus() {
    if (_studentRegistrationId == null) return const SizedBox.shrink();

    String statusText;
    Color statusColor;

    switch (_studentRegistrationStatus) {
      case 'registered':
        statusText = 'Đã đăng ký';
        statusColor = Theme.of(context).colorScheme.primary;
        break;
      case 'attended':
        statusText = 'Đã tham gia';
        statusColor = Theme.of(context).colorScheme.tertiary;
        break;
      case 'absent':
        statusText = 'Vắng mặt';
        statusColor = Theme.of(context).colorScheme.error;
        break;
      case 'cancelled':
        statusText = 'Đã hủy';
        statusColor = Colors.grey;
        break;
      default:
        statusText = 'Không xác định';
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomCard(
        color: statusColor.withOpacity(0.1),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái đăng ký',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    statusText + (_registeredRoleName != null ? ' • Vai trò: ${_registeredRoleName!}' : ''),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomBar() {
    // Don't show register button if already registered or activity is not upcoming
    if (_studentRegistrationId != null || _activity!.status != 'upcoming') {
      return null;
    }

    // Don't show if activity has already started
    if (_activity!.startTime != null && _activity!.startTime!.isBefore(DateTime.now())) {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          onPressed: () => _showRegisterDialog(),
          style: CustomButtonStyle.primary,
          child: const Text('Đăng ký tham gia'),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'upcoming':
        color = Colors.white;
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status == 'upcoming' ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
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

  void _showRegisterDialog() {
    if (_roles.isEmpty) {
      ErrorHandler.showSnack(context, 'Chưa có vai trò nào để đăng ký');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn vai trò'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _roles.map((role) {
            final roleName = role['role_name'] ?? '';
            final pointsAwarded = role['points_awarded'] ?? 0;
            final pointType = role['point_type'] ?? 'ctxh';
            final availableSlots = role['available_slots'];

            final isAvailable = availableSlots == null || availableSlots > 0;

            return ListTile(
              title: Text(roleName),
              subtitle: Text(
                '$pointsAwarded điểm ${pointType == 'ctxh' ? 'CTXH' : 'Rèn luyện'}${availableSlots != null ? ' - Còn $availableSlots chỗ' : ''}',
              ),
              enabled: isAvailable,
              onTap: isAvailable
                  ? () {
                      Navigator.pop(context);
                      _registerForRole(role['activity_role_id']);
                    }
                  : null,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerForRole(int roleId) async {
    setState(() => _isLoading = true);

    try {
      await _api.registerActivity({'activity_role_id': roleId});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đăng ký thành công!'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        
        // Reload activity detail
        await _loadActivityDetail();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}