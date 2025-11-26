// lib/screens/student_screens/chat/student_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/dialog_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../models/dialog_message.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/empty_state.dart';
import '../../../constants/app_colors.dart';

class StudentChatScreen extends StatefulWidget {
  final int advisorId;
  final String advisorName;

  const StudentChatScreen({
    Key? key,
    required this.advisorId,
    required this.advisorName,
  }) : super(key: key);

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final provider = context.read<DialogProvider>();
    await provider.fetchMessages(widget.advisorId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<DialogProvider>();
    final success = await provider.sendMessage(
      partnerId: widget.advisorId,
      content: content,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.advisorName,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<DialogProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMessages) {
                  return const Center(child: LoadingIndicator());
                }

                if (provider.messages.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline,
                    message: 'Chưa có tin nhắn nào',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isSentByMe = message.senderType == 'student';

                    return _MessageBubble(
                      message: message,
                      isSentByMe: isSentByMe,
                      onDelete: isSentByMe
                          ? () => _deleteMessage(message.messageId)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<DialogProvider>(
              builder: (context, provider, child) {
                return FloatingActionButton(
                  mini: true,
                  onPressed: provider.isSending ? null : _sendMessage,
                  backgroundColor: AppColors.primary,
                  child: provider.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 20),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(int messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn'),
        content: const Text('Bạn có chắc muốn xóa tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<DialogProvider>();
      await provider.deleteMessage(messageId);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final DialogMessage message;
  final bool isSentByMe;
  final VoidCallback? onDelete;

  const _MessageBubble({
    Key? key,
    required this.message,
    required this.isSentByMe,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSentByMe
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: isSentByMe ? const Radius.circular(4) : null,
                    bottomLeft: !isSentByMe ? const Radius.circular(4) : null,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isSentByMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.sentAt),
                      style: TextStyle(
                        color: isSentByMe
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSentByMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}