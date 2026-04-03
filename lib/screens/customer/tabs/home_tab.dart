import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../models/dish_model.dart';
import '../../../models/category_model.dart';
import '../../../theme/role_themes.dart';
import '../customer_chatbot_screen.dart';

// ─── Data model cho banner ────────────────────────────────────────────────────
class _BannerData {
  final List<Color> gradient;
  final String imageUrl;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;

  const _BannerData({
    required this.gradient,
    required this.imageUrl,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
  });
}

const _kBanners = [
  _BannerData(
    gradient: [Color(0xFFFF6B35), Color(0xFFFF9A3D)],
    imageUrl:
        'https://res.cloudinary.com/dojcgjli4/image/upload/v1775230230/banner1_hv0yhw.jpg',
    badge: 'ƯU ĐÃI HÔM NAY',
    badgeColor: Color(0xFFFF6B35),
    title: 'Đại Tiệc Lẩu Vị Lai',
    subtitle: 'Giảm ngay 20% cho nhóm từ 4 người',
  ),
  _BannerData(
    gradient: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
    imageUrl:
        'https://res.cloudinary.com/dojcgjli4/image/upload/v1775230230/banner2_krj93i.jpg',
    badge: 'COMBO ĐẶC BIỆT',
    badgeColor: Color(0xFF6C63FF),
    title: 'Set Cơm Phần Thượng Hạng',
    subtitle: 'Trọn bộ cơm + canh + món phụ 79.000đ',
  ),
  _BannerData(
    gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
    imageUrl:
        'https://res.cloudinary.com/dojcgjli4/image/upload/v1775230230/banner3_yenmnn.jpg',
    badge: 'MỚI – THỨC UỐNG',
    badgeColor: Color(0xFF11998E),
    title: 'Trà Sữa Thêm Topping',
    subtitle: 'Miễn phí 1 topping khi order qua app',
  ),
];

// ─── Widget Banner tự cuộn ────────────────────────────────────────────────────
class _PromoBannerSlider extends StatefulWidget {
  const _PromoBannerSlider();

  @override
  State<_PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<_PromoBannerSlider> {
  final PageController _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _kBanners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Slides ──
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: _kBanners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _BannerSlide(data: _kBanners[i]),
          ),
        ),

        const SizedBox(height: 12),

        // ── Scroll-dot indicator ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_kBanners.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: active
                    ? LinearGradient(colors: _kBanners[i].gradient)
                    : null,
                color: active ? null : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Một slide banner ────────────────────────────────────────────────────────
class _BannerSlide extends StatelessWidget {
  final _BannerData data;
  const _BannerSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Full width, padding nhỏ 2 bên để thấy giới hạn card
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: data.gradient.first.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh nền
          Image.network(
            data.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Gradient overlay phía dưới
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  data.gradient.first.withValues(alpha: 0.85),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),

          // Nội dung
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    data.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tiêu đề
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                          blurRadius: 6,
                          color: Colors.black38,
                          offset: Offset(0, 2))
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Mô tả
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black26)
                    ],
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

// ─── HomeTab chính ────────────────────────────────────────────────────────────
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final bestSellers = menuProvider.allItems
        .where((d) => menuProvider.isTopSelling(d.id))
        .take(6)
        .toList();

    return RefreshIndicator(
      color: CustomerTheme.primary,
      displacement: 40,
      edgeOffset: 20,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── 3 Banner quảng cáo full width + scroll-dot ──
            const _PromoBannerSlider(),

            const SizedBox(height: 28),

            _buildSectionHeader(context, 'Danh mục', null),
            const SizedBox(height: 12),
            _buildCategories(context, menuProvider),

            const SizedBox(height: 28),
            _buildAssistantCard(context),
            const SizedBox(height: 28),

            _buildSectionHeader(context, 'Món chạy nhất 🔥', null),
            const SizedBox(height: 16),
            _buildBestSellers(context, bestSellers),

            const SizedBox(height: 28),
            _buildLoyaltyCard(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── SECTION HEADER ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: CustomerTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: CustomerTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: const Text('Xem tất cả',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ── CATEGORIES ──────────────────────────────────────────────────────────────
  Widget _buildCategories(BuildContext context, MenuProvider provider) {
    final cats = CategoryModel.defaults;
    final List<Color> catColors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF6C5CE7),
      const Color(0xFF00B894),
      const Color(0xFFFDAB00),
      const Color(0xFF0984E3),
      const Color(0xFFE17055),
      const Color(0xFF00CEC9),
      const Color(0xFFAA00FF),
    ];

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final cat = cats[index];
          final color = catColors[index % catColors.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {},
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: color.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        cat.name
                            .substring(0, math.min(2, cat.name.length))
                            .toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF636E72),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── ASSISTANT CARD ──────────────────────────────────────────────────────────
  Widget _buildAssistantCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerChatbotScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trợ lý Vị Lai AI',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Gợi ý thực đơn & tư vấn món ngay lập tức',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── BEST SELLERS ─────────────────────────────────────────────────────────────
  Widget _buildBestSellers(BuildContext context, List<DishModel> dishes) {
    if (dishes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Text(
            'Chưa có dữ liệu món bán chạy',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dishes.length,
        itemBuilder: (context, index) {
          final dish = dishes[index];
          return Container(
            width: 155,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      Image.network(
                        dish.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: CustomerTheme.primary.withValues(alpha: 0.1),
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: CustomerTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded,
                                  color: Colors.white, size: 10),
                              SizedBox(width: 2),
                              Text('HOT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dish.price.round()}đ',
                        style: const TextStyle(
                          color: CustomerTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── LOYALTY CARD ─────────────────────────────────────────────────────────────
  Widget _buildLoyaltyCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CustomerTheme.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thành viên V-VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tích điểm nhận ưu đãi 5–10% mỗi hoá đơn',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
