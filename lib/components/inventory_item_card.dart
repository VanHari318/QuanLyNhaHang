import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_model.dart';
import '../providers/inventory_provider.dart';

/// Inventory row card with smart low-stock detection (sufficient for 20 servings).
class InventoryItemCard extends StatelessWidget {
  final InventoryModel item;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.onImport,
    this.onExport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final invProvider = context.watch<InventoryProvider>();
    
    final isLow = invProvider.isLowStock(item);

    final percent = item.maxQuantity > 0
        ? (item.quantity / item.maxQuantity).clamp(0.0, 1.0)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isLow ? cs.errorContainer : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: isLow ? cs.onErrorContainer : cs.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Name & quantity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          if (isLow)
                            _LowStockBadge(cs: cs),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatQty(item.quantity)} ${item.unit}',
                        style: TextStyle(
                          color: isLow ? cs.error : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionBtn(
                      icon: Icons.add_box_rounded,
                      color: Colors.green,
                      tooltip: 'Nhập kho',
                      onTap: onImport,
                    ),
                    _ActionBtn(
                      icon: Icons.remove_circle_outline_rounded,
                      color: cs.error,
                      tooltip: 'Xuất kho',
                      onTap: onExport,
                    ),
                    if (onDelete != null)
                      _ActionBtn(
                        icon: Icons.delete_outline_rounded,
                        color: cs.outlineVariant,
                        tooltip: 'Xóa',
                        onTap: onDelete,
                      ),
                  ],
                ),
              ],
            ),
            // Stock progress bar đã được loại bỏ theo yêu cầu của người dùng
          ],
        ),
      ),
    );
  }

  String _formatQty(double qty) {
    return qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(1);
  }
}

class _LowStockBadge extends StatefulWidget {
  final ColorScheme cs;
  const _LowStockBadge({required this.cs});

  @override
  State<_LowStockBadge> createState() => _LowStockBadgeState();
}

class _LowStockBadgeState extends State<_LowStockBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: widget.cs.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '⚠️ Sắp hết',
          style: TextStyle(
            color: widget.cs.onErrorContainer,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(6),
    );
  }
}
