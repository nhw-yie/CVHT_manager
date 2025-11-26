// lib/providers/dialog_provider.dart

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/conversation.dart';
import '../models/dialog_message.dart';
import '../utils/error_handler.dart';

/// Provider for Dialog/Messaging functionality
/// Works for both Student and Advisor roles
class DialogProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // Conversations list
  List<Conversation> _conversations = [];
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  // Current conversation
  Conversation? _currentConversation;
  Conversation? get currentConversation => _currentConversation;

  // Messages in current conversation
  List<DialogMessage> _messages = [];
  List<DialogMessage> get messages => List.unmodifiable(_messages);

  // Unread count (for badge)
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Loading states
  bool _isLoadingConversations = false;
  bool get isLoadingConversations => _isLoadingConversations;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _error;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Fetch conversations list
  Future<void> fetchConversations() async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await _api.getConversations();
      final data = resp['data'] ?? resp;

      if (data is List) {
        _conversations = data
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _conversations = [];
      }
    } catch (e) {
      _error = _extractError(e);
      _conversations = [];
      if (kDebugMode) debugPrint('DialogProvider.fetchConversations error: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Fetch messages with a specific partner
  /// AUTO marks messages from partner as read
  Future<void> fetchMessages(int partnerId) async {
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await _api.getDialogMessages(partnerId: partnerId);
      final data = resp['data'] ?? resp;

      if (data is List) {
        _messages = data
            .map((e) => DialogMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _messages = [];
      }

      // Update current conversation
      _currentConversation = _conversations.firstWhere(
        (c) => c.partnerId == partnerId,
        orElse: () => Conversation(
          conversationId: partnerId,
          partnerId: partnerId,
          partnerName: 'Unknown',
          partnerType: 'student',
          unreadCount: 0,
        ),
      );

      // Update unread count for this conversation
      final idx = _conversations.indexWhere((c) => c.partnerId == partnerId);
      if (idx != -1) {
        _conversations[idx] = Conversation(
          conversationId: _conversations[idx].conversationId,
          partnerId: _conversations[idx].partnerId,
          partnerName: _conversations[idx].partnerName,
          partnerAvatar: _conversations[idx].partnerAvatar,
          partnerType: _conversations[idx].partnerType,
          partnerCode: _conversations[idx].partnerCode,
          className: _conversations[idx].className,
          lastMessage: _conversations[idx].lastMessage,
          lastMessageTime: _conversations[idx].lastMessageTime,
          unreadCount: 0, // reset to 0 after reading
        );
      }
    } catch (e) {
      _error = _extractError(e);
      _messages = [];
      if (kDebugMode) debugPrint('DialogProvider.fetchMessages error: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Send a message to partner
  Future<bool> sendMessage({
    required int partnerId,
    required String content,
    String? attachmentPath,
  }) async {
    if (content.trim().isEmpty) {
      _error = 'Nội dung tin nhắn không được để trống';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await _api.sendDialogMessage(
        partnerId: partnerId,
        content: content,
        attachmentPath: attachmentPath,
      );

      final data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) {
        final newMsg = DialogMessage.fromJson(data);
        _messages.add(newMsg);

        // Update conversation's last message
        final idx = _conversations.indexWhere((c) => c.partnerId == partnerId);
        if (idx != -1) {
          _conversations[idx] = Conversation(
            conversationId: _conversations[idx].conversationId,
            partnerId: _conversations[idx].partnerId,
            partnerName: _conversations[idx].partnerName,
            partnerAvatar: _conversations[idx].partnerAvatar,
            partnerType: _conversations[idx].partnerType,
            partnerCode: _conversations[idx].partnerCode,
            className: _conversations[idx].className,
            lastMessage: content,
            lastMessageTime: newMsg.sentAt,
            unreadCount: _conversations[idx].unreadCount,
          );
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('DialogProvider.sendMessage error: $e');
      notifyListeners();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Delete a message (only sender can delete)
  Future<bool> deleteMessage(int messageId) async {
    try {
      await _api.deleteDialogMessage(messageId);
      _messages.removeWhere((m) => m.messageId == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('DialogProvider.deleteMessage error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Fetch unread message count
  Future<void> fetchUnreadCount() async {
    try {
      final resp = await _api.getUnreadMessageCount();
      final data = resp['data'] ?? resp;
      if (data is Map && data['unread_count'] != null) {
        _unreadCount = int.tryParse(data['unread_count'].toString()) ?? 0;
      } else {
        _unreadCount = 0;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('DialogProvider.fetchUnreadCount error: $e');
    }
  }

  /// Search messages in current conversation
  Future<List<DialogMessage>> searchMessages({
    required int partnerId,
    required String keyword,
  }) async {
    if (keyword.trim().isEmpty) return [];

    try {
      final resp = await _api.searchDialogMessages(
        partnerId: partnerId,
        keyword: keyword,
      );
      final data = resp['data'] ?? resp;

      if (data is List) {
        return data
            .map((e) => DialogMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('DialogProvider.searchMessages error: $e');
      return [];
    }
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  String _extractError(Object e) {
    try {
      return ErrorHandler.mapToMessage(e);
    } catch (_) {
      return e.toString();
    }
  }
}