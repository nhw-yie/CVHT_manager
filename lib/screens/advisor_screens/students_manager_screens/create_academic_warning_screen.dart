import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/academic_monitoring_provider.dart';
import '../../../providers/at_risk_students_provider.dart';
import '../../../providers/class_provider.dart';
// widgets import intentionally omitted if not used directly here
import '../../../constants/app_colors.dart';

/// Screen to create academic warnings for selected students.
///
/// - Uses `ClassProvider` for semester list
/// - Uses `AtRiskStudentsProvider` for the recommended (auto) student list
/// - Uses `AcademicMonitoringProvider` to perform the creation API call
///
/// The UI includes two selection modes (auto from at-risk list, or manual search),
/// preview of selected students and a final create button. Validation is
/// performed before creation. The provider call's result is shown in a dialog
/// with counts for success / failures.
class CreateAcademicWarningScreen extends StatefulWidget {
  const CreateAcademicWarningScreen({Key? key}) : super(key: key);

  @override
  State<CreateAcademicWarningScreen> createState() => _CreateAcademicWarningScreenState();
}

class _CreateAcademicWarningScreenState extends State<CreateAcademicWarningScreen> {
  final _formKey = GlobalKey<FormState>();

  // Selection mode: 0 = auto (at-risk), 1 = manual
  int _selectionMode = 0;

  // Selected semester id
  int? _selectedSemesterId;

  // Selected student IDs
  final Set<int> _selectedStudentIds = {};

  // Filters and UI state
  String _riskFilter = 'all'; // e.g. 'all','high','medium','low'
  String _manualQuery = '';
  bool _isCreating = false;

  // Pagination state for manual search (simple offset-based)
  int _manualPage = 1;

  @override
  void initState() {
    super.initState();
    // Optionally preload provider data. We avoid calling provider methods
    // that may not exist; consumers should ensure providers are prepared
    // by higher-level screens or call explicit fetch methods when integrating.
  }

  void _toggleStudent(int id, {required bool selected}) {
    setState(() {
      if (selected) {
        _selectedStudentIds.add(id);
      } else {
        _selectedStudentIds.remove(id);
      }
    });
  }

  void _selectAllVisible(List<int> ids) {
    setState(() {
      _selectedStudentIds.addAll(ids);
    });
  }

  void _clearAllSelection() {
    setState(() {
      _selectedStudentIds.clear();
    });
  }

  Future<void> _createWarnings() async {
    // Validation
    if (_selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn học kỳ')));
      return;
    }
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sinh viên')));
      return;
    }

    final acadProv = context.read<AcademicMonitoringProvider>();

    setState(() => _isCreating = true);

    // Show a simple loading dialog while creating
    showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    try {
      final ok = await acadProv.createWarnings(semesterId: _selectedSemesterId!, studentIds: _selectedStudentIds.toList());

      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      if (ok) {
        await showDialog<void>(context: context, builder: (ctx) {
          return AlertDialog(
            title: const Text('Kết quả tạo cảnh báo'),
            content: const Text('Tạo cảnh báo thành công'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng')),
            ],
          );
        });
        if (mounted) context.pop();
      } else {
        // Use provider's errorMessage if available
        final msg = acadProv.errorMessage ?? 'Có lỗi xảy ra khi tạo cảnh báo.';
        await showDialog<void>(context: context, builder: (ctx) {
          return AlertDialog(
            title: const Text('Lỗi'),
            content: Text(msg),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng'))],
          );
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tạo cảnh báo: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classProv = context.watch<ClassProvider>();
    final atRiskProv = context.watch<AtRiskStudentsProvider>();
    // ClassProvider exposes `classes` and `students`.
    final semesters = classProv.classes;
    final allStudents = classProv.students;

    // Helper accessors for Map-based student payloads
    int _idOf(Map<String, dynamic> m) {
      final val = m['student_id'] ?? m['studentId'] ?? m['id'];
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    String? _avatarOf(Map<String, dynamic> m) => (m['avatar_url'] ?? m['avatarUrl'] ?? m['avatar'])?.toString();
    String _nameOf(Map<String, dynamic> m) => (m['full_name'] ?? m['fullName'] ?? m['name'] ?? '').toString();
    String _codeOf(Map<String, dynamic> m) => (m['student_code'] ?? m['studentCode'] ?? m['code'] ?? '').toString();
    String _riskOf(Map<String, dynamic> m) => (m['risk_level'] ?? m['riskLevel'] ?? '').toString();
    String _cpaOf(Map<String, dynamic> m) => (m['cpa'] ?? m['CPA'] ?? '').toString();

    // Filtered at-risk list (AtRiskStudentsProvider provides `students` as List<Map<String,dynamic>>)
    final atRiskList = atRiskProv.students.where((Map<String, dynamic> s) {
      if (_riskFilter == 'all') return true;
      final lvl = (s['risk_level'] ?? s['riskLevel'] ?? '').toString().toLowerCase();
      return lvl.contains(_riskFilter);
    }).toList();

    // Manual search results (simple client-side filtering) — ClassProvider.students contains `Student` objects
    final manualResults = allStudents.where((s) {
      if (_manualQuery.isEmpty) return true;
      final q = _manualQuery.toLowerCase();
      final name = s.fullName.toString().toLowerCase();
      final code = s.userCode.toString().toLowerCase();
      return name.contains(q) || code.contains(q);
    }).skip(((_manualPage - 1) * 20)).take(20).toList();

    // Responsive columns for student list
    final width = MediaQuery.of(context).size.width;
    final columns = width > 900 ? 2 : (width > 600 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Cảnh báo Học vụ'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // SECTION 1 - SELECT SEMESTER
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Chọn học kỳ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedSemesterId,
                    items: semesters.map<DropdownMenuItem<int>>((c) {
                      return DropdownMenuItem(value: c.classId, child: Text(c.className));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedSemesterId = v),
                    validator: (v) => v == null ? 'Hãy chọn học kỳ' : null,
                    decoration: const InputDecoration(helperText: 'Chọn học kỳ cần tạo cảnh báo'),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // SECTION 2 - SELECT STUDENTS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Chọn sinh viên', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  // Mode radio
                  Row(children: [
                    Expanded(child: RadioListTile<int>(value: 0, groupValue: _selectionMode, title: const Text('Chọn từ sinh viên nguy cơ (Khuyến nghị)'), onChanged: (v) => setState(() => _selectionMode = v ?? 0))),
                    Expanded(child: RadioListTile<int>(value: 1, groupValue: _selectionMode, title: const Text('Chọn thủ công'), onChanged: (v) => setState(() => _selectionMode = v ?? 1))),
                  ]),

                  const SizedBox(height: 8),

                  // AUTO SELECT UI
                  if (_selectionMode == 0) ...[
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Wrap(children: [
                        ChoiceChip(label: const Text('Tất cả'), selected: _riskFilter == 'all', onSelected: (_) => setState(() => _riskFilter = 'all')),
                        const SizedBox(width: 8),
                        ChoiceChip(label: const Text('Cao'), selected: _riskFilter == 'high', onSelected: (_) => setState(() => _riskFilter = 'high')),
                        const SizedBox(width: 8),
                        ChoiceChip(label: const Text('Trung bình'), selected: _riskFilter == 'medium', onSelected: (_) => setState(() => _riskFilter = 'medium')),
                        const SizedBox(width: 8),
                        ChoiceChip(label: const Text('Thấp'), selected: _riskFilter == 'low', onSelected: (_) => setState(() => _riskFilter = 'low')),
                      ]),
                      TextButton(onPressed: () => _selectAllVisible(atRiskList.map((s) => _idOf(s)).toList()), child: const Text('Chọn tất cả'))
                    ]),

                    const SizedBox(height: 8),

                    SizedBox(
                      height: 240,
                      child: atRiskProv.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : atRiskList.isEmpty
                              ? const Center(child: Text('Không có sinh viên nguy cơ'))
                              : GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, childAspectRatio: 6.2),
                                  itemCount: atRiskList.length,
                                  itemBuilder: (ctx, i) {
                                    final s = atRiskList[i];
                                    final sid = _idOf(s);
                                    final selected = _selectedStudentIds.contains(sid);
                                    final avatar = _avatarOf(s);
                                    return ListTile(
                                      leading: CircleAvatar(backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) as ImageProvider : null, child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person) : null),
                                      title: Text(_nameOf(s)),
                                      subtitle: Text('${_codeOf(s)} • ${_riskOf(s)} • CPA: ${_cpaOf(s).isEmpty ? '--' : _cpaOf(s)}'),
                                      trailing: Checkbox(value: selected, onChanged: (v) => _toggleStudent(sid, selected: v ?? false)),
                                    );
                                  }),
                    ),
                  ],

                  // MANUAL SELECT UI
                  if (_selectionMode == 1) ...[
                    TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên hoặc mã sinh viên'),
                      onChanged: (v) => setState(() {
                        _manualQuery = v;
                        _manualPage = 1;
                      }),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 240,
                      child: manualResults.isEmpty
                          ? const Center(child: Text('Không tìm thấy kết quả'))
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, childAspectRatio: 6.2),
                              itemCount: manualResults.length,
                              itemBuilder: (ctx, i) {
                                final s = manualResults[i];
                                final sid = s.studentId;
                                final selected = _selectedStudentIds.contains(sid);
                                final avatar = s.avatarUrl ?? '';
                                return ListTile(
                                  leading: CircleAvatar(backgroundImage: (avatar.isNotEmpty) ? NetworkImage(avatar) as ImageProvider : null, child: (avatar.isEmpty) ? const Icon(Icons.person) : null),
                                  title: Text(s.fullName),
                                  subtitle: Text(s.userCode),
                                  trailing: Checkbox(value: selected, onChanged: (v) => _toggleStudent(sid, selected: v ?? false)),
                                );
                              }),
                    ),

                    // Simple pagination controls
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      TextButton(onPressed: _manualPage > 1 ? () => setState(() => _manualPage--) : null, child: const Text('Trang trước')),
                      Text('Trang $_manualPage'),
                      TextButton(onPressed: manualResults.length == 20 ? () => setState(() => _manualPage++) : null, child: const Text('Trang sau')),
                    ])
                  ]
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // SECTION 3 - PREVIEW SELECTED
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Đã chọn: ${_selectedStudentIds.length} sinh viên', style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextButton(onPressed: _clearAllSelection, child: const Text('Xóa tất cả lựa chọn'))
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final sid in _selectedStudentIds)
                      Chip(label: Text('$sid'), deleteIcon: const Icon(Icons.close), onDeleted: () => _toggleStudent(sid, selected: false))
                  ])
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // SECTION 4 - WARNING PREVIEW
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Hệ thống sẽ tự động:', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('✓ Tạo cảnh báo dựa trên CPA'),
                  Text('✓ Gửi email cho sinh viên'),
                  Text('✓ Gửi thông báo trong app'),
                  Text('✓ Tạo ghi chú theo dõi'),
                ]),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(children: [
            Expanded(
                child: OutlinedButton(
              onPressed: _isCreating ? null : () => context.pop(),
              child: const Text('Hủy'),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
              onPressed: _isCreating
                  ? null
                  : () {
                      // Validate form then create
                      if (_formKey.currentState?.validate() ?? true) {
                        _createWarnings();
                      }
                    },
              child: _isCreating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Tạo cảnh báo'),
            )),
          ]),
        ),
      ),
    );
  }
}
