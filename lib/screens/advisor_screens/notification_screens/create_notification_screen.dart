// lib/screens/advisor_screens/notification_screens/create_notification_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../models/notification_model.dart';

class CreateNotificationScreen extends StatefulWidget {
  final NotificationModel? notification; // null = create, non-null = edit

  const CreateNotificationScreen({Key? key, this.notification}) : super(key: key);

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _linkController = TextEditingController();

  String _selectedType = 'general';
  final List<int> _selectedClassIds = [];
  
  bool _isLoading = false;
  
  // Mock classes - In real app, fetch from API
  final List<ClassInfo> _availableClasses = [
    ClassInfo(classId: 1, className: 'CNTT-K15A'),
    ClassInfo(classId: 2, className: 'CNTT-K15B'),
    ClassInfo(classId: 3, className: 'KTPM-K15A'),
    ClassInfo(classId: 4, className: 'KHMT-K15A'),
  ];

  @override
  void initState() {
    super.initState();
    
    // If editing, populate fields
    if (widget.notification != null) {
      _titleController.text = widget.notification!.title;
      _summaryController.text = widget.notification!.summary;
      _linkController.text = widget.notification!.link ?? '';
      _selectedType = widget.notification!.type;
      
      if (widget.notification!.classes != null) {
        _selectedClassIds.addAll(
          widget.notification!.classes!.map((c) => c.classId),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.notification != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa thông báo' : 'Tạo thông báo mới'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildSummaryField(),
            const SizedBox(height: 16),
            _buildLinkField(),
            const SizedBox(height: 16),
            _buildClassSelector(),
            const SizedBox(height: 24),
            _buildSubmitButton(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Tiêu đề *',
        hintText: 'Nhập tiêu đề thông báo',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLength: 255,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập tiêu đề';
        }
        return null;
      },
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại thông báo *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _typeChip('Chung', 'general', Icons.info, Colors.grey),
            _typeChip('Học vụ', 'academic', Icons.school, Colors.blue),
            _typeChip('Hoạt động', 'activity', Icons.event, Colors.green),
            _typeChip('Khẩn cấp', 'urgent', Icons.warning, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _typeChip(String label, String value, IconData icon, Color color) {
    final isSelected = _selectedType == value;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = value;
        });
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildSummaryField() {
    return TextFormField(
      controller: _summaryController,
      decoration: InputDecoration(
        labelText: 'Nội dung *',
        hintText: 'Nhập nội dung chi tiết',
        alignLabelWithHint: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: Icon(Icons.description),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 6,
      maxLength: 2000,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập nội dung';
        }
        return null;
      },
    );
  }

  Widget _buildLinkField() {
    return TextFormField(
      controller: _linkController,
      decoration: InputDecoration(
        labelText: 'Liên kết (không bắt buộc)',
        hintText: 'https://example.com',
        prefixIcon: const Icon(Icons.link),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.url,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasScheme) {
            return 'Liên kết không hợp lệ';
          }
        }
        return null;
      },
    );
  }

  Widget _buildClassSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gửi đến lớp *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                _selectedClassIds.length == _availableClasses.length
                    ? 'Bỏ chọn tất cả'
                    : 'Chọn tất cả',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedClassIds.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vui lòng chọn ít nhất một lớp',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _availableClasses.map((classInfo) {
              final isSelected = _selectedClassIds.contains(classInfo.classId);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedClassIds.add(classInfo.classId);
                    } else {
                      _selectedClassIds.remove(classInfo.classId);
                    }
                  });
                },
                title: Text(classInfo.className),
                subtitle: Text('Mã lớp: ${classInfo.classId}'),
                secondary: Icon(
                  Icons.class_,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedClassIds.length == _availableClasses.length) {
        _selectedClassIds.clear();
      } else {
        _selectedClassIds.clear();
        _selectedClassIds.addAll(_availableClasses.map((c) => c.classId));
      }
    });
  }

  Widget _buildSubmitButton(bool isEdit) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isEdit ? 'Cập nhật thông báo' : 'Tạo thông báo',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một lớp'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<AdvisorNotificationsProvider>();
    final isEdit = widget.notification != null;

    bool success;

    if (isEdit) {
      success = await provider.updateNotification(
        notificationId: widget.notification!.notificationId,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        type: _selectedType,
        classIds: _selectedClassIds,
      );
    } else {
      success = await provider.createNotification(
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        type: _selectedType,
        classIds: _selectedClassIds,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Đã cập nhật thông báo' : 'Đã tạo thông báo'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}