// lib/screens/advisor_screens/meeting_screens/edit_meeting_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/meeting_provider.dart';
import '../../../providers/class_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/error_handler.dart';

class EditMeetingScreen extends StatefulWidget {
  final String meetingId;

  const EditMeetingScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<EditMeetingScreen> createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends State<EditMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _classFeedbackController = TextEditingController();
  final _linkController = TextEditingController();
  final _locationController = TextEditingController();

  int? _selectedClassId;
  DateTime? _meetingTime;
  DateTime? _endTime;
  String _status = 'scheduled';
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetingData();
    });
  }

  Future<void> _loadMeetingData() async {
    final provider = context.read<MeetingProvider>();
    final classProvider = context.read<ClassProvider>();
    
    await classProvider.fetchClasses(reset: true);
    
    final id = int.tryParse(widget.meetingId);
    if (id != null) {
      await provider.fetchDetail(id);
      
      final meeting = provider.selected;
      if (meeting != null) {
        _titleController.text = meeting.title;
        _summaryController.text = meeting.summary ?? '';
        _classFeedbackController.text = meeting.classFeedback ?? '';
        _linkController.text = meeting.meetingLink ?? '';
        _locationController.text = meeting.location ?? '';
        _selectedClassId = meeting.classId;
        _meetingTime = meeting.meetingTime;
        _endTime = meeting.endTime;
        _status = meeting.status;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _classFeedbackController.dispose();
    _linkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isEndTime) async {
    final initialDate = isEndTime 
      ? (_endTime ?? _meetingTime ?? DateTime.now())
      : (_meetingTime ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isEndTime) {
            _endTime = dateTime;
          } else {
            _meetingTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_meetingTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian họp')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<MeetingProvider>();
      final id = int.tryParse(widget.meetingId);
      
      if (id != null) {
        // validate meeting link if provided
        String? meetingLink;
        if (_linkController.text.trim().isNotEmpty) {
          meetingLink = _linkController.text.trim();
          final uri = Uri.tryParse(meetingLink);
          if (uri == null || !uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link họp không hợp lệ. Vui lòng nhập URL bắt đầu bằng https://')),
            );
            setState(() => _isSubmitting = false);
            return;
          }
        }

        final payload = {
          'title': _titleController.text.trim(),
          'meeting_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(_meetingTime!),
          'status': _status,
        };

        if (_summaryController.text.trim().isNotEmpty) {
          payload['summary'] = _summaryController.text.trim();
        }

        if (_classFeedbackController.text.trim().isNotEmpty) {
          payload['class_feedback'] = _classFeedbackController.text.trim();
        }

        if (meetingLink != null) {
          payload['meeting_link'] = meetingLink;
        }

        if (_locationController.text.trim().isNotEmpty) {
          payload['location'] = _locationController.text.trim();
        }

        if (_endTime != null) {
          payload['end_time'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(_endTime!);
        }

        final success = await provider.updateMeeting(id, payload);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật cuộc họp thành công')),
            );
            context.pop();
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Chỉnh sửa cuộc họp',
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
        body: const LoadingIndicator(),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chỉnh sửa cuộc họp',
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin cơ bản',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildClassInfo(),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _titleController,
                    label: 'Tiêu đề cuộc họp',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStatusDropdown(),
                  const SizedBox(height: AppSpacing.md),
                  _buildDateTimeField(
                    label: 'Thời gian bắt đầu',
                    value: _meetingTime,
                    onTap: () => _selectDateTime(false),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDateTimeField(
                    label: 'Thời gian kết thúc (tùy chọn)',
                    value: _endTime,
                    onTap: () => _selectDateTime(true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Địa điểm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _locationController,
                    label: 'Địa điểm (tùy chọn)',
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _linkController,
                    label: 'Link họp online (tùy chọn)',
                    prefixIcon: const Icon(Icons.link),
                    hint: 'https://meet.google.com/...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nội dung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _summaryController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung cuộc họp (tùy chọn)',
                      hintText: 'Nhập nội dung cuộc họp...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _classFeedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ý kiến đóng góp của lớp (tùy chọn)',
                      hintText: 'Nhập ý kiến đóng góp...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
              style: CustomButtonStyle.primary,
              child: const Text('Cập nhật cuộc họp'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfo() {
    return Consumer<ClassProvider>(
      builder: (context, provider, _) {
        final selectedClass = provider.classes.firstWhere(
          (c) => c.classId == _selectedClassId,
          orElse: () => provider.classes.first,
        );

        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: AppRadius.base,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.class_, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Lớp: ${selectedClass.className}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Trạng thái',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.info),
      ),
      items: const [
        DropdownMenuItem(value: 'scheduled', child: Text('Sắp diễn ra')),
        DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
        DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _status = value;
          });
        }
      },
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      if (label.contains('kết thúc')) {
                        _endTime = null;
                      } else {
                        _meetingTime = null;
                      }
                    });
                  },
                )
              : null,
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(value)
              : 'Chọn thời gian',
          style: TextStyle(
            color: value != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}