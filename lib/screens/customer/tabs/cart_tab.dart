import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/dish_model.dart';

class CartTab extends StatelessWidget {
  final Function(int)? onSwitchTab;
  const CartTab({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cs = Theme.of(context).colorScheme;

    if (cart.items.isEmpty) {
      return _buildEmpty(cs, 'Giỏ hàng đang trống');
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: cart.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final dish = cart.items.keys.elementAt(index);
          final qty = cart.items[dish]!;
          return _CartItemTile(dish: dish, qty: qty, cart: cart);
        },
      ),
      bottomNavigationBar: _buildSummary(context, cart),
    );
  }

  Widget _buildEmpty(ColorScheme cs, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart) {
    final cs = Theme.of(context).colorScheme;
    final bool isDineIn = cart.tableId != null && cart.tableId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text('${_fmtPrice(cart.totalPrice)}đ', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (isDineIn) {
                  onSwitchTab?.call(1); // Chuyển sang tab Thực đơn (Menu)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xác nhận GPS và nhấn "Gửi đơn" tại Menu.')),
                  );
                } else {
                  onSwitchTab?.call(2); // Chuyển sang tab Đặt hàng Online (GPS)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng xác nhận địa chỉ giao hàng.')),
                  );
                }
              },
              child: Text(isDineIn ? 'Xác nhận đơn tại bàn' : 'Tiến hành đặt giao hàng'),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _CartItemTile extends StatelessWidget {
  final DishModel dish;
  final int qty;
  final CartProvider cart;

  const _CartItemTile({required this.dish, required this.qty, required this.cart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(dish.imageUrl, width: 85, height: 85, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: 85, height: 85, color: cs.surfaceContainerHighest)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_fmtPrice(dish.price)}đ', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _circleBtn(Icons.remove, () => cart.removeItem(dish)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  _circleBtn(Icons.add, () => cart.addItem(dish)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // Xoá tất cả món này
                      for(int i=0; i<qty; i++) cart.removeItem(dish);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
        child: Icon(icon, size: 16),
      ),
    );
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
