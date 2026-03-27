import 'package:cloud_firestore/cloud_firestore.dart';

/// Service khởi tạo dữ liệu mẫu cho Vị Lai Quán (未来馆)
/// Gồm: 4 categories, 30 dishes, 20 tables, 8 chatbot FAQ
class InitDataService {
  final _db = FirebaseFirestore.instance;

  // ── Supabase URL helper ───────────────────────────────────────────────────
  static String _supabaseUrl(String dishId) =>
      'https://supabase.co/storage/v1/object/public/vilaiquan/dishes/$dishId.jpg';

  // ── Entry point ───────────────────────────────────────────────────────────
  Future<void> seedAll() async {
    await seedCategories();
    await seedDishes();
    await seedTables();
    await seedChatbot();
  }

  // ── 1. seedCategories() ───────────────────────────────────────────────────
  Future<void> seedCategories() async {
    final categories = [
      {'id': 'appetizer', 'name': 'Khai vị'},
      {'id': 'main',      'name': 'Món chính'},
      {'id': 'dessert',   'name': 'Tráng miệng'},
      {'id': 'drink',     'name': 'Nước uống'},
    ];
    final batch = _db.batch();
    for (final c in categories) {
      batch.set(_db.collection('categories').doc(c['id']), c,
          SetOptions(merge: false));
    }
    await batch.commit();
  }

  // ── 2. seedDishes() ──────────────────────────────────────────────────────
  Future<void> seedDishes() async {
    final dishes = [
      // ── Khai vị (5) ──────────────────────────────────────────────────────
      _dish('dish_01', 'Gỏi cuốn',      30000, 'appetizer', isBest: true,
          desc: 'Gỏi cuốn tươi với tôm, thịt heo và rau sống'),
      _dish('dish_02', 'Chả giò',       40000, 'appetizer',
          desc: 'Chả giò nhân thịt heo và rau củ, chiên vàng giòn'),
      _dish('dish_03', 'Súp cua',       35000, 'appetizer',
          desc: 'Súp cua thịt nóng hổi, đậm đà hương vị biển'),
      _dish('dish_04', 'Salad trộn',    45000, 'appetizer',
          desc: 'Salad rau củ tươi trộn sốt mè rang thơm ngon'),
      _dish('dish_05', 'Bánh mì bơ tỏi', 25000, 'appetizer',
          desc: 'Bánh mì nướng bơ tỏi giòn thơm, ăn kèm khai vị'),

      // ── Món chính (15) ───────────────────────────────────────────────────
      _dish('dish_06', 'Cơm chiên hải sản', 70000, 'main',
          desc: 'Cơm chiên với tôm, mực, cua và rau củ tươi'),
      _dish('dish_07', 'Bò lúc lắc',   120000, 'main', isBest: true,
          desc: 'Thịt bò tươi xào lúc lắc tiêu xanh, ăn kèm cơm trắng'),
      _dish('dish_08', 'Gà nướng mật ong', 90000, 'main', isBest: true,
          desc: 'Gà ta nướng mật ong thảo mộc, da giòn vàng ươm'),
      _dish('dish_09', 'Lẩu thái',    150000, 'main', isBest: true,
          desc: 'Lẩu thái chua cay đặc trưng với hải sản tươi và nấm'),
      _dish('dish_10', 'Phở bò',       50000, 'main', isBest: true,
          desc: 'Phở bò Hà Nội truyền thống, nước dùng hầm 12 tiếng'),
      _dish('dish_11', 'Bún bò Huế',   55000, 'main',
          desc: 'Bún bò Huế chính thống, sả, ớt và giò heo'),
      _dish('dish_12', 'Cơm tấm sườn', 60000, 'main',
          desc: 'Cơm tấm Nam Bộ với sườn nướng, bì chả và trứng'),
      _dish('dish_13', 'Mì xào hải sản', 80000, 'main',
          desc: 'Mì xào với tôm, mực và rau củ đa dạng'),
      _dish('dish_14', 'Cá kho tộ',   100000, 'main',
          desc: 'Cá basa kho tộ đậm đà, ăn kèm cơm trắng nóng hổi'),
      _dish('dish_15', 'Thịt kho trứng', 75000, 'main',
          desc: 'Thịt ba chỉ kho trứng kiểu Nam Bộ, nước dừa béo ngậy'),
      _dish('dish_16', 'Bún chả',      60000, 'main',
          desc: 'Bún chả Hà Nội với chả nướng than hoa thơm lừng'),
      _dish('dish_17', 'Cơm gà xối mỡ', 65000, 'main',
          desc: 'Cơm gà xối mỡ giòn rụm, nước mắm chanh tỏi ớt'),
      _dish('dish_18', 'Pizza hải sản', 120000, 'main',
          desc: 'Pizza đế mỏng với tôm, mực và phô mai mozzarella'),
      _dish('dish_19', 'Spaghetti bò bằm', 90000, 'main',
          desc: 'Mì Ý sốt bolognese bò bằm đậm đà kiểu Ý'),
      _dish('dish_20', 'Hamburger bò', 80000, 'main',
          desc: 'Burger bò Mỹ với phô mai cheddar và rau tươi'),

      // ── Tráng miệng (5) ──────────────────────────────────────────────────
      _dish('dish_21', 'Bánh flan',    20000, 'dessert', isBest: true,
          desc: 'Bánh flan caramel mềm mịn, thơm ngậy hương vani'),
      _dish('dish_22', 'Kem vani',     25000, 'dessert',
          desc: 'Kem vani Ý béo ngậy, phục vụ trong ly waffle tươi'),
      _dish('dish_23', 'Chè đậu đỏ',  20000, 'dessert',
          desc: 'Chè đậu đỏ nước dừa thơm béo, ăn lạnh mát mẻ'),
      _dish('dish_24', 'Trái cây dĩa', 30000, 'dessert',
          desc: 'Đĩa trái cây tươi nhiều loại theo mùa'),
      _dish('dish_25', 'Bánh tiramisu', 40000, 'dessert',
          desc: 'Bánh tiramisu Ý với mascarpone và cà phê espresso'),

      // ── Đồ uống (5) ──────────────────────────────────────────────────────
      _dish('dish_26', 'Coca Cola',    15000, 'drink',
          desc: 'Coca Cola lon lạnh 330ml'),
      _dish('dish_27', 'Trà đào',      30000, 'drink', isBest: true,
          desc: 'Trà đào cam sả đá tươi mát, thơm dịu'),
      _dish('dish_28', 'Cà phê sữa',   25000, 'drink', isBest: true,
          desc: 'Cà phê phin truyền thống với sữa đặc, đá hoặc nóng'),
      _dish('dish_29', 'Nước cam',     35000, 'drink',
          desc: 'Nước ép cam tươi vắt nguyên chất, không đường'),
      _dish('dish_30', 'Sinh tố xoài', 40000, 'drink',
          desc: 'Sinh tố xoài cát Hòa Lộc đặc sánh với sữa tươi'),
    ];

    // Batch write (Firestore giới hạn 500 ops/batch)
    var batch = _db.batch();
    for (int i = 0; i < dishes.length; i++) {
      final d = dishes[i];
      batch.set(_db.collection('dishes').doc(d['id'] as String), d,
          SetOptions(merge: false));
    }
    await batch.commit();
  }

  // ── 3. seedTables() ──────────────────────────────────────────────────────
  Future<void> seedTables() async {
    // capacity phân bổ: 2,4,6 theo pattern
    const caps = [4, 2, 6, 4, 4, 2, 6, 4, 4, 2, 4, 6, 4, 2, 4, 6, 4, 4, 2, 4];
    final batch = _db.batch();
    for (int i = 1; i <= 20; i++) {
      final id = 'table_$i';
      batch.set(
        _db.collection('tables').doc(id),
        {
          'id':       id,
          'name':     'Bàn $i',
          'status':   'available',
          'capacity': caps[i - 1],
        },
        SetOptions(merge: false),
      );
    }
    await batch.commit();
  }

  // ── 4. seedChatbot() ─────────────────────────────────────────────────────
  Future<void> seedChatbot() async {
    final faqs = [
      {'id': 'faq_01', 'question': 'Tên quán là gì?',
       'answer': 'Chúng tôi là Vị Lai Quán (未来馆) – nhà hàng phong cách hiện đại, thành lập năm 2026.'},
      {'id': 'faq_02', 'question': 'Quán được thành lập năm nào?',
       'answer': 'Vị Lai Quán (未来馆) được thành lập vào năm 2026.'},
      {'id': 'faq_03', 'question': 'Món nào ngon nhất ở đây?',
       'answer': 'Khách hàng yêu thích nhất là Bò lúc lắc và Lẩu thái – hai món best-seller nổi tiếng của chúng tôi!'},
      {'id': 'faq_04', 'question': 'Quán có bao nhiêu món?',
       'answer': 'Thực đơn hiện tại có 30 món: 5 khai vị, 15 món chính, 5 tráng miệng và 5 đồ uống.'},
      {'id': 'faq_05', 'question': 'Giờ mở cửa là mấy giờ?',
       'answer': 'Vị Lai Quán mở cửa từ 8:00 sáng đến 22:00 tối hàng ngày, kể cả cuối tuần và ngày lễ.'},
      {'id': 'faq_06', 'question': 'Quán có bao nhiêu bàn?',
       'answer': 'Hiện tại quán có 20 bàn với sức chứa từ 2 đến 6 người mỗi bàn.'},
      {'id': 'faq_07', 'question': 'Có phục vụ giao hàng không?',
       'answer': 'Có! Chúng tôi hỗ trợ đặt món online với giao hàng tận nơi.'},
      {'id': 'faq_08', 'question': 'Có phù hợp cho gia đình không?',
       'answer': 'Hoàn toàn phù hợp! Vị Lai Quán có không gian ấm cúng, menu đa dạng cho mọi lứa tuổi.'},
    ];

    final batch = _db.batch();
    for (final f in faqs) {
      batch.set(_db.collection('chatbot_data').doc(f['id']), f,
          SetOptions(merge: false));
    }
    await batch.commit();
  }

  // ── Private helper ────────────────────────────────────────────────────────
  Map<String, dynamic> _dish(
    String id,
    String name,
    double price,
    String category, {
    String desc = '',
    bool isBest = false,
  }) =>
      {
        'id':          id,
        'name':        name,
        'price':       price,
        'category':    category,
        'description': desc,
        'image_url':   _supabaseUrl(id),
        'status':      'available',
        'isAvailable': true,
        'isBestSeller': isBest,
        'created_at':  FieldValue.serverTimestamp(),
      };
}
