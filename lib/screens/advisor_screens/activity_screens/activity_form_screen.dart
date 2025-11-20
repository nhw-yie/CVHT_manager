import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/app_colors.dart';
import '../../../../providers/advisor_activities_provider.dart';
import '../../../../models/models.dart';
import '../../assign_students_screen.dart';

class AdvisorActivityFormScreen extends StatefulWidget {
  final int? activityId;
  const AdvisorActivityFormScreen({Key? key, this.activityId}) : super(key: key);

  @override
  State<AdvisorActivityFormScreen> createState() => _AdvisorActivityFormScreenState();
}

class _AdvisorActivityFormScreenState extends State<AdvisorActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  bool _submitting = false;
  // assignment mode: false => students self-register, true => advisor assigns
  bool _assignByAdvisor = false;
  List<int> _selectedStudentIds = [];
  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    if (widget.activityId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final prov = Provider.of<AdvisorActivitiesProvider>(context, listen: false);
        await prov.fetchDetail(widget.activityId!);
        final a = prov.selected;
        if (a != null) {
          _titleCtrl.text = a.title;
          _descCtrl.text = a.generalDescription ?? '';
          _locationCtrl.text = a.location ?? '';
          _from = a.startTime;
          _to = a.endTime;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final prov = Provider.of<AdvisorActivitiesProvider>(context, listen: false);
    final payload = {
      'title': _titleCtrl.text.trim(),
      'general_description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'start_time': _from?.toIso8601String(),
      'end_time': _to?.toIso8601String(),
    };

    bool ok = false;
    if (widget.activityId == null) {
      List<Map<String, dynamic>>? assignments;
      if (_assignByAdvisor && _selectedStudentIds.isNotEmpty && _selectedRoleId != null) {
        assignments = _selectedStudentIds.map((id) => {
          'student_id': id,
          'activity_role_id': _selectedRoleId,
        }).toList();
      }

      ok = await prov.createActivity(payload, assignByAdvisor: _assignByAdvisor, assignments: assignments);
    } else {
      ok = await prov.updateActivity(widget.activityId!, payload);
    }

    setState(() => _submitting = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu hoạt động thành công')));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.activityId == null ? 'Tạo hoạt động' : 'Chỉnh sửa hoạt động'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề'), validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Tóm tắt'), maxLines: 4),
            const SizedBox(height: 12),
            TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Địa điểm')),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('CVHT phân bổ sinh viên (không cho tự đăng ký)'),
              value: _assignByAdvisor,
              onChanged: (v) => setState(() => _assignByAdvisor = v),
            ),
            if (_assignByAdvisor) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<List<int?>>(MaterialPageRoute(builder: (_) => const AssignStudentsScreen()));
                  if (result != null) {
                    setState(() {
                      _selectedStudentIds = result.whereType<int>().toList();
                    });
                  }
                },
                icon: const Icon(Icons.group_add),
                label: Text(_selectedStudentIds.isEmpty ? 'Chọn sinh viên để phân bổ' : 'Đã chọn ${_selectedStudentIds.length} sinh viên'),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [Expanded(child: Text(_from == null ? 'Chưa chọn ngày bắt đầu' : _from!.toLocal().toString())), const SizedBox(width: 8), ElevatedButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: _from ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650))); if (d != null) setState(() => _from = d); }, child: const Text('Chọn'))]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: Text(_to == null ? 'Chưa chọn ngày kết thúc' : _to!.toLocal().toString())), const SizedBox(width: 8), ElevatedButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: _to ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650))); if (d != null) setState(() => _to = d); }, child: const Text('Chọn'))]),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const CircularProgressIndicator() : const Text('Lưu'))
          ]),
        ),
      ),
    );
  }
}
