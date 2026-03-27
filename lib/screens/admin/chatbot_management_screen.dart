import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../models/chatbot_model.dart';

/// Màn hình quản lý FAQ ChatBot – MD3
class ChatbotManagementScreen extends StatelessWidget {
  const ChatbotManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChatbotBody();
  }
}

class _ChatbotBody extends StatelessWidget {
  const _ChatbotBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatbotProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatBot FAQ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(Icons.smart_toy_rounded, size: 16, color: cs.primary),
              label: Text('${provider.entries.length} câu hỏi',
                  style: TextStyle(color: cs.primary)),
              backgroundColor: cs.primaryContainer,
            ),
          ),
        ],
      ),
      body: provider.entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Chưa có câu hỏi nào',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _FaqCard(
                entry: provider.entries[i],
                onEdit: () =>
                    _showDialog(context, entry: provider.entries[i]),
                onDelete: () =>
                    provider.deleteEntry(provider.entries[i].id),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Thêm câu hỏi'),
      ),
    );
  }

  void _showDialog(BuildContext context, {ChatBotModel? entry}) {
    final qCtrl = TextEditingController(text: entry?.question);
    final aCtrl = TextEditingController(text: entry?.answer);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(entry == null ? 'Thêm FAQ' : 'Sửa FAQ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: qCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Câu hỏi *',
              prefixIcon: Icon(Icons.help_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Câu trả lời *',
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
              alignLabelWithHint: true,
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (qCtrl.text.isEmpty || aCtrl.text.isEmpty) return;
              final model = ChatBotModel(
                id: entry?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                question: qCtrl.text.trim(),
                answer: aCtrl.text.trim(),
              );
              final provider = context.read<ChatbotProvider>();
              if (entry == null) {
                await provider.addEntry(model);
              } else {
                await provider.updateEntry(model);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(entry == null ? 'Thêm' : 'Lưu'),
          ),
        ],
      ),
    );
  }
}

// ── FAQ card ──────────────────────────────────────────────────────────────────
class _FaqCard extends StatefulWidget {
  final ChatBotModel entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FaqCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.help_outline_rounded, color: cs.onPrimaryContainer, size: 18),
            ),
            title: Text(widget.entry.question,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? null : TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: Icon(Icons.edit_rounded, color: cs.primary, size: 20),
                    onPressed: widget.onEdit),
                IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: cs.error, size: 20),
                    onPressed: widget.onDelete),
                IconButton(
                  icon: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: cs.secondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.entry.answer,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
