# 🏮 Vị Lai Quán (未来馆) – Seed Data Guide

## 📋 Cấu trúc dữ liệu

| Collection | Số lượng | Mô tả |
|---|---|---|
| `categories` | 4 | appetizer, main, dessert, drink |
| `dishes` | 30 | 5 khai vị + 15 món chính + 5 tráng miệng + 5 uống |
| `tables` | 20 | Bàn 1–20, capacity 2–6 |
| `chatbot_data` | 8 | FAQ về nhà hàng |

---

## 🚀 Cách 1: Node.js Script (Khuyến nghị)

### Bước 1 – Cài đặt
```bash
cd scripts
npm install
```

### Bước 2 – Lấy Service Account Key
1. Vào [Firebase Console](https://console.firebase.google.com/project/quan-ly-nha-hang-20f37)
2. ⚙️ **Project Settings → Service Accounts**
3. Click **"Generate new private key"** → tải về `serviceAccountKey.json`
4. Đặt file vào thư mục `scripts/`

### Bước 3 – Chạy seed
```bash
npm run seed
# hoặc
node seed_firestore.js
```

### Output kỳ vọng
```
🏮 ====================================
   Vị Lai Quán (未来馆) – Seed Script
   Firebase: quan-ly-nha-hang-20f37
🏮 ====================================

📂 Seeding categories...
  ✓ Committed 4 docs to categories
✅ 4 categories seeded.

🍽️  Seeding dishes...
  ✓ Committed 30 docs to dishes
✅ 30 dishes seeded.

🪑 Seeding tables...
  ✓ Committed 20 docs to tables
✅ 20 tables seeded.

🤖 Seeding chatbot_data...
  ✓ Committed 8 docs to chatbot_data
✅ 8 FAQ entries seeded.

🎉 Seed hoàn tất! Database đã sẵn sàng sử dụng.
```

---

## 📱 Cách 2: Flutter In-App Button

Trong màn hình Admin Dashboard, nhấn nút **"Seed"** ở card màu xanh cuối trang.  
Hàm `InitDataService().seedAll()` sẽ tự chạy.

---

## 🖼️ Image URL Format (Supabase giả lập)

```
https://supabase.co/storage/v1/object/public/vilaiquan/dishes/dish_01.jpg
                                                                   ↑
                                                              dish_01 → dish_30
```

Khi deploy thực tế, thay `supabase.co` bằng URL project Supabase thật của bạn.

---

## ⚠️ Lưu ý

- Script dùng `merge: false` → **overwrite** dữ liệu cũ nếu chạy lại
- File `serviceAccountKey.json` đã được thêm vào `.gitignore` (secret!)
- Chỉ nên chạy seed **1 lần** khi khởi tạo database mới
