import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/at_risk_students_provider.dart';
import '../../../widgets/widgets.dart';
import '../../../constants/app_colors.dart';
import './widgets/student_risk_card.dart';

/// At-Risk Students List Screen
/// Shows filter chips, sorting controls, stats summary and a responsive list/grid
class AtRiskStudentsScreen extends StatefulWidget {
  const AtRiskStudentsScreen({Key? key}) : super(key: key);

  @override
  State<AtRiskStudentsScreen> createState() => _AtRiskStudentsScreenState();
}

class _AtRiskStudentsScreenState extends State<AtRiskStudentsScreen> {
  // Local UI filter state (provider does not expose a selected filter)
  String _currentFilter = 'all';

  // Open a modal sheet to choose sorting options
  void _openSortSheet(BuildContext context, AtRiskStudentsProvider prov) {
    showModalBottomSheet<void>(context: context, builder: (ctx) {
      final options = {
        'Mức độ nguy cơ': 'risk_level',
        'Điểm CPA': 'cpa',
        'Tỷ lệ vắng': 'absence_rate',
        'Tên A-Z': 'name',
      };
      return ListView(
        shrinkWrap: true,
        children: options.keys.map((label) {
          return ListTile(
            title: Text(label),
            onTap: () {
              prov.setSortOrder(options[label]!, prov.sortAscending);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      );
    });
  }

  // Open a modal to select filter (same choices as chips)
  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(context: context, builder: (ctx) {
      final chips = [
        {'label': 'Tất cả', 'value': 'all'},
        {'label': 'Nguy cơ cao', 'value': 'high'},
        {'label': 'Trung bình', 'value': 'medium'},
        {'label': 'Thấp', 'value': 'low'},
      ];
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(spacing: 8, children: chips.map((c) {
          final selected = _currentFilter == c['value'];
          return ChoiceChip(
            label: Text(c['label']!),
            selected: selected,
            onSelected: (_) {
              setState(() => _currentFilter = c['value']!);
              Navigator.pop(ctx);
            },
          );
        }).toList()),
      );
    });
  }
  @override
  void initState() {
    super.initState();
    // Fetch initial data after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<AtRiskStudentsProvider>();
      prov.fetchAtRiskStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for reactive updates
    final prov = context.watch<AtRiskStudentsProvider>();

    // Responsive breakpoints
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    // Risk colors
    const criticalColor = Color(0xFF8B0000);
    const highColor = Color(0xFFDC143C);
    const mediumColor = Color(0xFFFF6B6B);
    const lowColor = Color(0xFFFFA500);

    // Sorting dropdown options
    const sortOptions = [
      'Mức độ nguy cơ',
      'Điểm CPA',
      'Tỷ lệ vắng',
      'Tên A-Z',
    ];
    const sortMap = {
      'Mức độ nguy cơ': 'risk_level',
      'Điểm CPA': 'cpa',
      'Tỷ lệ vắng': 'absence_rate',
      'Tên A-Z': 'name',
    };

    // Build filter chips
    Widget _buildFilterChips() {
      final chips = <Map<String, String>>[
        {'label': 'Tất cả', 'value': 'all'},
        {'label': 'Nguy cơ cao', 'value': 'high'},
        {'label': 'Trung bình', 'value': 'medium'},
        {'label': 'Thấp', 'value': 'low'},
      ];

      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: chips.map((c) {
          final selected = _currentFilter == c['value'];
          return ChoiceChip(
            label: Text(c['label']!),
            selected: selected,
            onSelected: (_) {
              setState(() => _currentFilter = c['value']!);
            },
            selectedColor: AppColors.primary.withOpacity(0.12),
            backgroundColor: Colors.transparent,
            labelStyle: TextStyle(color: selected ? AppColors.primary : null),
          );
        }).toList(),
      );
    }

    // Build sorting card
    Widget _buildSortCard() {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            const Text('Sắp xếp:'),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: sortMap.entries.firstWhere((e) => e.value == prov.sortBy, orElse: () => const MapEntry('Mức độ nguy cơ', 'risk_level')).key,
              items: sortOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val == null) return;
                final field = sortMap[val]!;
                prov.setSortOrder(field, prov.sortAscending);
              },
            ),
            const Spacer(),
            IconButton(
              tooltip: prov.sortAscending ? 'Giảm dần' : 'Tăng dần',
              icon: Icon(prov.sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () => prov.setSortOrder(prov.sortBy, !prov.sortAscending),
            ),
          ]),
        ),
      );
    }

    // Stats summary bar
    Widget _buildStatsBar() {
      final total = prov.students.length;
      final highCount = prov.getRiskLevelCount('high');

      // compute average CPA locally
      double? _toDouble(Object? v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }

      final cpas = prov.students.map((s) => _toDouble(s['cpa'] ?? s['CPA'])).where((e) => e != null).map((e) => e!).toList();
      final avgCpa = cpas.isEmpty ? '-' : (cpas.reduce((a, b) => a + b) / cpas.length).toStringAsFixed(2);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Text('Tìm thấy: ', style: Theme.of(context).textTheme.bodyMedium),
          Text('$total', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text('| Nguy cơ cao: ', style: Theme.of(context).textTheme.bodyMedium),
          Text('$highCount', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: criticalColor, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text('| CPA TB: ', style: Theme.of(context).textTheme.bodyMedium),
          Text('$avgCpa', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
        ]),
      );
    }

    // Build the list/grid of students
    Widget _buildStudentsList() {
      if (prov.isLoading) {
        // Show loading skeletons
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: 6,
          itemBuilder: (ctx, i) => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LoadingIndicator(mode: LoadingMode.skeleton, height: 64)),
        );
      }

      if (prov.errorMessage != null) {
        // Show error display with retry
        return Center(
          child: ErrorDisplay(message: prov.errorMessage!, onRetry: () => prov.fetchAtRiskStudents()),
        );
      }

      final students = _currentFilter == 'all' ? prov.students : prov.getStudentsByRiskLevel(_currentFilter);

      if (students.isEmpty) {
        // Empty state
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Không có sinh viên nguy cơ', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Quay lại')),
          ]),
        );
      }

      // Pull-to-refresh wrapper
      return RefreshIndicator(
        onRefresh: () async => prov.fetchAtRiskStudents(),
        child: LayoutBuilder(builder: (ctx, constraints) {
          // Use GridView for tablet/desktop
          if (crossAxisCount == 1) {
            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (ctx, idx) {
                final s = students[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: StudentRiskCard(
                    student: s,
                    onTap: () => context.push('/advisor/students/${s['id'] ?? s['student_id']}'),
                    riskColors: {'critical': criticalColor, 'high': highColor, 'medium': mediumColor, 'low': lowColor},
                  ),
                );
              },
            );
          }

          // Grid for larger screens
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 3.8),
            itemCount: students.length,
            itemBuilder: (ctx, idx) {
              final s = students[idx];
              return StudentRiskCard(
                student: s,
                onTap: () => context.push('/advisor/students/${s['id'] ?? s['student_id']}'),
                riskColors: {'critical': criticalColor, 'high': highColor, 'medium': mediumColor, 'low': lowColor},
              );
            },
          );
        }),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sinh viên Nguy cơ',
        showBackButton: true,
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: () => _openSortSheet(context, prov)),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _openFilterSheet(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Filter chips row
          _buildFilterChips(),
          const SizedBox(height: 12),

          // Sort controls and summary
          Row(children: [Expanded(child: _buildSortCard()), const SizedBox(width: 12), Expanded(child: _buildStatsBar())]),
          const SizedBox(height: 12),

          // Expanded list area
          Expanded(child: _buildStudentsList()),
        ]),
      ),
      floatingActionButton: prov.students.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/advisor/students/create-warning'),
              icon: const Icon(Icons.warning),
              label: const Text('Tạo cảnh báo'),
            )
          : null,
    );
  }
}
