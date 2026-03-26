import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/table_model.dart';
import '../models/food_item.dart';
import '../models/order_model.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';

class OrderingScreen extends StatefulWidget {
  final TableModel table;
  const OrderingScreen({super.key, required this.table});

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final Map<FoodItem, int> _cart = {};

  void _addToCart(FoodItem item) {
    setState(() {
      _cart[item] = (_cart[item] ?? 0) + 1;
    });
  }

  double get _totalPrice {
    return _cart.entries.fold(0, (sum, entry) => sum + (entry.key.price * entry.value));
  }

  void _placeOrder() async {
    if (_cart.isEmpty) return;

    final List<OrderItem> items = _cart.entries.map((e) => OrderItem(
      foodItem: e.key,
      quantity: e.value,
    )).toList();

    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: widget.table.number,
      items: items,
      totalPrice: _totalPrice,
      status: OrderStatus.pending,
      type: OrderType.dineIn,
      createdAt: DateTime.now(),
    );

    await Provider.of<OrderProvider>(context, listen: false).placeOrder(order);
    Navigator.pop(context); // Go back to table selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order sent to kitchen')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Table ${widget.table.number} Order')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: menuProvider.items.length,
              itemBuilder: (context, index) {
                final item = menuProvider.items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.price}đ'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: () => _addToCart(item),
                  ),
                );
              },
            ),
          ),
          if (_cart.isNotEmpty) 
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text('Total: ${_totalPrice.toStringAsFixed(0)}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Send to Kitchen'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
