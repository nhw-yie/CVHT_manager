// lib/screens/advisor_screens/chat/advisor_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/dialog_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/empty_state.dart';
import '../../../constants/app_colors.dart';
import '../../../models/dialog_message.dart';

class AdvisorChatScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String studentCode;
  final String className;

  const AdvisorChatScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.className,
  }) : super(key: key);

  @override
  State<AdvisorChatScreen> createState() => _AdvisorChatScreenState();
}

class _AdvisorChatScreenState extends State<AdvisorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  List<DialogMessage> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final provider = context.read<DialogProvider>();
    await provider.fetchMessages(widget.studentId);
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
      partnerId: widget.studentId,
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

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final provider = context.read<DialogProvider>();
    final results = await provider.searchMessages(
      partnerId: widget.studentId,
      keyword: keyword,
    );

    setState(() {
      _searchResults = results;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.studentName,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${widget.studentCode} • ${widget.className}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(),
          Expanded(
            child: _isSearching && _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tin nhắn...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final message = _searchResults[index];
        final isSentByMe = message.senderType == 'advisor';

        return _MessageBubble(
          message: message,
          isSentByMe: isSentByMe,
          searchKeyword: _searchController.text,
        );
      },
    );
  }

  Widget _buildMessageList() {
    return Consumer<DialogProvider>(
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
            final isSentByMe = message.senderType == 'advisor';

            return _MessageBubble(
              message: message,
              isSentByMe: isSentByMe,
              onDelete: isSentByMe ? () => _deleteMessage(message.messageId) : null,
            );
          },
        );
      },
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
  final String? searchKeyword;

  const _MessageBubble({
    Key? key,
    required this.message,
    required this.isSentByMe,
    this.onDelete,
    this.searchKeyword,
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
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 16, color: AppColors.secondary),
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
                    _buildContent(context),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.sentAt),
                          style: TextStyle(
                            color: isSentByMe
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        if (isSentByMe && message.isRead) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
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

  Widget _buildContent(BuildContext context) {
    if (searchKeyword == null || searchKeyword!.isEmpty) {
      return Text(
        message.content,
        style: TextStyle(
          color: isSentByMe ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      );
    }

    // Highlight search keyword
    final text = message.content;
    final keyword = searchKeyword!.toLowerCase();
    final lowerText = text.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    while (start < text.length) {
      final index = lowerText.indexOf(keyword, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.shade200,
          color: Colors.black,
        ),
      ));

      start = index + keyword.length;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isSentByMe ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        children: spans,
      ),
    );
  }
}