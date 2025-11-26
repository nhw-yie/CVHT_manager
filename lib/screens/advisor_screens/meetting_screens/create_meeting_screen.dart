// lib/screens/advisor_screens/meeting_screens/create_meeting_screen.dart
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

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _classFeedbackController = TextEditingController();
  final _linkController = TextEditingController();
  final _locationController = TextEditingController();

  int? _selectedClassId;
  DateTime? _meetingTime;
  DateTime? _endTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().fetchClasses(reset: true);
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
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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
    
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lớp')),
      );
      return;
    }

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
        'class_id': _selectedClassId!,
        'title': _titleController.text.trim(),
        'meeting_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(_meetingTime!),
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

      final success = await provider.createMeeting(payload);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo cuộc họp thành công')),
          );
          context.pop();
        } else {
          ErrorHandler.showSnack(context, provider.error ?? 'Có lỗi xảy ra');
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
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tạo cuộc họp mới',
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
                  _buildClassDropdown(),
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
              child: const Text('Tạo cuộc họp'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Consumer<ClassProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LinearProgressIndicator();
        }

        final classes = provider.classes;
        if (classes.isEmpty) {
          return const Text('Không có lớp nào');
        }

        return DropdownButtonFormField<int>(
          value: _selectedClassId,
          decoration: const InputDecoration(
            labelText: 'Chọn lớp',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.class_),
          ),
          items: classes.map((cls) {
            return DropdownMenuItem<int>(
              value: cls.classId,
              child: Text(cls.className),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClassId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Vui lòng chọn lớp';
            }
            return null;
          },
        );
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