import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/advisor_activities_provider.dart';
import '../../../providers/class_provider.dart';
// removed unused models import
import '../../../constants/app_colors.dart';
import '../../../widgets/widgets.dart';
import '../../../utils/error_handler.dart';

class CreateActivityScreen extends StatefulWidget {
  final int? activityId; // null = create, non-null = edit

  const CreateActivityScreen({Key? key, this.activityId}) : super(key: key);

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  String _status = 'upcoming';
  final Set<int> _selectedClasses = {};
  
  // Roles
  final List<Map<String, dynamic>> _roles = [];

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.activityId != null;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().fetchClasses(reset: true);
      if (_isEditMode) {
        _loadActivityData();
      } else {
        _addDefaultRole();
      }
    });
  }

  Future<void> _loadActivityData() async {
    setState(() => _isLoading = true);
    
    try {
      await context.read<ActivitiesProvider>().fetchDetail(widget.activityId!);
      final activity = context.read<ActivitiesProvider>().selected;
      
      if (activity != null) {
      _titleController.text = activity.title;
        _descriptionController.text = activity.generalDescription ?? '';
        _locationController.text = activity.location ?? '';
        _startTime = activity.startTime;
        _endTime = activity.endTime;
        _status = activity.status ?? 'upcoming';
        
        // TODO: Load selected classes and roles
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnack(context, e);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addDefaultRole() {
    _roles.add({
      'role_name': '',
      'description': '',
      'requirements': '',
      'points_awarded': 0,
      'point_type': 'ctxh',
      'max_slots': null,
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa hoạt động' : 'Tạo hoạt động mới'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildTimeSection(),
                  const SizedBox(height: 24),
                  _buildClassSelectionSection(),
                  const SizedBox(height: 24),
                  _buildRolesSection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cơ bản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Tên hoạt động *',
            controller: _titleController,
            validator: (v) =>
                v?.isEmpty ?? true ? 'Vui lòng nhập tên hoạt động' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Mô tả',
            controller: _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Địa điểm',
            controller: _locationController,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'upcoming', child: Text('Sắp diễn ra')),
              DropdownMenuItem(value: 'ongoing', child: Text('Đang diễn ra')),
              DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
              DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thời gian',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDateTimePicker(
            label: 'Thời gian bắt đầu *',
            value: _startTime,
            onChanged: (dt) => setState(() => _startTime = dt),
          ),
          const SizedBox(height: 16),
          _buildDateTimePicker(
            label: 'Thời gian kết thúc',
            value: _endTime,
            onChanged: (dt) => setState(() => _endTime = dt),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
          );

          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(value)
              : 'Chọn thời gian',
        ),
      ),
    );
  }

  Widget _buildClassSelectionSection() {
    return Consumer<ClassProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn lớp tham gia *',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (provider.classes.isEmpty)
                const Text('Không có lớp nào')
              else
                ...provider.classes.map((cls) {
                  final isSelected = _selectedClasses.contains(cls.classId);
                  return CheckboxListTile(
                    title: Text(cls.className),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedClasses.add(cls.classId);
                        } else {
                          _selectedClasses.remove(cls.classId);
                        }
                      });
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRolesSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vai trò trong hoạt động *',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  setState(() {
                    _roles.add({
                      'role_name': '',
                      'description': '',
                      'requirements': '',
                      'points_awarded': 0,
                      'point_type': 'ctxh',
                      'max_slots': null,
                    });
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._roles.asMap().entries.map((entry) {
            final index = entry.key;
            return _buildRoleItem(index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRoleItem(int index) {
    final role = _roles[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vai trò ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_roles.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _roles.removeAt(index));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: role['role_name'],
              decoration: const InputDecoration(
                labelText: 'Tên vai trò *',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => role['role_name'] = v,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Vui lòng nhập tên vai trò' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: role['description'],
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (v) => role['description'] = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: role['points_awarded'].toString(),
                    decoration: const InputDecoration(
                      labelText: 'Điểm *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        role['points_awarded'] = int.tryParse(v) ?? 0,
                    validator: (v) {
                      final points = int.tryParse(v ?? '');
                      if (points == null || points < 0) {
                        return 'Điểm không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: role['point_type'],
                    decoration: const InputDecoration(
                      labelText: 'Loại điểm',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ctxh', child: Text('CTXH')),
                      DropdownMenuItem(
                          value: 'ren_luyen', child: Text('Rèn luyện')),
                    ],
                    onChanged: (v) {
                      if (v != null) role['point_type'] = v;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: role['max_slots']?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Số lượng tối đa (để trống nếu không giới hạn)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                role['max_slots'] = v.isEmpty ? null : int.tryParse(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      onPressed: _isLoading ? null : _handleSubmit,
      isLoading: _isLoading,
      child: Text(_isEditMode ? 'Cập nhật' : 'Tạo hoạt động'),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null) {
      ErrorHandler.showSnack(context, 'Vui lòng chọn thời gian bắt đầu');
      return;
    }

    if (_selectedClasses.isEmpty) {
      ErrorHandler.showSnack(context, 'Vui lòng chọn ít nhất một lớp');
      return;
    }

    if (_roles.isEmpty) {
      ErrorHandler.showSnack(context, 'Vui lòng thêm ít nhất một vai trò');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'title': _titleController.text,
        'general_description': _descriptionController.text,
        'location': _locationController.text,
        'start_time': _startTime!.toIso8601String(),
        'end_time': _endTime?.toIso8601String(),
        'status': _status,
        'class_ids': _selectedClasses.toList(),
        'roles': _roles,
      };

      final provider = context.read<ActivitiesProvider>();
      bool success;

      if (_isEditMode) {
        success = await provider.updateActivity(widget.activityId!, payload);
      } else {
        success = await provider.createActivity(payload);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Cập nhật hoạt động thành công'
                  : 'Tạo hoạt động thành công',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ErrorHandler.showSnack(context, provider.errorMessage ?? 'Có lỗi xảy ra');
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