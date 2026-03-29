import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/table_model.dart';
import '../../models/dish_model.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';

/// Màn hình đặt món cho waiter – dùng DishModel (API mới)
class OrderingScreen extends StatefulWidget {
  final TableModel table;
  const OrderingScreen({super.key, required this.table});

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final Map<DishModel, int> _cart = {};

  void _addToCart(DishModel dish) {
    setState(() {
      _cart[dish] = (_cart[dish] ?? 0) + 1;
    });
  }

  void _removeFromCart(DishModel dish) {
    setState(() {
      if ((_cart[dish] ?? 0) <= 1) {
        _cart.remove(dish);
      } else {
        _cart[dish] = _cart[dish]! - 1;
      }
    });
  }

  double get _totalPrice {
    return _cart.entries.fold(0, (sum, e) => sum + (e.key.price * e.value));
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;

    final items = _cart.entries
        .map((e) => OrderItem(dish: e.key, quantity: e.value))
        .toList();

    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: OrderType.dine_in,
      tableId: widget.table.id,
      items: items,
      totalPrice: _totalPrice,
      status: OrderStatus.pending,
    );

    if (!mounted) return;
    await Provider.of<OrderProvider>(context, listen: false).placeOrder(order);
    await Provider.of<TableProvider>(context, listen: false)
        .updateStatus(widget.table.id, TableStatus.occupied);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi order vào bếp 🍳')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final cs = Theme.of(context).colorScheme;
    // Dùng allItems (tất cả món còn dùng được)
    final dishes = menuProvider.allItems.where((d) => d.isAvailable).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.table.name} – Gọi món'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: dishes.length,
              itemBuilder: (ctx, i) {
                final dish = dishes[i];
                final qty = _cart[dish] ?? 0;
                return Card(
                  child: ListTile(
                    leading: dish.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(dish.imageUrl,
                                width: 48, height: 48, fit: BoxFit.cover),
                          )
                        : Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.fastfood_rounded,
                                color: cs.onSurfaceVariant),
                          ),
                    title: Text(dish.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${dish.price.toInt()}đ'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (qty > 0) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: cs.error,
                            onPressed: () => _removeFromCart(dish),
                          ),
                          Text('$qty',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                  fontSize: 16)),
                        ],
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: cs.primary,
                          onPressed: () => _addToCart(dish),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Cart summary
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -3))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tổng cộng',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('${_totalPrice.toInt()}đ',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: cs.primary, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Gửi vào bếp'),
                      onPressed: _placeOrder,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
