import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/chat_api.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatApi _api;
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  bool _isLoading = true;
  bool _isSending = false;
  String? _loadError;
  bool _isVi = false; // mặc định English để đồng bộ với phần còn lại của app

  @override
  void initState() {
    super.initState();
    _api = ChatApi(ApiClient());
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  String t(String en, String vi) => _isVi ? vi : en;

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final messages = await _api.getMessages();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    // Optimistic user bubble (id tạm tới khi server xác nhận).
    final local = ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      message: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(local);
      _isSending = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      final result = await _api.sendMessage(text);
      if (!mounted) return;

      setState(() {
        final index = _messages.indexOf(local);
        if (index >= 0) {
          _messages[index] = result[0]; // thay bằng user message thật
        } else {
          _messages.add(result[0]);
        }
        _messages.add(result[1]); // bot reply
        _isSending = false;
      });
      _scrollToBottom();
      _inputFocus.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.remove(local);
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      _inputController.text = text; // khôi phục lại text chưa gửi
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F2),
      appBar: AppBar(
        title: Text(t('Support', 'Hỗ trợ')),
        backgroundColor: const Color(0xFFF7F7F2),
        actions: [
          IconButton(
            tooltip: _isVi ? 'English' : 'Tiếng Việt',
            icon: const Icon(Icons.translate),
            onPressed: () => setState(() => _isVi = !_isVi),
          ),
          IconButton(
            tooltip: t('Refresh', 'Tải lại'),
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          if (!_isLoading && _loadError == null) _buildSuggestions(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t('Could not load messages', 'Không tải được tin nhắn'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_loadError!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadHistory,
            child: Text(t('Try again', 'Thử lại')),
          ),
        ],
      );
    }

    if (_messages.isEmpty) return _buildEmpty();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _MessageBubble(message: _messages[index]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent, size: 56, color: Color(0xFF1F7A5A)),
            const SizedBox(height: 12),
            Text(
              t('How can we help?', 'Chúng tôi có thể giúp gì?'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              t(
                'Ask about practice, goals, lessons, VIP or payments.',
                'Hỏi về luyện tập, mục tiêu, bài học, VIP hoặc thanh toán.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    // Các từ khóa này backend chatbot đều nhận diện được (bỏ dấu + vi/en).
    final labels = _isVi
        ? ['VIP', 'Luyện tập', 'Mục tiêu', 'Bài học']
        : ['VIP', 'Practice', 'Goals', 'Lessons'];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: labels
            .map(
              (label) => ActionChip(
                label: Text(label),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF1F7A5A)),
                labelStyle: const TextStyle(color: Color(0xFF1F7A5A)),
                onPressed: _isSending ? null : () => _sendMessage(label),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: t('Type a message…', 'Nhập tin nhắn…'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F1),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: _isSending ? null : () => _sendMessage(),
              icon: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1F7A5A),
                      ),
                    )
                  : const Icon(Icons.send, color: Color(0xFF1F7A5A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF163B32),
              child: Icon(Icons.support_agent, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1F7A5A) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
