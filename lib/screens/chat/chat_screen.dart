import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../services/chat_service.dart';

class _ChatMessage {
  final String text;
  final bool fromUser;
  _ChatMessage(this.text, this.fromUser);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      "Hi! I'm the BookVerse Assistant. Ask me about books, your orders, "
      "your cart, or how anything in the app works.",
      false,
    ),
  ];
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text, true));
      _sending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final cart = context.read<CartProvider>().items;
      final reply = await _chatService.sendMessage(
        sessionId: _sessionId,
        message: text,
        cart: cart,
      );
      setState(() => _messages.add(_ChatMessage(reply, false)));
    } catch (e) {
      debugPrint('ChatScreen: assistant request failed: $e');
      setState(() => _messages.add(_ChatMessage(
            "Sorry, I couldn't reach the assistant right now.\n(${e.toString()})",
            false,
          )));
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? AppColors.ink : AppColors.paperSurface,
      appBar: AppBar(
        title: const Text('BookVerse Assistant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return _buildBubble('Typing…', false, dark, isTyping: true);
                  }
                  final m = _messages[i];
                  return FadeInUp(
                    duration: const Duration(milliseconds: 250),
                    child: _buildBubble(m.text, m.fromUser, dark),
                  );
                },
              ),
            ),
            _buildInputBar(dark),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool fromUser, bool dark, {bool isTyping = false}) {
    final bg = fromUser
        ? AppColors.primary
        : (dark ? AppColors.surfaceRaised : Colors.white);
    final fg = fromUser ? Colors.white : (dark ? Colors.white : Colors.black87);

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromUser ? 18 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? AppColors.espresso : AppColors.paperSurface,
        border: Border(
          top: BorderSide(
            color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Ask about books, orders, your cart…',
                filled: true,
                fillColor: dark ? AppColors.surfaceRaised : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sending ? null : _send,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
