const admin = require('firebase-admin');

// Đọc file authentication
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// 1. MẢNG DỮ LIỆU CÔNG THỨC 30 MÓN (100 SUẤT) ĐÃ FIX MÃ DISH_01 ĐẾN DISH_30
const bulkData100Str = `
[
  {
    "dish_id": "dish_01",
    "dish_name": "Gỏi cuốn",
    "servings": 100,
    "ingredients": [
      { "name": "Bánh tráng", "unit": "g", "base_quantity": 10, "total_quantity": 1000 },
      { "name": "Tôm tươi", "unit": "g", "base_quantity": 30, "total_quantity": 3000 },
      { "name": "Thịt ba chỉ", "unit": "g", "base_quantity": 20, "total_quantity": 2000 },
      { "name": "Bún tươi", "unit": "g", "base_quantity": 20, "total_quantity": 2000 },
      { "name": "Rau sống", "unit": "g", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_02",
    "dish_name": "Chả giò",
    "servings": 100,
    "ingredients": [
      { "name": "Bánh tráng rế", "unit": "g", "base_quantity": 10, "total_quantity": 1000 },
      { "name": "Thịt heo xay", "unit": "g", "base_quantity": 40, "total_quantity": 4000 },
      { "name": "Nấm mèo", "unit": "g", "base_quantity": 5, "total_quantity": 500 },
      { "name": "Dầu ăn", "unit": "ml", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_03",
    "dish_name": "Súp cua",
    "servings": 100,
    "ingredients": [
      { "name": "Thịt cua", "unit": "g", "base_quantity": 30, "total_quantity": 3000 },
      { "name": "Bột năng", "unit": "g", "base_quantity": 15, "total_quantity": 1500 },
      { "name": "Trứng cút", "unit": "quả", "base_quantity": 2, "total_quantity": 200 },
      { "name": "Xương gà", "unit": "g", "base_quantity": 50, "total_quantity": 5000 }
    ]
  },
  {
    "dish_id": "dish_04",
    "dish_name": "Salad trộn",
    "servings": 100,
    "ingredients": [
      { "name": "Xà lách", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Cà chua", "unit": "g", "base_quantity": 30, "total_quantity": 3000 },
      { "name": "Sốt mè rang", "unit": "ml", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_05",
    "dish_name": "Bánh mì bơ tỏi",
    "servings": 100,
    "ingredients": [
      { "name": "Bánh mì", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Bơ lạt", "unit": "g", "base_quantity": 15, "total_quantity": 1500 },
      { "name": "Tỏi", "unit": "g", "base_quantity": 5, "total_quantity": 500 }
    ]
  },
  {
    "dish_id": "dish_06",
    "dish_name": "Bò lúc lắc",
    "servings": 100,
    "ingredients": [
      { "name": "Thịt bò", "unit": "g", "base_quantity": 150, "total_quantity": 15000 },
      { "name": "Hành tây", "unit": "g", "base_quantity": 20, "total_quantity": 2000 },
      { "name": "Ớt chuông", "unit": "g", "base_quantity": 20, "total_quantity": 2000 },
      { "name": "Khoai tây chiên", "unit": "g", "base_quantity": 50, "total_quantity": 5000 }
    ]
  },
  {
    "dish_id": "dish_07",
    "dish_name": "Cơm chiên hải sản",
    "servings": 100,
    "ingredients": [
      { "name": "Gạo trắng", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Tôm tươi", "unit": "g", "base_quantity": 30, "total_quantity": 3000 },
      { "name": "Mực ống", "unit": "g", "base_quantity": 30, "total_quantity": 3000 },
      { "name": "Trứng gà", "unit": "quả", "base_quantity": 1, "total_quantity": 100 }
    ]
  },
  {
    "dish_id": "dish_08",
    "dish_name": "Gà nướng mật ong",
    "servings": 100,
    "ingredients": [
      { "name": "Thịt gà", "unit": "g", "base_quantity": 250, "total_quantity": 25000 },
      { "name": "Mật ong", "unit": "ml", "base_quantity": 15, "total_quantity": 1500 }
    ]
  },
  {
    "dish_id": "dish_09",
    "dish_name": "Lẩu thái",
    "servings": 100,
    "ingredients": [
      { "name": "Tôm tươi", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Mực ống", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Nghêu", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Cốt lẩu thái", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Rau lẩu", "unit": "g", "base_quantity": 100, "total_quantity": 10000 }
    ]
  },
  {
    "dish_id": "dish_10",
    "dish_name": "Phở bò",
    "servings": 100,
    "ingredients": [
      { "name": "Bánh phở", "unit": "g", "base_quantity": 150, "total_quantity": 15000 },
      { "name": "Thịt bò", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Xương bò", "unit": "g", "base_quantity": 100, "total_quantity": 10000 }
    ]
  },
  {
    "dish_id": "dish_11",
    "dish_name": "Bún bò Huế",
    "servings": 100,
    "ingredients": [
      { "name": "Bún bò", "unit": "g", "base_quantity": 150, "total_quantity": 15000 },
      { "name": "Thịt bò", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Giò heo", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Chả cua", "unit": "g", "base_quantity": 30, "total_quantity": 3000 }
    ]
  },
  {
    "dish_id": "dish_12",
    "dish_name": "Cơm tấm sườn",
    "servings": 100,
    "ingredients": [
      { "name": "Gạo tấm", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Sườn heo", "unit": "g", "base_quantity": 150, "total_quantity": 15000 },
      { "name": "Bì heo", "unit": "g", "base_quantity": 20, "total_quantity": 2000 },
      { "name": "Trứng gà", "unit": "quả", "base_quantity": 1, "total_quantity": 100 }
    ]
  },
  {
    "dish_id": "dish_13",
    "dish_name": "Mì xào hải sản",
    "servings": 100,
    "ingredients": [
      { "name": "Mì tôm", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Tôm tươi", "unit": "g", "base_quantity": 40, "total_quantity": 4000 },
      { "name": "Mực ống", "unit": "g", "base_quantity": 40, "total_quantity": 4000 },
      { "name": "Rau súp lơ", "unit": "g", "base_quantity": 50, "total_quantity": 5000 }
    ]
  },
  {
    "dish_id": "dish_14",
    "dish_name": "Cá kho tộ",
    "servings": 100,
    "ingredients": [
      { "name": "Cá basa", "unit": "g", "base_quantity": 150, "total_quantity": 15000 },
      { "name": "Nước mắm", "unit": "ml", "base_quantity": 15, "total_quantity": 1500 },
      { "name": "Gạo trắng", "unit": "g", "base_quantity": 80, "total_quantity": 8000 }
    ]
  },
  {
    "dish_id": "dish_15",
    "dish_name": "Thịt kho trứng",
    "servings": 100,
    "ingredients": [
      { "name": "Thịt ba chỉ", "unit": "g", "base_quantity": 150, "total_quantity": 15000 },
      { "name": "Trứng vịt", "unit": "quả", "base_quantity": 1, "total_quantity": 100 },
      { "name": "Nước dừa tươi", "unit": "ml", "base_quantity": 100, "total_quantity": 10000 }
    ]
  },
  {
    "dish_id": "dish_16",
    "dish_name": "Bún chả",
    "servings": 100,
    "ingredients": [
      { "name": "Bún tươi", "unit": "g", "base_quantity": 150, "total_quantity": 15000 },
      { "name": "Thịt ba chỉ", "unit": "g", "base_quantity": 80, "total_quantity": 8000 },
      { "name": "Thịt nạc vai", "unit": "g", "base_quantity": 80, "total_quantity": 8000 },
      { "name": "Nước mắm", "unit": "ml", "base_quantity": 30, "total_quantity": 3000 }
    ]
  },
  {
    "dish_id": "dish_17",
    "dish_name": "Cơm gà xối mỡ",
    "servings": 100,
    "ingredients": [
      { "name": "Gạo trắng", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Thịt gà", "unit": "g", "base_quantity": 200, "total_quantity": 20000 },
      { "name": "Dầu ăn", "unit": "ml", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_18",
    "dish_name": "Pizza hải sản",
    "servings": 100,
    "ingredients": [
      { "name": "Đế pizza", "unit": "cái", "base_quantity": 1, "total_quantity": 100 },
      { "name": "Phô mai mozzarella", "unit": "g", "base_quantity": 80, "total_quantity": 8000 },
      { "name": "Tôm tươi", "unit": "g", "base_quantity": 30, "total_quantity": 3000 },
      { "name": "Mực ống", "unit": "g", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_19",
    "dish_name": "Spaghetti bò bằm",
    "servings": 100,
    "ingredients": [
      { "name": "Mì Ý", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Thịt bò xay", "unit": "g", "base_quantity": 80, "total_quantity": 8000 },
      { "name": "Sốt cà chua", "unit": "g", "base_quantity": 50, "total_quantity": 5000 }
    ]
  },
  {
    "dish_id": "dish_20",
    "dish_name": "Hamburger bò",
    "servings": 100,
    "ingredients": [
      { "name": "Vỏ burger", "unit": "cái", "base_quantity": 1, "total_quantity": 100 },
      { "name": "Thịt bò xay", "unit": "g", "base_quantity": 120, "total_quantity": 12000 },
      { "name": "Phô mai lát", "unit": "lát", "base_quantity": 1, "total_quantity": 100 },
      { "name": "Xà lách", "unit": "g", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_21",
    "dish_name": "Bánh flan",
    "servings": 100,
    "ingredients": [
      { "name": "Trứng gà", "unit": "quả", "base_quantity": 1, "total_quantity": 100 },
      { "name": "Sữa tươi", "unit": "ml", "base_quantity": 80, "total_quantity": 8000 },
      { "name": "Đường", "unit": "g", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_22",
    "dish_name": "Kem vani",
    "servings": 100,
    "ingredients": [
      { "name": "Kem vani", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Bánh ốc quế", "unit": "cái", "base_quantity": 1, "total_quantity": 100 }
    ]
  },
  {
    "dish_id": "dish_23",
    "dish_name": "Chè đậu đỏ",
    "servings": 100,
    "ingredients": [
      { "name": "Đậu đỏ", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Nước cốt dừa", "unit": "ml", "base_quantity": 30, "total_quantity": 3000 },
      { "name": "Đường", "unit": "g", "base_quantity": 20, "total_quantity": 2000 }
    ]
  },
  {
    "dish_id": "dish_24",
    "dish_name": "Trái cây dĩa",
    "servings": 100,
    "ingredients": [
      { "name": "Xoài chín", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Dưa hấu", "unit": "g", "base_quantity": 50, "total_quantity": 5000 },
      { "name": "Trái thơm", "unit": "g", "base_quantity": 50, "total_quantity": 5000 }
    ]
  },
  {
    "dish_id": "dish_25",
    "dish_name": "Bánh tiramisu",
    "servings": 100,
    "ingredients": [
      { "name": "Phô mai mascarpone", "unit": "g", "base_quantity": 40, "total_quantity": 4000 },
      { "name": "Cà phê espresso", "unit": "ml", "base_quantity": 10, "total_quantity": 1000 },
      { "name": "Bột cacao", "unit": "g", "base_quantity": 2, "total_quantity": 200 }
    ]
  },
  {
    "dish_id": "dish_26",
    "dish_name": "Coca Cola",
    "servings": 100,
    "ingredients": [
      { "name": "Coca Cola", "unit": "lon", "base_quantity": 1, "total_quantity": 100 }
    ]
  },
  {
    "dish_id": "dish_27",
    "dish_name": "Trà đào",
    "servings": 100,
    "ingredients": [
      { "name": "Trà đen", "unit": "g", "base_quantity": 5, "total_quantity": 500 },
      { "name": "Siro đào", "unit": "ml", "base_quantity": 20, "total_quantity": 2000 },
      { "name": "Đào ngâm", "unit": "g", "base_quantity": 30, "total_quantity": 3000 }
    ]
  },
  {
    "dish_id": "dish_28",
    "dish_name": "Cà phê sữa",
    "servings": 100,
    "ingredients": [
      { "name": "Cà phê bột", "unit": "g", "base_quantity": 15, "total_quantity": 1500 },
      { "name": "Sữa đặc", "unit": "ml", "base_quantity": 30, "total_quantity": 3000 }
    ]
  },
  {
    "dish_id": "dish_29",
    "dish_name": "Nước cam",
    "servings": 100,
    "ingredients": [
      { "name": "Cam tươi", "unit": "quả", "base_quantity": 2, "total_quantity": 200 },
      { "name": "Đường", "unit": "g", "base_quantity": 10, "total_quantity": 1000 }
    ]
  },
  {
    "dish_id": "dish_30",
    "dish_name": "Sinh tố xoài",
    "servings": 100,
    "ingredients": [
      { "name": "Xoài chín", "unit": "g", "base_quantity": 100, "total_quantity": 10000 },
      { "name": "Sữa đặc", "unit": "ml", "base_quantity": 20, "total_quantity": 2000 },
      { "name": "Sữa tươi", "unit": "ml", "base_quantity": 30, "total_quantity": 3000 }
    ]
  }
]
`;

// 2. MẢNG DỮ LIỆU TỒN KHO TỔNG HỢP CẦN CHO 30 MÓN x 100 SUẤT
const inventoryTotalStr = `
[
  { "ingredient": "Tôm tươi", "total_needed": 18000, "unit": "g" },
  { "ingredient": "Thịt bò", "total_needed": 30000, "unit": "g" },
  { "ingredient": "Thịt bò xay", "total_needed": 20000, "unit": "g" },
  { "ingredient": "Thịt ba chỉ", "total_needed": 25000, "unit": "g" },
  { "ingredient": "Thịt gà", "total_needed": 45000, "unit": "g" },
  { "ingredient": "Thịt nạc vai", "total_needed": 8000, "unit": "g" },
  { "ingredient": "Thịt heo xay", "total_needed": 4000, "unit": "g" },
  { "ingredient": "Gạo trắng", "total_needed": 28000, "unit": "g" },
  { "ingredient": "Gạo tấm", "total_needed": 10000, "unit": "g" },
  { "ingredient": "Sườn heo", "total_needed": 15000, "unit": "g" },
  { "ingredient": "Mực ống", "total_needed": 14000, "unit": "g" },
  { "ingredient": "Cá basa", "total_needed": 15000, "unit": "g" },
  { "ingredient": "Xương bò", "total_needed": 10000, "unit": "g" },
  { "ingredient": "Xương gà", "total_needed": 5000, "unit": "g" },
  { "ingredient": "Giò heo", "total_needed": 10000, "unit": "g" },
  { "ingredient": "Nghêu", "total_needed": 10000, "unit": "g" },
  { "ingredient": "Trứng gà", "total_needed": 300, "unit": "quả" },
  { "ingredient": "Trứng vịt", "total_needed": 100, "unit": "quả" },
  { "ingredient": "Trứng cút", "total_needed": 200, "unit": "quả" },
  { "ingredient": "Cam tươi", "total_needed": 200, "unit": "quả" },
  { "ingredient": "Xoài chín", "total_needed": 15000, "unit": "g" },
  { "ingredient": "Bún tươi", "total_needed": 17000, "unit": "g" },
  { "ingredient": "Bún bò", "total_needed": 15000, "unit": "g" },
  { "ingredient": "Bánh phở", "total_needed": 15000, "unit": "g" },
  { "ingredient": "Mì tôm", "total_needed": 10000, "unit": "g" },
  { "ingredient": "Mì Ý", "total_needed": 10000, "unit": "g" },
  { "ingredient": "Sữa tươi", "total_needed": 11000, "unit": "ml" },
  { "ingredient": "Dầu ăn", "total_needed": 4000, "unit": "ml" },
  { "ingredient": "Nước cốt dừa", "total_needed": 3000, "unit": "ml" },
  { "ingredient": "Nước dừa tươi", "total_needed": 10000, "unit": "ml" },
  { "ingredient": "Nước mắm", "total_needed": 4500, "unit": "ml" },
  { "ingredient": "Sốt mè rang", "total_needed": 2000, "unit": "ml" },
  { "ingredient": "Sữa đặc", "total_needed": 5000, "unit": "ml" },
  { "ingredient": "Mật ong", "total_needed": 1500, "unit": "ml" },
  { "ingredient": "Nhóm Chả (Chả cua, Bì heo)", "total_needed": 5000, "unit": "g" },
  { "ingredient": "Nhóm Bánh (Bánh mì, Đế pizza, Ốc quế, Bánh tráng)", "total_needed": 7200, "unit": "cái/g" },
  { "ingredient": "Nhóm Rau (Xà lách, Rau lẩu, Cà chua, Súp lơ)", "total_needed": 25000, "unit": "g" },
  { "ingredient": "Cốt gia vị (Lẩu, Cacao, Cafe, Ớt chuông, Hành tây, Tỏi...)", "total_needed": 20000, "unit": "g" },
  { "ingredient": "Coca Cola", "total_needed": 100, "unit": "lon" }
]
`;

async function uploadBulkData() {
  const bulkData100 = JSON.parse(bulkData100Str);
  const inventoryTotal = JSON.parse(inventoryTotalStr);

  const batch1 = db.batch();
  console.log(">> Uploading bulk_ingredients_100...");
  bulkData100.forEach((dish) => {
    const docRef = db.collection('bulk_ingredients_100').doc(dish.dish_id);
    batch1.set(docRef, dish, { merge: true });
  });
  await batch1.commit();
  console.log("✅ Xong Bulk Data (30 Món)!");

  const batch2 = db.batch();
  console.log(">> Uploading inventory tổng...");
  inventoryTotal.forEach((item, index) => {
    // Đánh số id tự động từ inv_bulk_001
    const docId = `inv_bulk_${(index + 1).toString().padStart(3, '0')}`;
    const docRef = db.collection('inventory').doc(docId);
    
    // Đổi ra kg/lít nếu lớn hơn 1000g
    let qty = item.total_needed;
    let unitStr = item.unit;
    if (qty >= 1000 && (unitStr === 'g' || unitStr === 'ml')) {
      qty = qty / 1000;
      unitStr = unitStr === 'g' ? 'kg' : 'lít';
    }

    batch2.set(docRef, {
      id: docId,
      name: item.ingredient,
      quantity: qty,
      maxQuantity: qty,
      unit: unitStr,
    }, { merge: true });
  });
  
  await batch2.commit();
  console.log("✅ Xong Inventory Cập Nhật Đầy Đủ!");
}

uploadBulkData().catch(console.error);
