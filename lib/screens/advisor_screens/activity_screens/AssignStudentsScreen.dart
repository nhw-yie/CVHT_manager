import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/widgets.dart';
import '../../../utils/error_handler.dart';
class AssignStudentsScreen extends StatefulWidget {
  final int activityId;

  const AssignStudentsScreen({
    Key? key,
    required this.activityId,
  }) : super(key: key);

  @override
  State<AssignStudentsScreen> createState() => _AssignStudentsScreenState();
}

class _AssignStudentsScreenState extends State<AssignStudentsScreen> {
  final ApiService _api = ApiService.instance;
  
  bool _isLoading = true;
  String? _errorMessage;
  
  Map<String, dynamic>? _activityData;
  List<dynamic> _availableStudents = [];
  List<dynamic> _unavailableStudents = [];
  List<ActivityRole> _roles = [];
  
  // Selected students for assignment
  final Map<int, int> _selectedAssignments = {}; // studentId -> roleId
  
  // Filter options
  int? _selectedClassFilter;
  int? _minTrainingPoint;
  int? _maxTrainingPoint;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableStudents();
  }

  Future<void> _loadAvailableStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch activity detail to get roles
      final activityResp = await _api.getActivityById(widget.activityId.toString());
      final activityData = activityResp['data'] ?? activityResp;
      
      if (activityData is Map<String, dynamic>) {
        _activityData = activityData;
        
        // Parse roles
        if (activityData['roles'] is List) {
          _roles = (activityData['roles'] as List)
              .map((e) => ActivityRole.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      // Fetch available students
      final studentsResp = await _api.getAvailableStudents(
        widget.activityId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        classId: _selectedClassFilter,
        minTrainingPoint: _minTrainingPoint,
        maxTrainingPoint: _maxTrainingPoint,
      );

      final data = studentsResp['data'] ?? studentsResp;
      if (data is Map) {
        _availableStudents = data['available_students'] ?? [];
        _unavailableStudents = data['unavailable_students'] ?? [];
      }
    } catch (e) {
      _errorMessage = ErrorHandler.mapToMessage(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignStudents() async {
    if (_selectedAssignments.isEmpty) {
      ErrorHandler.showSnack(context, 'Vui lòng chọn ít nhất một sinh viên');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assignments = _selectedAssignments.entries
          .map((e) => {
                'student_id': e.key,
                'activity_role_id': e.value,
              })
          .toList();

      // capture UI helpers before async gap
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      await _api.assignStudentsToActivity(widget.activityId, assignments);

      if (mounted) {
        nav.pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Đã phân bổ ${assignments.length} sinh viên'),
            backgroundColor: AppColors.success,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân bổ sinh viên'),
        actions: [
          if (_selectedAssignments.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _assignStudents,
              child: Text(
                'Phân bổ (${_selectedAssignments.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading && _availableStudents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ErrorDisplay(
                  message: _errorMessage!,
                  onRetry: _loadAvailableStudents,
                )
              : Column(
                  children: [
                    _buildFilterSection(),
                    _buildSummaryCard(),
                    Expanded(child: _buildStudentsList()),
                  ],
                ),
    );
  }

  Widget _buildFilterSection() {
    return CustomCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm sinh viên...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            onSubmitted: (_) => _loadAvailableStudents(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _minTrainingPoint,
                  decoration: const InputDecoration(
                    labelText: 'Điểm rèn luyện tối thiểu',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    ...List.generate(10, (i) => (i + 1) * 10)
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('$p điểm'),
                            )),
                  ],
                  onChanged: (value) {
                    setState(() => _minTrainingPoint = value);
                    _loadAvailableStudents();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loadAvailableStudents,
                icon: const Icon(Icons.filter_list),
                label: const Text('Lọc'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Có thể phân bổ',
            _availableStudents.length.toString(),
            AppColors.success,
          ),
          _buildSummaryItem(
            'Không khả dụng',
            _unavailableStudents.length.toString(),
            AppColors.error,
          ),
          _buildSummaryItem(
            'Đã chọn',
            _selectedAssignments.length.toString(),
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList() {
    if (_availableStudents.isEmpty && _unavailableStudents.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        message: 'Không có sinh viên nào',
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Có thể phân bổ'),
              Tab(text: 'Không khả dụng'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableStudentsList(),
                _buildUnavailableStudentsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableStudentsList() {
    if (_availableStudents.isEmpty) {
      return const EmptyState(
        icon: Icons.person_off,
        message: 'Không có sinh viên khả dụng',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableStudents.length,
      itemBuilder: (context, index) {
        final student = _availableStudents[index];
        final studentId = student['student_id'] as int;
        final isSelected = _selectedAssignments.containsKey(studentId);

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          child: Column(
            children: [
              ListTile(
                leading: AvatarWidget(
                  imageUrl: student['avatar_url'],
                  initials: (student['full_name'] as String).substring(0, 1),
                ),
                title: Text(student['full_name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MSSV: ${student['user_code']}'),
                    Text('Lớp: ${student['class_name']}'),
                    Text(
                      'Điểm RL: ${student['training_point'] ?? 0} | CTXH: ${student['social_point'] ?? 0}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        if (_roles.isNotEmpty) {
                          _selectedAssignments[studentId] = _roles.first.activityRoleId;
                        }
                      } else {
                        _selectedAssignments.remove(studentId);
                      }
                    });
                  },
                ),
              ),
              if (isSelected && _roles.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Vai trò: '),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedAssignments[studentId],
                          items: _roles
                              .map((role) => DropdownMenuItem(
                                    value: role.activityRoleId,
                                    child: Text(
                                      '${role.roleName} (${role.pointsAwarded} điểm)',
                                    ),
                                  ))
                              .toList(),
                          onChanged: (roleId) {
                            if (roleId != null) {
                              setState(() {
                                _selectedAssignments[studentId] = roleId;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnavailableStudentsList() {
    if (_unavailableStudents.isEmpty) {
      return const Center(
        child: Text('Tất cả sinh viên đều có thể phân bổ'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unavailableStudents.length,
      itemBuilder: (context, index) {
        final student = _unavailableStudents[index];

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey[100],
          child: ListTile(
            leading: AvatarWidget(
              imageUrl: student['avatar_url'],
              initials: (student['full_name'] as String).substring(0, 1),
            ),
            title: Text(student['full_name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MSSV: ${student['user_code']}'),
                Text('Lớp: ${student['class_name']}'),
                const SizedBox(height: 4),
                Text(
                  student['reason_cannot_assign'] ?? 'Không khả dụng',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}