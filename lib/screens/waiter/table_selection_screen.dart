import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/table_provider.dart';
import '../../models/table_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../theme/role_themes.dart';
import 'ordering_screen.dart';
import '../active_table_dialog.dart';
import '../../utils/logout_helper.dart';
import '../profile/profile_screen.dart';

/// Màn hình chọn bàn cho waiter – Sky-Fresh (Electric Blue)
class TableSelectionScreen extends StatelessWidget {
  const TableSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tableProvider = Provider.of<TableProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: WaiterTheme.background,
      appBar: _buildAppBar(context, isAdmin),
      body: Column(
        children: [
          _buildLegendBar(),
          Expanded(
            child: RefreshIndicator(
              color: WaiterTheme.primary,
              displacement: 40,
              edgeOffset: 0,
              onRefresh: () async =>
                  await Future.delayed(const Duration(seconds: 1)),
              child: tableProvider.tables.isEmpty
                  ? _buildEmpty(context)
                  : _buildGrid(context, tableProvider, orderProvider),
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isAdmin) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(gradient: WaiterTheme.appBarGradient),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (isAdmin)
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
                if (isAdmin) const SizedBox(width: 12),
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chair_alt_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sơ đồ bàn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                const Spacer(),
                _appBarIconBtn(
                  Icons.sync_rounded,
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Đang cập nhật danh sách bàn...'),
                        ],
                      ),
                      backgroundColor: WaiterTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _appBarIconBtn(
                  Icons.account_circle_rounded,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(width: 6),
                _appBarIconBtn(
                  Icons.door_back_door_rounded,
                  () => LogoutHelper.showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBarIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── LEGEND BAR ─────────────────────────────────────────────────────────────
  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legend(const Color(0xFF00B894), 'Trống'),
          const SizedBox(width: 20),
          _legend(const Color(0xFFFF7675), 'Đang dùng'),
          const SizedBox(width: 20),
          _legend(const Color(0xFFFDAB00), 'Đặt trước'),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600)),
      ],
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: WaiterTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chair_alt_rounded,
                    size: 64, color: WaiterTheme.primary),
              ),
              const SizedBox(height: 20),
              const Text('Chưa có bàn nào',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xFF2D3436))),
              const SizedBox(height: 8),
              Text('Kéo xuống để làm mới',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ── TABLE GRID ─────────────────────────────────────────────────────────────
  Widget _buildGrid(BuildContext context, TableProvider tableProvider,
      OrderProvider orderProvider) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: tableProvider.tables.length,
      itemBuilder: (context, index) {
        final table = tableProvider.tables[index];
        final activeOrders = orderProvider.orders
            .where(
              (o) =>
                  o.tableId == table.id &&
                  o.status != OrderStatus.completed &&
                  o.status != OrderStatus.cancelled,
            )
            .toList();

        final isOccupied = table.status == TableStatus.occupied ||
            activeOrders.isNotEmpty;
        final isAvailable =
            !isOccupied && table.status == TableStatus.available;

        final effectiveStatus =
            isOccupied ? TableStatus.occupied : table.status;
        final statusColorStr = _statusStr(effectiveStatus);
        final statusColor = WaiterTheme.tableStatusColor(statusColorStr);
        final hasReadyItems = activeOrders.any((o) => o.status == OrderStatus.ready);

        return _TableCard(
          table: table,
          statusColor: statusColor,
          isAvailable: isAvailable,
          isOccupied: isOccupied,
          hasReadyItems: hasReadyItems,
          activeOrders: activeOrders,
          onTap: () {
            if (isAvailable) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderingScreen(table: table)),
              );
            } else if (isOccupied) {
              // Vẫn mở dialog kể cả khi activeOrders rỗng để nhân viên có thể "Dọn bàn" cưỡng bức
              showActiveTableDialog(context, table, activeOrders);
            }
          },
        );
      },
    );
  }

  String _statusStr(TableStatus status) {
    return switch (status) {
      TableStatus.available => 'available',
      TableStatus.occupied => 'occupied',
      TableStatus.reserved => 'reserved',
    };
  }
}

// ── TABLE CARD WIDGET ─────────────────────────────────────────────────────
class _TableCard extends StatefulWidget {
  final TableModel table;
  final Color statusColor;
  final bool isAvailable;
  final bool isOccupied;
  final bool hasReadyItems;
  final List<OrderModel> activeOrders;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.statusColor,
    required this.isAvailable,
    required this.isOccupied,
    required this.hasReadyItems,
    required this.activeOrders,
    required this.onTap,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.hasReadyItems) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TableCard old) {
    super.didUpdateWidget(old);
    if (widget.hasReadyItems && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.hasReadyItems && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: WaiterTheme.tableCardDecoration(
          statusColor: widget.statusColor,
          isSelected: false,
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Chair icon with colored background
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chair_alt_rounded,
                      color: widget.statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.table.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: widget.statusColor,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${widget.table.capacity} chỗ',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Ready badge (room service icon)
            if (widget.hasReadyItems)
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: 0.9 + _pulse.value * 0.15,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.room_service_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
