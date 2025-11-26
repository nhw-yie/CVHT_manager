// lib/screens/advisor_screens/chat/advisor_conversations_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/dialog_provider.dart';
import '../../../models/conversation.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/avatar_widget.dart';
import '../../../constants/app_colors.dart';

class AdvisorConversationsScreen extends StatefulWidget {
  const AdvisorConversationsScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorConversationsScreen> createState() =>
      _AdvisorConversationsScreenState();
}

class _AdvisorConversationsScreenState
    extends State<AdvisorConversationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final provider = context.read<DialogProvider>();
    await provider.fetchConversations();
    await provider.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tin nhắn',
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        actions: [
          Consumer<DialogProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: Consumer<DialogProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingConversations) {
              return const Center(child: LoadingIndicator());
            }

            if (provider.conversations.isEmpty) {
              return EmptyState(
                icon: Icons.chat_bubble_outline,
                message: 'Chưa có cuộc hội thoại nào',
                actionLabel: 'Tải lại',
                onAction: _loadConversations,
              );
            }

            return ListView.separated(
              itemCount: provider.conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = provider.conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  onTap: () {
                    context.push('/advisor/chat/${conversation.partnerId}', extra: {
                      'studentName': conversation.partnerName,
                      'studentCode': conversation.partnerCode ?? '',
                      'className': conversation.className ?? '',
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    Key? key,
    required this.conversation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          AvatarWidget(
            imageUrl: conversation.partnerAvatar,
            initials: _getInitials(conversation.partnerName),
            radius: 24,
          ),
          if (conversation.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    conversation.unreadCount > 9
                        ? '9+'
                        : '${conversation.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.partnerName,
              style: TextStyle(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.lastMessageTime != null)
            Text(
              _formatTime(conversation.lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.className != null) ...[
            const SizedBox(height: 2),
            Text(
              '${conversation.partnerCode} • ${conversation.className}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (conversation.lastMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              conversation.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? Colors.black87
                    : Colors.grey.shade600,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'vi_VN').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}