import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/student.dart';
// ApiService can be used to fetch/update student data when backend is available.

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSemester = '2025-HK1';
  bool _isLoading = true;

  // Placeholder models
  Student? _student;
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // In real app, call ApiService to get student detail by id.
    await Future.delayed(const Duration(milliseconds: 500));

    final idInt = int.tryParse(widget.studentId) ?? 0;
    _student = Student(studentId: idInt, userCode: 'U$idInt', fullName: 'Sinh viên #$idInt', email: '${idInt}@school.edu', phoneNumber: '09${(10000000 + idInt) % 99999999}', avatarUrl: null, classId: 1, status: 'Ổn');

    _grades = List.generate(6, (i) => {'code': 'MH${i + 1}', 'name': 'Môn ${i + 1}', 'score': (6 + i).toDouble()});
    _activities = List.generate(4, (i) => {'title': 'Hoạt động ${i + 1}', 'point': (i + 1) * 2, 'date': DateTime.now().subtract(Duration(days: i * 10))});
    _notes = [
      {'time': DateTime.now().subtract(const Duration(days: 10)), 'text': 'Ghi chú: Liên hệ gia đình.'},
      {'time': DateTime.now().subtract(const Duration(days: 3)), 'text': 'Ghi chú: Cảnh báo lần 1.'},
    ];

    if (mounted) setState(() => _isLoading = false);
  }

  void _addNote() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Thêm ghi chú theo dõi'),
        content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Nội dung...')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm'))],
      );
    });

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      if (!mounted) return;
      setState(() => _notes.insert(0, {'time': DateTime.now(), 'text': ctrl.text.trim()}));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm ghi chú')));
    }
  }

  void _sendMessage() {
    context.push('/student/chat/student_${widget.studentId}');
  }

  void _warnAcademic() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Cảnh cáo học vụ'), content: const Text('Bạn có chắc muốn gửi cảnh cáo học vụ cho sinh viên này?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận'))]));
    if (ok == true) {
      // TODO: call API to create warning
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi cảnh cáo học vụ (giả lập)')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _header() {
    return ListTile(
      leading: CircleAvatar(radius: 30, child: Text((_student?.fullName.isNotEmpty ?? false) ? _student!.fullName[0] : 'S')),
      title: Text(_student?.fullName ?? '-'),
      subtitle: Text('MSSV: ${_student?.studentId ?? '-'}'),
    );
  }

  Widget _contactCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Thông tin liên hệ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(title: const Text('Email'), subtitle: Text(_student?.email ?? '-')),
          ListTile(title: const Text('Số điện thoại'), subtitle: Text(_student?.phoneNumber ?? '-')),
        ]),
      ),
    );
  }

  Widget _studyCard() {
    final gpa = 3.2; // placeholder
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Học tập - HK hiện tại', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(value: _selectedSemester, items: ['2025-HK1', '2024-HK2', '2024-HK1'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _selectedSemester = v ?? _selectedSemester))
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('GPA: ${gpa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 6), const Text('Tín chỉ: 15/18')])),
            SizedBox(width: 100, child: Column(children: [LinearProgressIndicator(value: gpa / 4.0, color: AppColors.primary, backgroundColor: AppColors.primary.withOpacity(0.12)), const SizedBox(height: 6), const Text('Xếp loại: Khá')]))
          ]),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Xem chi tiết điểm')))
        ]),
      ),
    );
  }

  Widget _gradesTile() {
    return ExpansionTile(title: const Text('Điểm các môn học'), children: _grades.map((g) => ListTile(title: Text('${g['code']} - ${g['name']}'), trailing: Text('${g['score']}'))).toList());
  }

  Widget _activitiesTile() {
    return ExpansionTile(title: const Text('Hoạt động đã tham gia'), children: _activities.map((a) => ListTile(title: Text(a['title']), subtitle: Text((a['date'] as DateTime).toLocal().toString().split(' ').first), trailing: Text('+${a['point']}'))).toList());
  }

  Widget _notesTile() {
    return ExpansionTile(
      title: const Text('Ghi chú theo dõi'),
      children: [
        ..._notes.map((n) => ListTile(leading: Icon(Icons.note, color: AppColors.primary), title: Text(n['text']), subtitle: Text((n['time'] as DateTime).toLocal().toString()))),
        ListTile(leading: const Icon(Icons.add), title: const Text('Thêm ghi chú'), onTap: _addNote)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sinh viên'), backgroundColor: AppColors.primary),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(children: [
                _header(),
                TabBar(controller: _tabController, tabs: const [Tab(text: 'Tổng quan'), Tab(text: 'Điểm/HT'), Tab(text: 'Ghi chú')], labelColor: AppColors.primary),
                Expanded(
                    child: TabBarView(controller: _tabController, children: [
                  // Overview
                  ListView(children: [_contactCard(), _studyCard(), _activitiesTile()]),
                  // Grades and activities
                  ListView(children: [_gradesTile(), _activitiesTile()]),
                  // Notes
                  ListView(children: [_notesTile()])
                ]))
              ]),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _sendMessage, icon: const Icon(Icons.message), label: const Text('Nhắn tin'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: _warnAcademic, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Cảnh cáo học vụ')))
        ]),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addNote, child: const Icon(Icons.add)),
    );
  }
}
