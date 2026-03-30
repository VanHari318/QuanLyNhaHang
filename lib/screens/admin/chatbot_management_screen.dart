import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../models/chatbot_model.dart';
import '../../theme/admin_theme.dart';

/// Màn hình quản lý FAQ ChatBot – Haidilao Premium Dark
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

    return Scaffold(
      backgroundColor: AdminColors.bgPrimary(context),
      appBar: AppBar(
        title: const Text('ChatBot FAQ'),
        backgroundColor: AdminColors.bgPrimary(context),
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AdminColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AdminColors.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smart_toy_rounded, size: 16, color: AdminColors.teal),
                  const SizedBox(width: 6),
                   Text(
                    '${provider.entries.length} câu hỏi',
                    style: TextStyle(color: AdminColors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: provider.entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AdminColors.bgElevated(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: AdminColors.borderDefault(context)),
                    ),
                    child: Icon(Icons.chat_bubble_outline_rounded,
                        size: 64, color: AdminColors.textMuted(context)),
                  ),
                  const SizedBox(height: 24),
                  Text('Chưa có câu hỏi nào',
                      style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: provider.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _FaqCard(
                entry: provider.entries[i],
                onEdit: () =>
                    _showDialog(context, entry: provider.entries[i]),
                onDelete: () => _confirmDelete(
                    context, provider.entries[i], provider),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminColors.crimson,
        foregroundColor: Colors.white,
        onPressed: () => _showDialog(context),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Thêm câu hỏi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatBotModel entry, ChatbotProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.bgCard(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AdminColors.borderDefault(context)),
        ),
        title: Text('Xóa dữ liệu', style: AdminText.h1(context).copyWith(color: AdminColors.error)),
        content: Text('Chắc chắn xóa câu hỏi FAQ này khỏi ChatBot?', style: TextStyle(color: AdminColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: AdminColors.textSecondary(context))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteEntry(entry.id);
            },
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {ChatBotModel? entry}) {
    final qCtrl = TextEditingController(text: entry?.question);
    final aCtrl = TextEditingController(text: entry?.answer);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.bgCard(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AdminColors.borderDefault(context)),
        ),
        title: Text(entry == null ? 'Thêm FAQ mới' : 'Sửa câu hỏi FAQ', style: AdminText.h1(context)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: qCtrl,
            maxLines: 2,
            style: TextStyle(color: AdminColors.textPrimary(context), fontWeight: FontWeight.bold),
            decoration: _inputDeco(context, 'Nhập câu hỏi FAQ *', Icons.help_outline_rounded),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: aCtrl,
            maxLines: 4,
            style: TextStyle(color: AdminColors.textPrimary(context)),
            decoration: _inputDeco(context, 'Nhập câu trả lời *', Icons.chat_bubble_outline_rounded).copyWith(alignLabelWithHint: true),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: AdminColors.textSecondary(context)))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.crimson,
              foregroundColor: Colors.white,
            ),
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
            child: Text(entry == null ? 'Thêm mới' : 'Lưu cập nhật', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

  InputDecoration _inputDeco(BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AdminColors.textSecondary(context)),
      prefixIcon: Icon(icon, color: AdminColors.textSecondary(context)),
      filled: true,
      fillColor: AdminColors.bgElevated(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AdminColors.borderDefault(context))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AdminColors.borderDefault(context))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminColors.crimson)),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.bgCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _expanded ? AdminColors.teal.withValues(alpha: 0.5) : AdminColors.borderDefault(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: AdminColors.teal, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(widget.entry.question,
                        style: AdminText.h3(context),
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AdminColors.teal, size: 20),
                        onPressed: widget.onEdit,
                        style: IconButton.styleFrom(backgroundColor: AdminColors.bgElevated(context)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.error, size: 20),
                        onPressed: widget.onDelete,
                        style: IconButton.styleFrom(backgroundColor: AdminColors.error.withValues(alpha: 0.1)),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: AdminColors.textSecondary(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminColors.bgPrimary(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.borderDefault(context)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: AdminColors.gold, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.entry.answer,
                        style: TextStyle(color: AdminColors.textSecondary(context), height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
