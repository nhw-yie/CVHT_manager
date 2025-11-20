// ...existing code...
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/advisor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../models/models.dart';

class AdvisorProfileScreen extends StatefulWidget {
  const AdvisorProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorProfileScreen> createState() => _AdvisorProfileScreenState();
}

class _AdvisorProfileScreenState extends State<AdvisorProfileScreen> {
  File? _avatarFile;
  final _phoneCtrl = TextEditingController();
  bool _editing = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Fetch advisor detail if provider available and auth has id
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final prov = Provider.of<AdvisorProvider?>(context, listen: false);
      final id = auth.currentUser?.id ?? auth.currentUser?.advisorId;
      if (prov != null && id != null) {
        prov.fetchAdvisorDetail(id as int);
        prov.fetchAdvisorClasses(id as int);
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showEditSheet(AdvisorProvider prov, Advisor advisor) {
    _phoneCtrl.text = advisor.phoneNumber ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _submitting = true);
                    final payload = {'phone_number': _phoneCtrl.text.trim()};
                    final ok = await prov.updateAdvisor(advisor.advisorId, payload);
                    setState(() => _submitting = false);
                    if (ok) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thông tin thành công')));
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${prov.error ?? 'Không xác định'}')));
                    }
                  },
                  child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Lưu'),
                )
              ])
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If AdvisorProvider isn't provided by parent route, create a local instance
    final prov = Provider.of<AdvisorProvider?>(context);
    return prov == null
        ? ChangeNotifierProvider(
            create: (_) => AdvisorProvider(),
            child: const AdvisorProfileScreen(), // rebuild with provider available
          )
        : Consumer2<AuthProvider, AdvisorProvider>(
            builder: (ctx, auth, provider, _) {
              final adv = provider.selectedAdvisor ?? (auth.currentUser as Advisor?);
              if (provider.isLoading && adv == null) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (provider.error != null && adv == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Hồ sơ giảng viên'), backgroundColor: AppColors.primary),
                  body: EmptyState(icon: Icons.error_outline, message: provider.error!),
                );
              }
              if (adv == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Hồ sơ giảng viên'), backgroundColor: AppColors.primary),
                  body: const EmptyState(message: 'Không tìm thấy thông tin giảng viên'),
                );
              }

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Hồ sơ giảng viên'),
                  backgroundColor: AppColors.primary,
                  actions: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditSheet(provider, adv)),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(radius: 40, backgroundImage: adv.avatarUrl != null && adv.avatarUrl!.isNotEmpty ? NetworkImage(adv.avatarUrl!) : null, child: adv.avatarUrl == null || adv.avatarUrl!.isEmpty ? Text((adv.fullName ?? 'G').substring(0, 1)) : null),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(adv.fullName ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Mã: ${adv.userCode ?? '-'}'),
                          const SizedBox(height: 4),
                          Text(adv.email ?? '-', style: const TextStyle(color: Colors.black54)),
                        ]),
                      )
                    ]),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Thông tin liên hệ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListTile(title: const Text('Số điện thoại'), subtitle: Text(adv.phoneNumber ?? '-')),
                          ListTile(title: const Text('Đơn vị'), subtitle: Text(adv.unitName ?? '-')),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.classesOfAdvisor.isNotEmpty) Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Các lớp phụ trách', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: provider.classesOfAdvisor.map((c) => Chip(label: Text(c.className))).toList())
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Hoạt động gần đây', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // placeholder: lấy từ provider.selectedAdvisor.activities nếu có
                          Text((provider.selectedAdvisor?.activities ?? []).isEmpty ? 'Không có hoạt động' : (provider.selectedAdvisor?.activities?.map((a)=>a.title).join('\n') ?? '')),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              );
            },
          );
  }
}
// ...existing code...