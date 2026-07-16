import '../../../core/network/api_client.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String sender; // "user" | "bot"
  final String message;
  final DateTime createdAt;

  bool get isUser => sender == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: json['sender'] as String? ?? 'bot',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  /// GET /api/chat/messages — backend đã trả oldest → newest.
  Future<List<ChatMessage>> getMessages() async {
    final response = Map<String, dynamic>.from(
      await _client.get('/api/chat/messages') as Map,
    );

    final data = response['data'];
    if (data is! List) return [];

    return data
        .map(
          (item) =>
              ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// POST /api/chat/messages — trả [userMessage, botMessage].
  Future<List<ChatMessage>> sendMessage(String text) async {
    final response = Map<String, dynamic>.from(
      await _client.post('/api/chat/messages', {'message': text}) as Map,
    );

    final data = Map<String, dynamic>.from(response['data'] as Map);
    final userMessage = ChatMessage.fromJson(
      Map<String, dynamic>.from(data['userMessage'] as Map),
    );
    final botMessage = ChatMessage.fromJson(
      Map<String, dynamic>.from(data['botMessage'] as Map),
    );

    return [userMessage, botMessage];
  }
}
