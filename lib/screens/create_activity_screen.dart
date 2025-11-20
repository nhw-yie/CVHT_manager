import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({Key? key}) : super(key: key);

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  String? _organizer;

  final List<Map<String, dynamic>> _roles = [];

  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _fromDate ?? now, firstDate: DateTime(now.year - 2), lastDate: DateTime(now.year + 5));
    if (picked != null && mounted) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _toDate ?? now, firstDate: DateTime(now.year - 2), lastDate: DateTime(now.year + 5));
    if (picked != null && mounted) setState(() => _toDate = picked);
  }

  Future<void> _pickFromTime() async {
    final picked = await showTimePicker(context: context, initialTime: _fromTime ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null && mounted) setState(() => _fromTime = picked);
  }

  Future<void> _pickToTime() async {
    final picked = await showTimePicker(context: context, initialTime: _toTime ?? const TimeOfDay(hour: 17, minute: 0));
    if (picked != null && mounted) setState(() => _toTime = picked);
  }

  void _showAddRoleSheet() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final requirementCtrl = TextEditingController();
    final maxCtrl = TextEditingController();
    final pointCtrl = TextEditingController();
    String scoreType = 'Rèn luyện';

    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Thêm vai trò', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên vai trò')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
            TextField(controller: requirementCtrl, decoration: const InputDecoration(labelText: 'Yêu cầu')),
            TextField(controller: maxCtrl, decoration: const InputDecoration(labelText: 'Số lượng tối đa'), keyboardType: TextInputType.number),
            TextField(controller: pointCtrl, decoration: const InputDecoration(labelText: 'Điểm thưởng'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(value: scoreType, items: const [DropdownMenuItem(value: 'Rèn luyện', child: Text('Rèn luyện')), DropdownMenuItem(value: 'CTXH', child: Text('CTXH'))], onChanged: (v) => scoreType = v ?? 'Rèn luyện', decoration: const InputDecoration(labelText: 'Loại điểm')),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')), ElevatedButton(onPressed: () {
              final name = nameCtrl.text.trim();
              final max = int.tryParse(maxCtrl.text.trim()) ?? 0;
              final point = double.tryParse(pointCtrl.text.trim()) ?? 0.0;
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên vai trò là bắt buộc')));
                return;
              }
              setState(() => _roles.add({'name': name, 'description': descCtrl.text.trim(), 'requirement': requirementCtrl.text.trim(), 'max': max, 'point': point, 'scoreType': scoreType}));
              Navigator.pop(ctx);
            }, child: const Text('Lưu'))])
          ]),
        ),
      );
    });
  }

  Widget _buildRoleList() {
    if (_roles.isEmpty) return const Padding(padding: EdgeInsets.all(12.0), child: Text('Chưa có vai trò nào'));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _roles.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final r = _roles[idx];
        return ListTile(
          title: Text(r['name'] ?? '-'),
          subtitle: Text('Yêu cầu: ${r['requirement'] ?? '-'} • Số lượng: ${r['max']}'),
          trailing: Text('+${r['point']} ${r['scoreType']}'),
          onLongPress: () {
            setState(() => _roles.removeAt(idx));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa vai trò')));
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc')));
      return;
    }
    if (_fromDate!.isAfter(_toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ngày bắt đầu phải trước ngày kết thúc')));
      return;
    }
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất 1 vai trò')));
      return;
    }

    setState(() => _submitting = true);
    // show loading
    showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    try {
      // TODO: call ApiService.createActivity when API available. For now simulate network.
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo hoạt động thành công (giả lập)')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Lỗi'), content: Text(e.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo hoạt động'), backgroundColor: AppColors.primary),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Tên hoạt động'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Tên hoạt động là bắt buộc' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Mô tả chung'), maxLines: 5, validator: (v) => (v == null || v.trim().isEmpty) ? 'Mô tả là bắt buộc' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: InkWell(onTap: _pickFromDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Từ ngày'), child: Text(_fromDate == null ? 'Chọn ngày' : _fromDate!.toLocal().toString().split(' ').first)))),
              const SizedBox(width: 8),
              Expanded(child: InkWell(onTap: _pickToDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Đến ngày'), child: Text(_toDate == null ? 'Chọn ngày' : _toDate!.toLocal().toString().split(' ').first)))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: InkWell(onTap: _pickFromTime, child: InputDecorator(decoration: const InputDecoration(labelText: 'Giờ bắt đầu'), child: Text(_fromTime == null ? 'Chọn giờ' : _fromTime!.format(context))))),
              const SizedBox(width: 8),
              Expanded(child: InkWell(onTap: _pickToTime, child: InputDecorator(decoration: const InputDecoration(labelText: 'Giờ kết thúc'), child: Text(_toTime == null ? 'Chọn giờ' : _toTime!.format(context))))),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Địa điểm'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Địa điểm là bắt buộc' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _organizer, items: const [DropdownMenuItem(value: 'Khoa', child: Text('Khoa')), DropdownMenuItem(value: 'Đoàn', child: Text('Đoàn')), DropdownMenuItem(value: 'CLB', child: Text('CLB'))], onChanged: (v) => setState(() => _organizer = v), decoration: const InputDecoration(labelText: 'Đơn vị tổ chức')),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Vai trò tham gia', style: TextStyle(fontWeight: FontWeight.bold)), FloatingActionButton.small(heroTag: 'add_role', onPressed: _showAddRoleSheet, child: const Icon(Icons.add))]),
            const SizedBox(height: 8),
            _buildRoleList(),
            const SizedBox(height: 24),
            Row(children: [
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _submitting ? null : _submit, child: const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Text('Tạo hoạt động'))))
            ])
          ]),
        ),
      ),
    );
  }
}
