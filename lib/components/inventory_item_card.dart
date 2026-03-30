import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../theme/admin_theme.dart';

/// Inventory row card with low-stock detection at < 20% of maxQuantity - Haidilao Premium Dark
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLow ? AdminColors.error.withValues(alpha: 0.5) : AdminColors.borderDefault,
          width: isLow ? 1.5 : 1,
        ),
        boxShadow: isLow 
          ? [BoxShadow(color: AdminColors.error.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)]
          : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isLow ? AdminColors.error.withValues(alpha: 0.15) : AdminColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLow ? AdminColors.error.withValues(alpha: 0.3) : AdminColors.teal.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: isLow ? AdminColors.error : AdminColors.teal,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
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
                        style: AdminText.h2,
                      ),
                    ),
                    if (isLow) const _LowStockBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    text: 'Số lượng: ',
                    style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${_formatQty(item.quantity)} ${item.unit}',
                        style: TextStyle(
                          color: isLow ? AdminColors.error : AdminColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                color: AdminColors.success,
                bgColor: AdminColors.success.withValues(alpha: 0.1),
                tooltip: 'Nhập kho',
                onTap: onImport,
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.remove_circle_outline_rounded,
                color: AdminColors.warning,
                bgColor: AdminColors.warning.withValues(alpha: 0.1),
                tooltip: 'Xuất kho',
                onTap: onExport,
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: AdminColors.error,
                  bgColor: AdminColors.error.withValues(alpha: 0.1),
                  tooltip: 'Xóa',
                  onTap: onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatQty(double qty) {
    return qty.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
  }
}

class _LowStockBadge extends StatefulWidget {
  const _LowStockBadge();

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.error.withValues(alpha: 0.3)),
        ),
        child: const Text(
          '⚠️ BÁO ĐỘNG HẾT',
          style: TextStyle(
            color: AdminColors.error,
            fontSize: 9,
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
  final Color bgColor;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
