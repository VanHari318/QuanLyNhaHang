import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../providers/menu_provider.dart';

class CustomerChatbotScreen extends StatefulWidget {
  const CustomerChatbotScreen({super.key});

  @override
  State<CustomerChatbotScreen> createState() => _CustomerChatbotScreenState();
}

class _CustomerChatbotScreenState extends State<CustomerChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final chatbotProvider = context.watch<ChatbotProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý Vị Lai', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: chatbotProvider.history.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildBotMessage(cs, 'Xin chào! Tôi là trợ lý ảo của Vị Lai Quán. Hôm nay bạn muốn ăn gì?');
                }
                
                final msg = chatbotProvider.history[index - 1];
                final isBot = msg['role'] == 'bot';
                
                return isBot 
                  ? _buildBotMessage(cs, msg['content']!)
                  : _buildUserMessage(cs, msg['content']!);
              },
            ),
          ),
          
          // 2. Suggestions
          _buildQuickSuggestions(context, chatbotProvider),
          
          // 3. Input Area
          _buildInputArea(cs, chatbotProvider),
        ],
      ),
    );
  }

  Widget _buildBotMessage(ColorScheme cs, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 64),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildUserMessage(ColorScheme cs, String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 64),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildQuickSuggestions(BuildContext context, ChatbotProvider provider) {
    final suggestions = ['Gợi ý món lẩu', 'Món nào best-seller?', 'Món tráng miệng', 'Liên hệ quán'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          onPressed: () => _sendMessage(context, provider, suggestions[i]),
          label: Text(suggestions[i]),
          backgroundColor: Colors.white,
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme cs, ChatbotProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onSubmitted: (val) => _sendMessage(context, provider, val),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: () => _sendMessage(context, provider, _messageController.text),
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(minimumSize: const Size(54, 54)),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, ChatbotProvider provider, String text) {
    if (text.trim().isEmpty) return;
    
    final menuProvider = context.read<MenuProvider>();
    provider.processMessage(text, menuProvider.allItems);
    _messageController.clear();
    
    // Auto-scroll logic (provider will notifyListeners when bot adds a message)
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
