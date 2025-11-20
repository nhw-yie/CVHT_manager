import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';
import '../constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId; // could be advisor id or conversation id
  final String advisorName;
  final String advisorAvatarUrl;

  const ChatScreen({Key? key, required this.conversationId, required this.advisorName, this.advisorAvatarUrl = ''}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = []; // simple local store (map with keys: id, from, content, type, createdAt, isRead)
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isSending = false;
  bool _isTyping = false;
  int _page = 1;
  bool _hasMore = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
    // polling for new messages every 5s as fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollNewMessages());
    _focusNode.addListener(() {
      setState(() {}); // rebuild to show/hide input if needed
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    await _fetchPage(page: 1);
    if (mounted) setState(() => _isLoading = false);
    // scroll to bottom after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _fetchPage({required int page}) async {
    if (!_hasMore && page != 1) return;
    try {
      final resp = await ApiService.instance.getMessages(query: {'conversation_id': widget.conversationId, 'page': page, 'per_page': 20});
      final data = resp['data'] ?? resp;
      final items = (data['items'] ?? data['messages'] ?? data) as dynamic;
      final List<dynamic> list = items is List ? items : (items is Map && items['data'] is List ? items['data'] : []);

      final parsed = list.map<Map<String, dynamic>>((m) {
        return {
          'id': m['id']?.toString() ?? UniqueKey().toString(),
          'from': m['from'] ?? m['sender'] ?? m['user_id'] ?? 'advisor',
          'content': m['content'] ?? m['text'] ?? '',
          'type': m['type'] ?? (m['attachment'] != null ? 'image' : 'text'),
          'attachment': m['attachment'] ?? m['file'] ?? null,
          'createdAt': DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
          'isRead': m['is_read'] == true || m['read'] == true,
        };
      }).toList();

      if (page == 1) {
        _messages.clear();
        _messages.addAll(parsed.reversed);
      } else {
        // prepend older messages
        _messages.insertAll(0, parsed.reversed);
      }

      _page = page;
      _hasMore = parsed.length >= 20;
      // mark visible messages as read
      _markVisibleMessagesRead();
      if (mounted) setState(() {});
    } catch (e) {
      // ignore or show snackbar
    }
  }

  Future<void> _pollNewMessages() async {
    try {
      final resp = await ApiService.instance.getMessages(query: {'conversation_id': widget.conversationId, 'page': 1, 'per_page': 20});
      final data = resp['data'] ?? resp;
      final items = (data['items'] ?? data['messages'] ?? data) as dynamic;
      final List<dynamic> list = items is List ? items : (items is Map && items['data'] is List ? items['data'] : []);
      if (list.isEmpty) return;
      final newest = list.map((m) => m['id']?.toString()).where((id) => id != null).toSet();
      final localIds = _messages.map((m) => m['id']?.toString()).toSet();
      final diff = newest.difference(localIds);
      if (diff.isNotEmpty) {
        await _fetchPage(page: 1);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent + 50 && !_isLoading && _hasMore) {
      // user scrolled to top, load older
      _fetchPage(page: _page + 1);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final payload = {'conversation_id': widget.conversationId, 'content': text, 'type': 'text'};
      final resp = await ApiService.instance.sendMessage(payload);
      // optimistic add
      final m = resp['data'] ?? resp;
      final entry = {
        'id': m['id']?.toString() ?? UniqueKey().toString(),
        'from': 'me',
        'content': text,
        'type': 'text',
        'createdAt': DateTime.now(),
        'isRead': false,
      };
      _messages.add(entry);
      _textController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      if (mounted) setState(() {});
    } catch (e) {
      // show error
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi tin thất bại')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendAttachment() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      if (res == null || res.files.isEmpty) return;
      final file = res.files.first;
  setState(() => _isSending = true);
  // ideally we would send multipart; here we send placeholder payload with filename/url
      final payload = {'conversation_id': widget.conversationId, 'content': '', 'type': 'image', 'attachment': file.name};
      final resp = await ApiService.instance.sendMessage(payload);
      final m = resp['data'] ?? resp;
      final entry = {
        'id': m['id']?.toString() ?? UniqueKey().toString(),
        'from': 'me',
        'content': '',
        'type': 'image',
        'attachment': file.path,
        'createdAt': DateTime.now(),
        'isRead': false,
      };
      _messages.add(entry);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi ảnh thất bại')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _markVisibleMessagesRead() async {
    try {
      for (final m in _messages) {
        if (m['from'] != 'me' && m['isRead'] == false) {
          final id = m['id']?.toString();
          if (id != null) {
            await ApiService.instance.markMessageRead(id);
            m['isRead'] = true;
          }
        }
      }
      setState(() {});
    } catch (_) {}
  }

  Widget _buildMessageBubble(Map<String, dynamic> m) {
    final fromMe = (m['from'] == 'me');
    final createdAt = m['createdAt'] as DateTime;
    final time = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: fromMe ? AppColors.primary : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (m['type'] == 'text') Text(m['content'] ?? '', style: TextStyle(color: fromMe ? Colors.white : Colors.black87)),
        if (m['type'] == 'image' && m['attachment'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Image.file(File(m['attachment']), width: 180, height: 120, fit: BoxFit.cover),
          ),
        const SizedBox(height: 6),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(time, style: TextStyle(fontSize: 11, color: fromMe ? Colors.white70 : Colors.black54)),
          const SizedBox(width: 6),
          if (fromMe)
            Icon(m['isRead'] == true ? Icons.done_all : Icons.check, size: 14, color: m['isRead'] == true ? Colors.blueAccent : (fromMe ? Colors.white70 : Colors.black54))
        ])
      ]),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromMe) ...[
            CircleAvatar(radius: 16, backgroundImage: widget.advisorAvatarUrl.isNotEmpty ? NetworkImage(widget.advisorAvatarUrl) : null, child: widget.advisorAvatarUrl.isEmpty ? Text(widget.advisorName.isNotEmpty ? widget.advisorName[0] : '?') : null),
            const SizedBox(width: 8),
          ],
          bubble,
        ],
      ),
    );
  }

  List<Widget> _buildMessageList() {
    final children = <Widget>[];
    DateTime? lastDate;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final d = (m['createdAt'] as DateTime).toLocal();
      if (lastDate == null || d.day != lastDate.day || d.month != lastDate.month || d.year != lastDate.year) {
        children.add(Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('${d.day}/${d.month}/${d.year}', style: const TextStyle(color: Colors.grey)))));
        lastDate = d;
      }
      children.add(_buildMessageBubble(m));
    }
    // small bottom padding
    children.add(const SizedBox(height: 12));
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundImage: widget.advisorAvatarUrl.isNotEmpty ? NetworkImage(widget.advisorAvatarUrl) : null, child: widget.advisorAvatarUrl.isEmpty ? Text(widget.advisorName.isNotEmpty ? widget.advisorName[0] : '?') : null),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.advisorName)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.call), onPressed: () {/* TODO: call */})],
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification) {
                      _markVisibleMessagesRead();
                    }
                    return false;
                  },
                  child: ListView(
                    controller: _scrollController,
                    reverse: false,
                    padding: const EdgeInsets.only(top: 8),
                    children: _buildMessageList(),
                  ),
                ),
        ),

        if (_isTyping) const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Đối tác đang gõ...', style: TextStyle(color: Colors.grey))) ,

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: Row(children: [
              IconButton(icon: const Icon(Icons.attach_file), onPressed: _pickAndSendAttachment),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  onChanged: (v) {
                    setState(() => _isTyping = v.isNotEmpty);
                  },
                  onSubmitted: (_) => _sendText(),
                  decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide.none), filled: true, fillColor: Colors.white70, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: _isSending ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.send), onPressed: _isSending ? null : _sendText),
            ]),
          ),
        )
      ]),
    );
  }
}
