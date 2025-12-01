import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../models/student.dart';
import '../../../models/points.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/class_provider.dart';
import '../../../providers/points_provider.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedClassId;
  String _sortBy = 'GPA'; // 'GPA', 'Rèn luyện', 'CTXH', 'Status'
  
  // ✅ THÊM MỚI - Cache điểm số của sinh viên
  Map<int, StudentPointsItem> _pointsCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = Provider.of<StudentProvider>(context, listen: false);
      final classProv = Provider.of<ClassProvider>(context, listen: false);
      await prov.fetchStudents(reset: true);
      await classProv.fetchClasses(reset: true);
      debugPrint('StudentProvider: loaded ${prov.students.length} items');
      debugPrint('ClassProvider: loaded ${classProv.classes.length} classes');
    });
  }

  // ✅ THÊM MỚI - Load điểm của lớp khi chọn lớp
  Future<void> _loadClassPoints(int classId) async {
    final pointsProv = Provider.of<PointsProvider>(context, listen: false);
    try {
      await pointsProv.fetchClassPointsSummary(classId: classId);
      if (pointsProv.classSummary != null) {
        // Cache điểm vào Map để tra cứu nhanh
        _pointsCache.clear();
        for (var item in pointsProv.classSummary!.students) {
          _pointsCache[item.studentId] = item;
        }
        setState(() {});
        debugPrint('Loaded points for ${_pointsCache.length} students in class $classId');
      }
    } catch (e) {
      debugPrint('Error loading class points: $e');
    }
  }

  Future<void> _refresh() async {
    final prov = Provider.of<StudentProvider>(context, listen: false);
    if (_selectedClassId != null) {
      final classProv = Provider.of<ClassProvider>(context, listen: false);
      await classProv.fetchStudentsByClass(_selectedClassId!);
      await _loadClassPoints(_selectedClassId!);
    } else {
      await prov.fetchStudents(reset: true);
      _pointsCache.clear();
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

  // ✅ CẬP NHẬT - Hiển thị điểm trong card
  Widget _buildCard(Student s) {
    final points = _pointsCache[s.studentId];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          child: Text(s.fullName.isNotEmpty ? s.fullName[0] : 'S'),
        ),
        title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MSSV: ${s.userCode} • Lớp: ${s.classId ?? '-'}'),
            const SizedBox(height: 4),
            // ✅ THÊM MỚI - Hiển thị điểm nếu có
            if (points != null) ...[
              Row(
                children: [
                  _buildPointChip('RL', points.totalTrainingPoints, Colors.blue),
                  const SizedBox(width: 6),
                  _buildPointChip('CTXH', points.totalSocialPoints, Colors.green),
                ],
              ),
            ],
          ],
        ),
        trailing: SizedBox(
          height: 40,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'GPA ${(2.5 + (s.studentId % 5) * 0.35).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(s.status ?? '').withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.status ?? '-',
                    style: TextStyle(color: _statusColor(s.status ?? ''), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          context.push('/advisor/students/${s.studentId}');
        },
      ),
    );
  }

  // ✅ THÊM MỚI - Widget hiển thị điểm dạng chip
  Widget _buildPointChip(String label, double points, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${points.toStringAsFixed(0)}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ✅ CẬP NHẬT - Sắp xếp danh sách sinh viên theo tiêu chí
  List<Student> _sortStudents(List<Student> students) {
    final sorted = List<Student>.from(students);
    
    switch (_sortBy) {
      case 'GPA':
        sorted.sort((a, b) {
          final gpaA = 2.5 + (a.studentId % 5) * 0.35;
          final gpaB = 2.5 + (b.studentId % 5) * 0.35;
          return gpaB.compareTo(gpaA); // Giảm dần
        });
        break;
        
      case 'Rèn luyện':
        if (_pointsCache.isNotEmpty) {
          sorted.sort((a, b) {
            final pA = _pointsCache[a.studentId]?.totalTrainingPoints ?? 0;
            final pB = _pointsCache[b.studentId]?.totalTrainingPoints ?? 0;
            return pB.compareTo(pA); // Giảm dần
          });
        }
        break;
        
      case 'CTXH':
        if (_pointsCache.isNotEmpty) {
          sorted.sort((a, b) {
            final pA = _pointsCache[a.studentId]?.totalSocialPoints ?? 0;
            final pB = _pointsCache[b.studentId]?.totalSocialPoints ?? 0;
            return pB.compareTo(pA); // Giảm dần
          });
        }
        break;
        
      case 'Status':
        sorted.sort((a, b) {
          final statusOrder = {
            'studying': 1,
            'warning': 2,
            'suspended': 3,
            'graduated': 4,
          };
          final orderA = statusOrder[a.status?.toLowerCase()] ?? 99;
          final orderB = statusOrder[b.status?.toLowerCase()] ?? 99;
          return orderA.compareTo(orderB);
        });
        break;
    }
    
    return sorted;
  }

  Widget _buildStudentList(List<Student> students, bool isClassView) {
    // ✅ Sắp xếp trước khi hiển thị
    final sortedStudents = _sortStudents(students);
    
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
          itemCount: sortedStudents.length,
          itemBuilder: (ctx, idx) => _buildCard(sortedStudents[idx]),
        ),
      ),
    );
  }

  // ✅ CẬP NHẬT - Sort button với icon rõ ràng hơn
  Widget _sortButton(String type, IconData icon) {
    final isSelected = _sortBy == type;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.12) : null,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      onPressed: () => setState(() => _sortBy = type),
      icon: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600),
      label: Text(
        type,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
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
                        setState(() {
                          _selectedClassId = null;
                          _pointsCache.clear(); // ✅ Clear cache khi bỏ chọn lớp
                        });
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
                          await _loadClassPoints(c.classId); // ✅ Load điểm khi chọn lớp
                          debugPrint('ClassProvider: class ${c.classId} students ${classProv.students.length}');
                        } else {
                          final prov = Provider.of<StudentProvider>(context,
                              listen: false);
                          await prov.fetchStudents(reset: true);
                          _pointsCache.clear();
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
          // Sorting buttons - ✅ CẬP NHẬT với CTXH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sortButton('GPA', Icons.school),
                  const SizedBox(width: 8),
                  _sortButton('Rèn luyện', Icons.fitness_center),
                  const SizedBox(width: 8),
                  _sortButton('CTXH', Icons.volunteer_activism),
                  const SizedBox(width: 8),
                  _sortButton('Status', Icons.filter_list),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ✅ THÊM MỚI - Hiển thị thống kê khi chọn lớp
          if (_selectedClassId != null && _pointsCache.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Tổng SV', _pointsCache.length.toString(), Icons.people),
                  _buildStatItem(
                    'TB Rèn luyện',
                    (_pointsCache.values.map((e) => e.totalTrainingPoints).reduce((a, b) => a + b) / _pointsCache.length).toStringAsFixed(1),
                    Icons.fitness_center,
                  ),
                  _buildStatItem(
                    'TB CTXH',
                    (_pointsCache.values.map((e) => e.totalSocialPoints).reduce((a, b) => a + b) / _pointsCache.length).toStringAsFixed(1),
                    Icons.volunteer_activism,
                  ),
                ],
              ),
            ),
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

  // ✅ THÊM MỚI - Widget hiển thị thống kê
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}