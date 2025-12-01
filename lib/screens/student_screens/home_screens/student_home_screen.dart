import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// migrated to use Theme colors
import '../../../providers/meeting_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider_student.dart';
import '../../../providers/points_provider.dart';
import '../../../providers/enhanced_points_provider.dart';
import '../../../models/models.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  static const List<_FeatureItem> _features = [
    _FeatureItem('Thông báo', Icons.notifications, '/notifications'),
    _FeatureItem('Điểm số', Icons.grade, '/student/points'),
    _FeatureItem('Hoạt động', Icons.event, '/activities'),
    _FeatureItem('Họp lớp', Icons.people, '/student/meetings'),
    _FeatureItem('Chat CVHT', Icons.chat, '/messages'),
    _FeatureItem('Lịch', Icons.calendar_month, '/calendar'),
  ];

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Ensure global providers are primed when the home screen appears
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final notifProv = Provider.of<NotificationsProvider>(context, listen: false);
          notifProv.fetchAll();
          notifProv.fetchUnread();
        } catch (_) {}

        try {
          final meetingProv = Provider.of<MeetingProvider>(context, listen: false);
          // Trigger a fetch but avoid noisy errors if provider isn't available yet
          meetingProv.fetchMeetings();
        } catch (_) {}
        try {
          final enhancedProv = Provider.of<EnhancedPointsProvider>(context, listen: false);
          // Ensure we have current semester and points for the home summary
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await enhancedProv.fetchCurrentSemester();
              if (enhancedProv.selectedSemesterId != null) {
                await enhancedProv.fetchPointsForSemester(enhancedProv.selectedSemesterId!);
              } else {
                await enhancedProv.fetchSemesters();
                if (enhancedProv.selectedSemesterId != null) {
                  await enhancedProv.fetchPointsForSemester(enhancedProv.selectedSemesterId!);
                }
              }
            } catch (_) {}
          });
        } catch (_) {}
      });
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: const Text('Trang chủ'),
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
          actions: [
            Consumer<NotificationsProvider>(
              builder: (context, notif, _) {
                final count = notif.unreadCount;
                return IconButton(
                  onPressed: () => context.go('/student/notifications'),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications),
                      if (count > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              count > 99 ? '99+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final avatar = auth.currentUser?.avatarUrl;
                return IconButton(
                  onPressed: () => context.go('/student/profile'),
                  icon: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        avatar != null && avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : null,
                    child:
                        avatar == null || avatar.isEmpty
                            ? Text(
                              (auth.currentUser?.fullName ?? 'U')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                            : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Consumer2<AuthProvider, NotificationsProvider>(
            builder: (context, auth, notifs, _) {
              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    auth.checkAuthStatus(),
                    notifs.fetchAll(),
                    notifs.fetchUnread(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildWelcomeSection(auth.currentUser, context),
                    const SizedBox(height: 12),
                    _buildSummaryCard(context),
                    const SizedBox(height: 16),
                    _buildFeatureGrid(context),
                    const SizedBox(height: 20),
                    _buildLatestNotificationsSection(notifs),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildWelcomeSection(User? user, BuildContext context) {
    final name = user?.fullName ?? 'Sinh viên';
    final code = user?.userCode ?? 'MSSV';
    final className = 'Lớp A'; // placeholder

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào,', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'MSSV: $code',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Lớp: $className',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    Widget _stat(String label, String value, {Color? color}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );

    return Consumer2<PointsProvider, EnhancedPointsProvider>(
      builder: (ctx, p, enhanced, _) {
        final loading = p.isLoading || enhanced.isLoadingPoints;

        // Prefer enhanced provider's semester-scoped points summary when available
        final trainingDouble = enhanced.pointsSummary?.totalTrainingPoints ?? p.summary?.totalTrainingPoints ?? 0.0;
        final socialDouble = enhanced.pointsSummary?.totalSocialPoints ?? p.summary?.totalSocialPoints ?? 0.0;

        final trainingText = loading ? '...' : trainingDouble.toStringAsFixed(0);
        final socialText = loading ? '...' : socialDouble.toStringAsFixed(1);

        return Card(
          color: Theme.of(ctx).cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _stat('GPA', '—', color: Theme.of(context).colorScheme.primary)),
                Expanded(child: _stat('Số tín chỉ', '—')),
                Expanded(child: _stat('Điểm rèn luyện', trainingText)),
                Expanded(child: _stat('Điểm CTXH', socialText)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
            children:
              StudentHomeScreen._features.map((f) {
                // For meetings tile, show upcoming count badge and rebuild when meetings change
                if (f.route == '/student/meetings') {
                  return Consumer<MeetingProvider>(
                    builder: (context, meetingProv, _) {
                      // If we have no meetings and not currently loading, trigger a fetch once
                      if (meetingProv.meetings.isEmpty && !meetingProv.isLoading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          meetingProv.fetchMeetings();
                        });
                      }

                      final now = DateTime.now();
                      final upcomingCount = meetingProv.meetings.where((m) {
                        return m.status == 'scheduled' &&
                            m.meetingTime.isAfter(now) &&
                            m.meetingTime.isBefore(now.add(const Duration(hours: 24)));
                      }).length;

                      return InkWell(
                        onTap: () => context.go(f.route),
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Icon(f.icon, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  f.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            if (upcomingCount > 0)
                              Positioned(
                                right: 8,
                                top: 6,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.redAccent,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      upcomingCount > 99 ? '99+' : upcomingCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return InkWell(
                  onTap: () => context.go(f.route),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(f.icon, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildLatestNotificationsSection(NotificationsProvider prov) {
    final latest = prov.allNotifications.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông báo mới nhất',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children:
                  latest.isEmpty
                      ? [const ListTile(title: Text('Không có thông báo mới'))]
                      : latest.map((n) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          title: Text(n.title),
                          subtitle: Text(n.summary),
                          trailing: Text(_formatDate(n.createdAt)),
                          onTap: () => prov.markAsRead(n),
                        );
                      }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0)
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _FeatureItem {
  final String label;
  final IconData icon;
  final String route;

  const _FeatureItem(this.label, this.icon, this.route);
}
