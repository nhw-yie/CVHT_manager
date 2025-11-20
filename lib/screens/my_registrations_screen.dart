import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/registrations_provider.dart';

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({Key? key}) : super(key: key);

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RegistrationsProvider>(context, listen: false).fetchRegistrations(filter: _filter);
    });
  }

  Color _badgeColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('cancel')) return AppColors.danger;
    if (s.contains('complete') || s.contains('done')) return AppColors.success;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Các hoạt động đã đăng ký'), backgroundColor: AppColors.primary),
      body: ChangeNotifierProvider<RegistrationsProvider>(
        create: (_) => RegistrationsProvider()..fetchRegistrations(filter: _filter),
        child: Consumer<RegistrationsProvider>(builder: (context, prov, _) {
          final items = prov.items;

          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('Tất cả'), selected: _filter == 'all', onSelected: (v) => _onFilterChanged('all')),
                ChoiceChip(label: const Text('Đang hoạt động'), selected: _filter == 'active', onSelected: (v) => _onFilterChanged('active')),
                ChoiceChip(label: const Text('Đã hoàn thành'), selected: _filter == 'completed', onSelected: (v) => _onFilterChanged('completed')),
                ChoiceChip(label: const Text('Đã hủy'), selected: _filter == 'cancelled', onSelected: (v) => _onFilterChanged('cancelled')),
              ]),
            ),

            Expanded(
              child: prov.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? RefreshIndicator(
                          onRefresh: prov.refresh,
                          child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 200), Center(child: Text('Chưa có đăng ký'))]),
                        )
                      : RefreshIndicator(
                          onRefresh: prov.refresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final it = items[idx];
                              final reg = it.registration;
                              final activity = it.activity;
                              final role = it.role;
                              final status = (reg.status ?? 'unknown');

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Expanded(child: Text(activity?.title ?? 'Hoạt động', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: _badgeColor(status), borderRadius: BorderRadius.circular(8)), child: Text(status, style: const TextStyle(color: Colors.white)))
                                    ]),
                                    const SizedBox(height: 8),
                                    Text('Vai trò: ${role?.roleName ?? '-'}'),
                                    const SizedBox(height: 6),
                                    Text('Ngày tham gia: ${reg.registrationTime?.toLocal().toString() ?? '-'}'),
                                    const SizedBox(height: 6),
                                    if ((status.toLowerCase()).contains('complete') || (status.toLowerCase()).contains('done'))
                                      Text('Điểm nhận: ${reg.status ?? '-'}'),
                                    const SizedBox(height: 12),
                                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                      TextButton(onPressed: () => Navigator.pushNamed(context, '/activity_detail', arguments: activity?.activityId.toString()), child: const Text('Chi tiết')),
                                      const SizedBox(width: 8),
                                      if (!(status.toLowerCase().contains('cancel') || status.toLowerCase().contains('complete')))
                                        OutlinedButton(onPressed: () => _onCancelPressed(prov, reg.registrationId.toString()), child: const Text('Hủy đăng ký'))
                                    ])
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
            )
          ]);
        }),
      ),
    );
  }

  void _onFilterChanged(String f) {
    setState(() => _filter = f);
    Provider.of<RegistrationsProvider>(context, listen: false).fetchRegistrations(filter: f);
  }

  void _onCancelPressed(RegistrationsProvider prov, String registrationId) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Hủy đăng ký'),
        content: TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Nhập lý do hủy...')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận'))],
      );
    });

    if (ok == true) {
      final reason = reasonCtrl.text.trim();
      final success = await prov.cancelRegistration(registrationId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Hủy thành công' : 'Hủy thất bại')));
    }
  }
}
