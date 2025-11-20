import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/api_service.dart';

/// Simple stub screen to input student IDs (comma separated) to assign to activity.
/// Returns List<int> of student ids when popped.
class AssignStudentsScreen extends StatefulWidget {
  final int? activityId;
  const AssignStudentsScreen({Key? key, this.activityId}) : super(key: key);

  @override
  State<AssignStudentsScreen> createState() => _AssignStudentsScreenState();
}

class _AssignStudentsScreenState extends State<AssignStudentsScreen> {
  final ApiService _api = ApiService.instance;
  List<Student> _items = [];
  List<Student> _filtered = [];
  final Set<int> _selected = {};
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({int page = 1}) async {
    setState(() => _loading = true);
    try {
      Map<String, dynamic> resp;
      if (widget.activityId != null) {
        resp = await _api.getAvailableStudents(
          widget.activityId!,
          page: page,
          perPage: 100,
          search: _query.isEmpty ? null : _query,
          // note: training/social filters handled via state variables if set
        );
        final data = resp['data'] ?? resp;
        List items = [];
        if (data is Map && data['available_students'] is List) items = data['available_students'] as List;
        else if (data is Map && data['data'] is List) items = data['data'] as List;
        else if (data is List) items = data;

        _items = items.map<Student>((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
        _filtered = List.from(_items);
      } else {
        resp = await _api.getStudents(page: page, perPage: 100, q: _query.isEmpty ? null : _query);
        final data = resp['data'] ?? resp;
        List items = [];
        if (data is Map && data['data'] is List) items = data['data'] as List;
        else if (data is List) items = data;

        _items = items.map<Student>((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
        _filtered = List.from(_items);
      }
    } catch (e) {
      _items = [];
      _filtered = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      if (q.isEmpty) _filtered = List.from(_items);
      else {
        final low = q.toLowerCase();
        _filtered = _items.where((s) => s.fullName.toLowerCase().contains(low) || s.userCode.toLowerCase().contains(low)).toList();
      }
    });
  }

  Widget _buildTile(Student s) {
    final sel = _selected.contains(s.studentId);
    return ListTile(
      leading: CircleAvatar(child: Text(s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S')),
      title: Text(s.fullName),
      subtitle: Text('MSSV: ${s.userCode} • Lớp: ${s.classId ?? '-'}'),
      trailing: Checkbox(value: sel, onChanged: (_) => setState(() => sel ? _selected.remove(s.studentId) : _selected.add(s.studentId))),
      onTap: () => setState(() => sel ? _selected.remove(s.studentId) : _selected.add(s.studentId)),
    );
  }

  void _confirm() {
    Navigator.of(context).pop(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn sinh viên'), centerTitle: true),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên hoặc MSSV'), onChanged: _onSearch),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('Không có sinh viên'))
              : ListView.builder(itemCount: _filtered.length, itemBuilder: (_, i) => _buildTile(_filtered[i])),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(children: [Expanded(child: ElevatedButton(onPressed: _confirm, child: Text('Xác nhận (${_selected.length})')))]),
        ),
      ]),
    );
  }
}
