import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/table_model.dart';
import '../../models/dish_model.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/role_themes.dart';
import '../../utils/recipe_helper.dart';

/// Màn hình gọi món cho waiter – Sky-Fresh (Electric Blue)
class OrderingScreen extends StatefulWidget {
  final TableModel table;
  const OrderingScreen({super.key, required this.table});

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen>
    with SingleTickerProviderStateMixin {
  final Map<DishModel, int> _cart = {};
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _addToCart(DishModel dish) {
    setState(() {
      _cart[dish] = (_cart[dish] ?? 0) + 1;
    });
    if (_cart.length == 1 && _cart.values.first == 1) {
      _slideController.forward();
    }
  }

  void _removeFromCart(DishModel dish) {
    setState(() {
      if ((_cart[dish] ?? 0) <= 1) {
        _cart.remove(dish);
      } else {
        _cart[dish] = _cart[dish]! - 1;
      }
    });
    if (_cart.isEmpty) _slideController.reverse();
  }

  double get _totalPrice =>
      _cart.entries.fold(0, (sum, e) => sum + (e.key.price * e.value));

  int get _totalCount =>
      _cart.values.fold(0, (sum, qty) => sum + qty);

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
    // Cache refs before awaiting
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    await orderProvider.placeOrder(order);
    await tableProvider.updateStatus(widget.table.id, TableStatus.occupied);

    if (!mounted) return;
    nav.pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Đã gửi order vào bếp! 🍳'),
          ],
        ),
        backgroundColor: WaiterTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final inventory = Provider.of<InventoryProvider>(context).items;
    final dishes = menuProvider.allItems.where((d) => d.isAvailable).toList();

    // Auto animate summary bar
    if (_cart.isNotEmpty && _slideController.isDismissed) {
      _slideController.forward();
    } else if (_cart.isEmpty && _slideController.isCompleted) {
      _slideController.reverse();
    }

    return Scaffold(
      backgroundColor: WaiterTheme.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Dish list
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
            itemCount: dishes.length,
            itemBuilder: (ctx, i) {
              final dish = dishes[i];
              final qty = _cart[dish] ?? 0;
              final isOutOfStock = menuProvider.isOutOfStock(dish.id, inventory);
              return _DishCard(
                dish: dish,
                qty: qty,
                isOutOfStock: isOutOfStock,
                onAdd: () => _addToCart(dish),
                onRemove: () => _removeFromCart(dish),
              );
            },
          ),

          // Sliding summary bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildSummaryBar(),
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration:
            const BoxDecoration(gradient: WaiterTheme.appBarGradient),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.table.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const Text(
                        'Chọn món để gọi',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Cart count badge
                if (_totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          '$_totalCount món',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SUMMARY BAR ────────────────────────────────────────────────────────────
  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      decoration: BoxDecoration(
        gradient: WaiterTheme.summaryBarGradient,
        boxShadow: [
          BoxShadow(
            color: WaiterTheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${_fmtPrice(_totalPrice)}đ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _placeOrder,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded,
                        color: WaiterTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Gửi vào bếp',
                      style: TextStyle(
                        color: WaiterTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

// ── DISH CARD WIDGET ──────────────────────────────────────────────────────
class _DishCard extends StatelessWidget {
  final DishModel dish;
  final int qty;
  final bool isOutOfStock;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _DishCard({
    required this.dish,
    required this.qty,
    required this.isOutOfStock,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isOutOfStock ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: qty > 0
              ? Border.all(
                  color: WaiterTheme.primary.withValues(alpha: 0.4),
                  width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Dish image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: dish.imageUrl.isNotEmpty
                        ? Image.network(
                            dish.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  if (isOutOfStock)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'HẾT',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Name + price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dish.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                        ),
                        if (isOutOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HẾT MÓN',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dish.price.toInt()}đ',
                      style: const TextStyle(
                        color: WaiterTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Qty controls
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (qty > 0) ...[
                    _CounterBtn(
                      icon: Icons.do_not_disturb_on_rounded,
                      color: Colors.red.shade400,
                      onTap: onRemove,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Text(
                          '$qty',
                          key: ValueKey(qty),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: WaiterTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  _CounterBtn(
                    icon: Icons.add_circle_rounded,
                    color: isOutOfStock
                        ? Colors.grey
                        : WaiterTheme.primary,
                    onTap: isOutOfStock ? null : onAdd,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: WaiterTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.set_meal_rounded,
          color: WaiterTheme.primary, size: 28),
    );
  }
}

// ── COUNTER BTN ───────────────────────────────────────────────────────────
class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _CounterBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 30),
    );
  }
}
