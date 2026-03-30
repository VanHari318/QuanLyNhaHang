import 'package:flutter/material.dart';
import '../models/inventory_model.dart';

/// Inventory row card with low-stock detection at < 20% of maxQuantity.
class InventoryItemCard extends StatelessWidget {
  final InventoryModel item;
  final bool isLow;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.isLow = false,
    this.onImport,
    this.onExport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLow ? cs.errorContainer : cs.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: isLow ? cs.onErrorContainer : cs.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
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
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          if (isLow)
                            _LowStockBadge(cs: cs),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số lượng: ${_formatQty(item.quantity)} ${item.unit}',
                        style: TextStyle(
                          color: isLow ? cs.error : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  String _formatQty(double qty) {
    return qty.toStringAsFixed(2);
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
