import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../models/student.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/class_provider.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedClassId;
  String _sortBy = 'GPA';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = Provider.of<StudentProvider>(context, listen: false);
      final classProv = Provider.of<ClassProvider>(context, listen: false);
      prov.fetchStudents(reset: true).then((_) => debugPrint('StudentProvider: loaded ${prov.students.length} items'));
      classProv.fetchClasses(reset: true).then((_) => debugPrint('ClassProvider: loaded ${classProv.classes.length} classes'));
    });
  }

  Future<void> _refresh() async {
    final prov = Provider.of<StudentProvider>(context, listen: false);
    if (_selectedClassId != null) {
      final classProv = Provider.of<ClassProvider>(context, listen: false);
      await classProv.fetchStudentsByClass(_selectedClassId!);
    } else {
      await prov.fetchStudents(reset: true);
    }
  }

  Future<void> _loadMore() async {
    final prov = Provider.of<StudentProvider>(context, listen: false);
    if (prov.loading || !prov.hasMore) return;
    await prov.fetchStudents();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('xuất')) return Colors.green;
    if (s.contains('giỏi') || s.contains('khá')) return Colors.blue;
    if (s.contains('trung')) return Colors.orange;
    if (s.contains('cảnh')) return Colors.red;
    return Colors.grey;
  }

  Widget _buildCard(Student s) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(s.fullName.isNotEmpty ? s.fullName[0] : 'S'),
        ),
        title: Text(s.fullName),
        subtitle: Text('MSSV: ${s.studentId} • Lớp: ${s.classId ?? '-'}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'GPA ${(2.5 + (s.studentId % 5) * 0.35).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(s.status ?? '').withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.status ?? '-',
                style: TextStyle(color: _statusColor(s.status ?? ''), fontSize: 12),
              ),
            )
          ],
        ),
        onTap: () {
          Navigator.pushNamed(context, '/activity_detail',
              arguments: s.studentId.toString());
        },
      ),
    );
  }

  Widget _buildStudentList(List<Student> students, bool isClassView) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (sn) {
          if (!isClassView &&
              sn is ScrollEndNotification &&
              sn.metrics.pixels >= sn.metrics.maxScrollExtent - 50) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (ctx, idx) => _buildCard(students[idx]),
        ),
      ),
    );
  }

  Widget _sortButton(String type, IconData icon) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor:
            _sortBy == type ? AppColors.primary.withOpacity(0.08) : null,
      ),
      onPressed: () => setState(() => _sortBy = type),
      icon: Icon(icon),
      label: Text(type),
    );
  }

  void _showAddNoteDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm ghi chú chung'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Nội dung...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ghi chú đã được thêm (chưa lưu)')),
                );
              },
              child: const Text('Thêm'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sinh viên'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: _showAddNoteDialog, child: const Icon(Icons.note_add)),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm theo tên hoặc MSSV',
                  border: OutlineInputBorder()),
              onSubmitted: (v) {
                final prov = Provider.of<StudentProvider>(context, listen: false);
                prov.fetchStudents(search: v, reset: true);
              },
            ),
          ),
          // Class chips
          Consumer<ClassProvider>(builder: (_, classProv, __) {
            return SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (ctx, idx) {
                  if (idx == 0) {
                    return ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _selectedClassId == null,
                      onSelected: (sel) async {
                        setState(() => _selectedClassId = null);
                        final prov =
                            Provider.of<StudentProvider>(context, listen: false);
                        await prov.fetchStudents(reset: true);
                      },
                    );
                  } else {
                    final c = classProv.classes[idx - 1];
                    return ChoiceChip(
                      label: Text(c.className),
                      selected: _selectedClassId == c.classId,
                      onSelected: (sel) async {
                        setState(() =>
                            _selectedClassId = sel ? c.classId : null);
                        debugPrint('Class chip selected: ${sel ? c.classId : 'null'}');
                        if (sel) {
                          await classProv.fetchStudentsByClass(c.classId);
                          debugPrint('ClassProvider: class ${c.classId} students ${classProv.students.length}');
                        } else {
                          final prov = Provider.of<StudentProvider>(context,
                              listen: false);
                          await prov.fetchStudents(reset: true);
                          debugPrint('StudentProvider: reloaded ${prov.students.length}');
                        }
                      },
                    );
                  }
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: classProv.classes.length + 1,
              ),
            );
          }),
          const SizedBox(height: 8),
          // Sorting buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _sortButton('GPA', Icons.sort),
                const SizedBox(width: 8),
                _sortButton('Rèn luyện', Icons.fitness_center),
                const SizedBox(width: 8),
                _sortButton('Status', Icons.filter_list),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Student list
          Expanded(
            child: Consumer2<ClassProvider, StudentProvider>(
              builder: (_, classProv, prov, __) {
                debugPrint('Build student list: selectedClassId=$_selectedClassId | classCount=${classProv.classes.length} | classStudents=${classProv.students.length} | globalStudents=${prov.students.length}');
                final students = _selectedClassId != null
                    ? classProv.students
                    : prov.students.map((m) => Student.fromJson(Map<String, dynamic>.from(m))).toList();
                if (students.isEmpty) {
                  return const Center(child: Text('Không có dữ liệu'));
                }
                return _buildStudentList(students, _selectedClassId != null);
              },
            ),
          ),
        ],
      ),
    );
  }
}
