import '../models/table_model.dart';
import '../models/category_model.dart';
import '../models/dish_model.dart';
import 'database_service.dart';

/// Khởi tạo dữ liệu mẫu vào Firestore cho project quan-ly-nha-hang-20f37
class InitDataService {
  final _db = DatabaseService();

  /// Seed 4 categories
  Future<void> seedCategories() async {
    for (final cat in CategoryModel.defaults) {
      await _db.saveCategory(cat);
    }
  }

  /// Seed 20 bàn (Bàn 1 → Bàn 20, capacity ngẫu nhiên 2-6)
  Future<void> seedTables() async {
    final capacities = [2, 2, 4, 4, 4, 4, 6, 6, 4, 4, 2, 4, 6, 4, 4, 2, 6, 4, 4, 4];
    for (int i = 1; i <= 20; i++) {
      await _db.saveTable(TableModel(
        id: 'table_$i',
        name: 'Bàn $i',
        capacity: capacities[i - 1],
      ));
    }
  }

  /// Seed 30 món ăn: 5 khai vị + 15 món chính + 5 tráng miệng + 5 đồ uống
  Future<void> seedDishes() async {
    final dishes = _buildDishes();
    for (final dish in dishes) {
      await _db.saveDish(dish);
    }
  }

  /// Seed toàn bộ dữ liệu (categories + tables + dishes)
  Future<void> seedAll() async {
    await seedCategories();
    await seedTables();
    await seedDishes();
  }

  List<DishModel> _buildDishes() {
    final now = DateTime.now();
    int idx = 0;

    DishModel make({
      required String name,
      required String desc,
      required double price,
      required String cat,
      bool best = false,
    }) {
      idx++;
      return DishModel(
        id: 'dish_${idx.toString().padLeft(2, '0')}',
        name: name,
        description: desc,
        price: price,
        imageUrl: '',
        category: cat,
        isBestSeller: best,
        createdAt: now.subtract(Duration(days: idx)),
      );
    }

    return [
      // ── Khai vị (5 món) ─────────────────────────────
      make(name: 'Gỏi cuốn tôm thịt', desc: 'Gỏi cuốn tươi với tôm, thịt heo và rau sống', price: 65000, cat: 'appetizer', best: true),
      make(name: 'Chả giò chiên giòn', desc: 'Chả giò nhân thịt heo và rau củ, chiên vàng giòn', price: 70000, cat: 'appetizer'),
      make(name: 'Súp cua cà chua', desc: 'Súp nóng với cua thịt và cà chua tươi', price: 55000, cat: 'appetizer'),
      make(name: 'Salad trộn Thái', desc: 'Salad rau củ phong cách Thái, chua ngọt cay', price: 60000, cat: 'appetizer'),
      make(name: 'Đậu phụ sốt tỏi', desc: 'Đậu phụ non chiên vàng, sốt tỏi phi thơm', price: 45000, cat: 'appetizer'),

      // ── Món chính (15 món) ───────────────────────────
      make(name: 'Bò lúc lắc', desc: 'Thịt bò tươi xào lúc lắc với tiêu xanh, phục vụ kèm cơm', price: 185000, cat: 'main', best: true),
      make(name: 'Cơm gà Hải Nam', desc: 'Cơm gà kiểu Singapore, nước chấm gừng đặc biệt', price: 120000, cat: 'main', best: true),
      make(name: 'Cá hồi áp chảo', desc: 'Phi lê cá hồi Na Uy áp chảo bơ, kèm salad', price: 220000, cat: 'main'),
      make(name: 'Tôm rang muối', desc: 'Tôm sú tươi rang muối ớt lá chanh', price: 175000, cat: 'main'),
      make(name: 'Thịt heo kho tàu', desc: 'Thịt ba chỉ kho trứng kiểu Nam Bộ', price: 95000, cat: 'main'),
      make(name: 'Gà nướng mật ong', desc: 'Gà ta nướng mật ong, da giòn, thơm thảo mộc', price: 160000, cat: 'main', best: true),
      make(name: 'Mực xào chua ngọt', desc: 'Mực tươi xào sốt chua ngọt, ớt chuông', price: 145000, cat: 'main'),
      make(name: 'Lẩu hải sản', desc: 'Lẩu hải sản đa dạng tôm, mực, nghêu, nấm', price: 350000, cat: 'main'),
      make(name: 'Sườn nướng BBQ', desc: 'Sườn heo non nướng sốt BBQ kiểu Mỹ', price: 195000, cat: 'main'),
      make(name: 'Bún bò Huế', desc: 'Bún bò Huế chính thống, sả, ớt, giò heo', price: 85000, cat: 'main'),
      make(name: 'Phở bò tái nạm', desc: 'Phở bò Hà Nội với thịt tái và nạm', price: 80000, cat: 'main', best: true),
      make(name: 'Cơm chiên dương châu', desc: 'Cơm chiên kiểu Trung Hoa với trứng và rau củ', price: 75000, cat: 'main'),
      make(name: 'Vịt quay Bắc Kinh', desc: 'Vịt quay da giòn phục vụ kèm bánh mì nhỏ', price: 280000, cat: 'main'),
      make(name: 'Đùi gà nướng thảo mộc', desc: 'Đùi gà nướng với hương thảo, tỏi và bơ', price: 130000, cat: 'main'),
      make(name: 'Rau muống xào tỏi', desc: 'Rau muống non xào tỏi phi thơm', price: 45000, cat: 'main'),

      // ── Tráng miệng (5 món) ──────────────────────────
      make(name: 'Chè ba màu', desc: 'Chè đậu ba màu thạch trân châu, đá bào', price: 40000, cat: 'dessert', best: true),
      make(name: 'Bánh flan caramel', desc: 'Bánh flan mềm mịn với caramel vàng', price: 35000, cat: 'dessert'),
      make(name: 'Kem dừa Thái', desc: 'Kem dừa béo ngậy trong vỏ dừa tươi', price: 55000, cat: 'dessert'),
      make(name: 'Chè đậu xanh nước dừa', desc: 'Chè đậu xanh nước cốt dừa thơm béo', price: 35000, cat: 'dessert'),
      make(name: 'Trái cây tươi thập cẩm', desc: 'Đĩa trái cây nhiều loại theo mùa', price: 65000, cat: 'dessert'),

      // ── Đồ uống (5 món) ──────────────────────────────
      make(name: 'Nước ép cam tươi', desc: 'Cam vắt tươi nguyên chất, không đường', price: 40000, cat: 'drink', best: true),
      make(name: 'Cà phê sữa đá', desc: 'Cà phê phin truyền thống với sữa đặc', price: 35000, cat: 'drink'),
      make(name: 'Trà đào cam sả', desc: 'Trà đào kết hợp cam và sả tươi', price: 45000, cat: 'drink'),
      make(name: 'Sinh tố bơ', desc: 'Sinh tố bơ đặc sánh với sữa tươi', price: 50000, cat: 'drink'),
      make(name: 'Nước khoáng Lavie', desc: 'Nước khoáng Lavie 500ml', price: 15000, cat: 'drink'),
    ];
  }
}
