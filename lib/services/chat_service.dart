import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'api_client.dart';

/// Service managing real-time AI conversation with Amudhu backend.
class ChatService extends ChangeNotifier {
  ChatService._();
  static final ChatService instance = ChatService._();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _conversationId;
  String? _lastFailedMessage;
  Map<String, dynamic>? _activeContext;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get conversationId => _conversationId;
  Map<String, dynamic>? get activeContext => _activeContext;
  bool get hasActiveContext => _activeContext != null && _activeContext!.isNotEmpty;

  void setActiveContext(Map<String, dynamic>? context) {
    _activeContext = context;
    notifyListeners();
  }

  void clearActiveContext() {
    _activeContext = null;
    notifyListeners();
  }

  /// Sends a user message to the backend and handles the AI reply.
  Future<void> sendMessage(String text, {Map<String, dynamic>? contextOverride}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isLoading) return;

    final userMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_user';
    final userMessage = ChatMessage(
      id: userMsgId,
      text: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
      attachedContext: contextOverride ?? _activeContext,
    );

    _messages.add(userMessage);
    _isLoading = true;
    _lastFailedMessage = null;
    notifyListeners();

    // Prepare bounded history for context awareness
    final history = _messages
        .where((m) => !m.isError && !m.isPending && m.id != userMsgId)
        .take(10)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    final payload = <String, dynamic>{
      'message': cleanText,
      'history': history,
      if (_conversationId != null) 'conversationId': _conversationId,
      if ((contextOverride ?? _activeContext) != null)
        'context': contextOverride ?? _activeContext,
    };

    try {
      final response = await ApiClient.instance.post(
        '/api/chat',
        body: payload,
        authenticated: true,
      );

      final reply = response['reply'] as String? ?? 'No response received from Amudhu.';
      if (response['conversationId'] is String) {
        _conversationId = response['conversationId'] as String;
      }

      final assistantMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(assistantMessage);
    } catch (e) {
      _lastFailedMessage = cleanText;
      final errorMessage = _getFriendlyErrorMessage(e);

      final errorChatMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_err',
        text: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      _messages.add(errorChatMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retries sending the last message that failed.
  Future<void> retryLastMessage() async {
    if (_lastFailedMessage == null || _isLoading) return;

    // Remove the trailing error message if present
    if (_messages.isNotEmpty && _messages.last.isError) {
      _messages.removeLast();
    }

    final messageToRetry = _lastFailedMessage!;
    // Remove the pending user message if duplicated
    if (_messages.isNotEmpty && _messages.last.isUser && _messages.last.text == messageToRetry) {
      _messages.removeLast();
    }

    await sendMessage(messageToRetry);
  }

  /// Clears the entire chat history and starts a fresh conversation.
  Future<void> clearConversation() async {
    if (_conversationId != null) {
      try {
        await ApiClient.instance.delete('/api/chat/history/$_conversationId');
      } catch (_) {}
    }
    _messages.clear();
    _conversationId = null;
    _lastFailedMessage = null;
    notifyListeners();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.code == 'RATE_LIMIT_EXCEEDED') {
        return 'Amudhu is receiving many requests. Please wait a moment and try again.';
      }
      if (error.code == 'GATEWAY_TIMEOUT') {
        return 'Request to Amudhu timed out. Please tap retry to try again.';
      }
      if (error.code == 'NETWORK_ERROR' || error.statusCode == 0) {
        return 'Cannot connect to Amudhu API. Please verify your backend server is running and check your network connection.';
      }
      if (error.statusCode == 502 || error.statusCode == 500) {
        return 'Amudhu could not process this request right now. Tap retry to try again.';
      }
      return error.message;
    }
    return 'I couldn’t connect to Amudhu right now. Please check your network connection and try again.';
  }
}
