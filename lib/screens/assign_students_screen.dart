import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/student.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AssignStudentsScreen extends StatefulWidget {
  final int? activityId;
  const AssignStudentsScreen({Key? key, this.activityId}) : super(key: key);

  @override
  State<AssignStudentsScreen> createState() => _AssignStudentsScreenState();
}

class _AssignStudentsScreenState extends State<AssignStudentsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedClass = 'All';
  String _sortBy = 'Name';

  // students list
  late List<Student> _allStudents;
  List<Student> _filtered = [];
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _availableClasses = [];
  int _minTraining = 0;
  int _minSocial = 0;

  // selection
  final Set<int> _selected = {};

  // activity info (placeholder)
  final String _activityName = 'Hoạt động Tình nguyện A';
  final String _roleName = 'Tình nguyện viên';
  final int _maxSlots = 5;

  @override
  void initState() {
    super.initState();
    _allStudents = [];
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    if (widget.activityId != null) {
      await _fetchFromAvailable(widget.activityId!);
    } else {
      // fallback simulated data
      _allStudents = List.generate(30, (i) => Student(studentId: 1000 + i, userCode: 'S${1000 + i}', fullName: 'Sinh viên ${i + 1}', classId: (i % 3) + 1, status: (i % 7 == 0) ? 'Cảnh cáo' : 'Bình thường'));
      _applyFilter();
    }
  }

  Future<void> _fetchFromAvailable(int activityId) async {
    setState(() {});
    try {
      final resp = await _api.getAvailableStudents(activityId, page: 1, perPage: 200);
      final data = resp['data'] ?? resp;
      // parse assigned_classes for filter
      if (data is Map && data['assigned_classes'] is List) {
        _availableClasses = List<Map<String, dynamic>>.from(data['assigned_classes'] as List);
      }
      List students = [];
      if (data is Map && data['available_students'] is List) students = data['available_students'] as List;
      else if (data is Map && data['data'] is List) students = data['data'] as List;
      _allStudents = students.map<Student>((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
      _applyFilter();
    } catch (e) {
      _allStudents = [];
      _filtered = [];
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = _allStudents.where((s) {
      if (_selectedClass != 'All' && s.classId != null && 'Class${s.classId}' != _selectedClass) return false;
      if (q.isNotEmpty && !(s.fullName.toLowerCase().contains(q) || s.userCode.toLowerCase().contains(q))) return false;
      // if API returned training/social in Student model? Fallback: allow
      return true;
    }).toList();
    if (_sortBy == 'GPA') {
      _filtered.sort((a, b) => (b.studentId % 5).compareTo(a.studentId % 5));
    } else if (_sortBy == 'CTXH') {
      _filtered.sort((a, b) => (b.studentId % 3).compareTo(a.studentId % 3));
    } else if (_sortBy == 'training_point') {
      _filtered.sort((a, b) => 0); // data not present on Student model by default
    } else if (_sortBy == 'social_point') {
      _filtered.sort((a, b) => 0);
    } else {
      _filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    }
    setState(() {});
  }

  bool _isEligible(Student s) {
    // Simple eligibility rule: if status contains 'Cảnh', mark as not eligible
    if (s.status != null && s.status!.toLowerCase().contains('cảnh')) return false;
    // else eligible
    return true;
  }

  void _toggleSelect(Student s) {
    if (_selected.contains(s.studentId)) {
      setState(() => _selected.remove(s.studentId));
    } else {
      if (_selected.length >= _maxSlots) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đạt số slot tối đa')));
        return;
      }
      if (!_isEligible(s)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinh viên không đủ điều kiện')));
        return;
      }
      setState(() => _selected.add(s.studentId));
    }
  }

  Future<void> _confirmAndSend() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa chọn sinh viên nào')));
      return;
    }
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Xác nhận phân bổ'),
        content: Text('Gửi thông báo cho ${_selected.length} sinh viên cho vai trò "$_roleName"?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi'))],
      );
    });

    if (ok == true) {
      // simulate API call
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text('Đã gửi thông báo đến ${_selected.length} sinh viên')));
      setState(() => _selected.clear());
    }
  }

  Widget _buildStudentTile(Student s) {
    final eligible = _isEligible(s);
    final selected = _selected.contains(s.studentId);
    Color statusColor = eligible ? Colors.green : Colors.orange;
    String statusLabel = eligible ? 'Đủ điều kiện' : 'Cần xem xét';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Checkbox(value: selected, onChanged: (_) => _toggleSelect(s)),
        title: Text(s.fullName),
        subtitle: Text('MSSV: ${s.userCode} • Lớp: Class${s.classId}'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('GPA: ${(s.studentId % 5 + 2).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)))
        ]),
        onTap: () => _toggleSelect(s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phân bổ sinh viên'), actions: [IconButton(onPressed: () => _confirmAndSend(), icon: const Icon(Icons.done))], backgroundColor: AppColors.primary),
      body: Column(children: [
        Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_activityName, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text('Vai trò: $_roleName • Slots: $_maxSlots')])),),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _searchCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm tên hoặc MSSV'), onChanged: (_) => _applyFilter())),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedClass,
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem(value: 'All', child: Text('All')),
                ..._availableClasses.map((c) => DropdownMenuItem(value: 'Class${c['class_id']}', child: Text(c['class_name']?.toString() ?? 'Class${c['class_id']}'))).toList(),
              ],
              onChanged: (v) => setState(() {
                _selectedClass = v ?? 'All';
                _applyFilter();
              }),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(value: _sortBy, items: ['Name', 'GPA', 'CTXH', 'training_point', 'social_point'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() { _sortBy = v ?? 'Name'; _applyFilter(); })),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Điểm rèn luyện'), Row(children: [Expanded(child: Slider(value: _minTraining.toDouble(), min: 0, max: 100, onChanged: (v) => setState(() => _minTraining = v.toInt()))), Text('min: $_minTraining')])])),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Điểm CTXH'), Row(children: [Expanded(child: Slider(value: _minSocial.toDouble(), min: 0, max: 100, onChanged: (v) => setState(() => _minSocial = v.toInt()))), Text('min: $_minSocial')])])),
          ])
        ])),
        Expanded(child: ListView.builder(itemCount: _filtered.length, itemBuilder: (ctx, idx) => _buildStudentTile(_filtered[idx]))),
      ]),
      bottomNavigationBar: Container(padding: const EdgeInsets.all(12), color: Colors.white, child: Row(children: [
        Text('Đã chọn: ${_selected.length} sinh viên'),
        const Spacer(),
        ElevatedButton(onPressed: _confirmAndSend, child: const Text('Gửi thông báo tham gia'))
      ])),
    );
  }
}
