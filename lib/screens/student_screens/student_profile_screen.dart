import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/error_handler.dart';
import '../../models/student_detail_model.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> with SingleTickerProviderStateMixin {
  File? _avatarFile;
  bool _notificationsEnabled = true;
  late AnimationController _animController;

  bool _isLoading = true;
  String? _error;
  StudentDetail? _detail;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final studentId = auth.currentUser?.id;
      if (studentId != null) {
        final resp = await ApiService.instance.getStudentById(studentId);
        final data = resp['data'] ?? resp;
        if (data is Map<String, dynamic>) _detail = StudentDetail.fromJson(data);
      } else {
        final resp = await ApiService.instance.me();
        final data = resp['data'] ?? resp;
        if (data is Map<String, dynamic> && (data['student_id'] != null || data['id'] != null)) {
          final idVal = data['student_id'] ?? data['id'];
          final id = idVal;
          final resp2 = await ApiService.instance.getStudentById(id);
          final d2 = resp2['data'] ?? resp2;
          if (d2 is Map<String, dynamic>) _detail = StudentDetail.fromJson(d2);
        }
      }
    } catch (e) {
      _error = ErrorHandler.mapToMessage(e);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: false);
      if (res != null && res.files.isNotEmpty) {
        final path = res.files.single.path;
        if (path != null) setState(() => _avatarFile = File(path));
        messenger.showSnackBar(const SnackBar(content: Text('Ảnh đại diện đã chọn (chưa upload)')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
    }
  }

  void _showEditProfileSheet(AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.currentUser?.fullName ?? '');
    final emailCtrl = TextEditingController(text: auth.currentUser?.email ?? '');
    final phoneCtrl = TextEditingController(text: auth.currentUser?.phoneNumber ?? '');

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ và tên')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu (cập nhật cục bộ)')));
                },
                child: const Text('Lưu'),
              )
            ])
          ]),
        ),
      );
    });
  }

  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu cũ')), TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu mới'))]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận'))],
      );
    });

    if (ok == true) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yêu cầu đổi mật khẩu đã gửi')));
    }
  }

  Future<void> _logout(AuthProvider auth) async {
    final sure = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(title: const Text('Đăng xuất'), content: const Text('Bạn có chắc muốn đăng xuất?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))) ]);
    });

    if (sure == true) {
      await auth.logout();
      if (!mounted) return;
      context.go('/');
    }
  }

  Widget _buildHeader(AuthProvider auth) {
    final dynamic user = _detail?.student ?? auth.currentUser;
    final name = user?.fullName ?? 'Sinh viên';
    final mssv = user?.userCode ?? '-';
    final clazz = _detail?.classInfo?.className ?? '-';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Stack(children: [
          CircleAvatar(radius: 42, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            child: _avatarFile == null
                ? Text(name.isNotEmpty ? name[0] : 'S', style: const TextStyle(fontSize: 28))
                : ClipOval(child: Image.file(_avatarFile!, width: 84, height: 84, fit: BoxFit.cover))),
          Positioned(right: 0, bottom: 0, child: GestureDetector(onTap: _pickAvatar, child: CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.edit, size: 18, color: Colors.white))))
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text('MSSV: $mssv'), const SizedBox(height: 4), Text('Lớp: $clazz')])),
      ]),
    );
  }

  Widget _buildOverviewCard() {
    final gpa = _detail?.academicSummary?.cpa4 ?? _detail?.academicSummary?.semesterGpa4 ?? 0.0;
    final percent = (gpa / 4.0).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tổng quan học tập', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            SizedBox(
              width: 96,
              height: 96,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (ctx, child) {
                    final animatedValue = _animController.value * percent;
                    return Stack(alignment: Alignment.center, children: [
                      CircularProgressIndicator(value: animatedValue, strokeWidth: 8, color: Theme.of(context).colorScheme.primary.withOpacity(0.9)),
                      Column(mainAxisSize: MainAxisSize.min, children: [Text(gpa.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)), const Text('GPA')])
                    ]);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tín chỉ đạt'), Text('${_detail?.academicSummary?.totalCreditsPassed ?? '-'}')]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Điểm rèn luyện'), Text('--')]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Điểm CTXH'), Text('--')]),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () {}, child: const Text('Xem báo cáo chi tiết'))
              ]),
            )
          ])
        ]),
      ),
    );
  }

  Widget _buildDetailSections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        ExpansionTile(title: const Text('Ý thức học tập'), children: [ListTile(title: const Text('Điểm'), trailing: Text('--'))]),
        ExpansionTile(title: const Text('Ý thức tổ chức kỷ luật'), children: [ListTile(title: const Text('Điểm'), trailing: Text('--'))]),
        ExpansionTile(title: const Text('Hoạt động xã hội'), children: [ListTile(title: const Text('Điểm'), trailing: Text('--'))]),
        ExpansionTile(title: const Text('Văn hóa thể thao'), children: [ListTile(title: const Text('Điểm'), trailing: Text('--'))]),
      ]),
    );
  }

  Widget _buildActivitiesList() {
    var items = (_detail?.reports ?? [])
        .map((r) => {'title': 'Báo cáo Học kỳ', 'point': r.trainingPointSummary, 'date': DateTime.now()})
        .toList();

    if (items.isEmpty) {
      items = List.generate(6, (i) => {'title': 'Hoạt động ${i + 1}', 'point': (i + 1) * 2, 'date': DateTime.now().subtract(Duration(days: i * 7))});
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('Các hoạt động đã tham gia', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, idx) {
            final it = items[idx];
            final date = it['date'] is DateTime ? (it['date'] as DateTime) : DateTime.now();
            return ListTile(title: Text(it['title']?.toString() ?? ''), subtitle: Text('${date.toLocal().toString().split(' ').first}'), trailing: Text('+${it['point'] ?? ''}'));
          },
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final String? emailVal = _detail != null ? _detail!.student.email : auth.currentUser?.email;
    final String? phoneVal = _detail != null ? _detail!.student.phoneNumber : auth.currentUser?.phoneNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ sinh viên'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(onPressed: () => _showEditProfileSheet(auth), icon: const Icon(Icons.edit)),
          IconButton(onPressed: () => _logout(auth), icon: const Icon(Icons.logout)),
        ],
      ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _loadProfile, child: const Text('Thử lại'))]))
            : SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildHeader(auth),
                Card(margin: const EdgeInsets.symmetric(horizontal: 12), child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(title: const Text('Email'), subtitle: Text((_detail != null ? _detail!.student.email : auth.currentUser?.email) ?? '-')),
                    ListTile(title: const Text('Số điện thoại'), subtitle: Text((_detail != null ? _detail!.student.phoneNumber : auth.currentUser?.phoneNumber) ?? '-')),
                  ListTile(title: const Text('Cố vấn học tập (CVHT)'), subtitle: Text(_detail?.classInfo?.advisorId?.toString() ?? '-')),
                  ListTile(title: const Text('Khoa'), subtitle: Text(_detail?.classInfo?.facultyId?.toString() ?? '-')),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _showEditProfileSheet(auth), child: const Text('Chỉnh sửa')))
                ]))),
                if (_detail?.academicSummary != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tổng quan học tập', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('GPA: ${_detail!.academicSummary!.cpa4 ?? '--'}'),
                  Text('CPA: ${_detail!.academicSummary!.cpa10 ?? '--'}'),
                ])))),
                _buildOverviewCard(),
                _buildDetailSections(),
                _buildActivitiesList(),
                const SizedBox(height: 80)
              ]),
            ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Row(children: [
          Expanded(child: Row(children: [const Icon(Icons.notifications), const SizedBox(width: 8), const Text('Cài đặt thông báo'), const Spacer(), Switch(value: _notificationsEnabled, onChanged: (v) => setState(() => _notificationsEnabled = v))])),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _changePassword(), label: const Text('Đổi mật khẩu')),
    );
  }
}
